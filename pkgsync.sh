#!/bin/bash

set -e

[[ -e "$HOME"/.dotfiles/.pkgsynclist/config ]] && . "$HOME"/.dotfiles/.pkgsynclist/config

EXCLUSION_LIST="${EXCLUSION_LIST:-/etc/pkgsync/pkg_exclude.list}"
BLACKLIST_LIST="${BLACKLIST_LIST:-/etc/pkgsync/pkg_blacklist.list}" 
REMOVE_LIST="${REMOVE_LIST:-/etc/pkgsync/pkg_remove.list}"
INSTALL_LIST="${INSTALL_LIST:-/etc/pkgsync/pkg_install.list}"
PRESTART_SCRIPT="${PRESTART_SCRIPT:-/etc/pkgsync/pkg_prestart.sh}"
FINISH_SCRIPT="${FINISH_SCRIPT:-/etc/pkgsync/pkg_finish.sh}"
TMP_DIR="${TMP_DIR:-/tmp}"

# Запуск prestart скрипта, если он существует
[[ -x "$PRESTART_SCRIPT" ]] && "$PRESTART_SCRIPT"

# Извлчение названий пакетов из списков, сортировка с удалением дубликатов и запись во временный файл. Данных файлов может и не быть или они могут быть пустыми, скрипт продолжится в любом случае
grep -v '^#' "$EXCLUSION_LIST" 2>/dev/null | sort -u > "$TMP_DIR/pkg_exclude.list"   || true
grep -v '^#' "$BLACKLIST_LIST" 2>/dev/null | sort -u > "$TMP_DIR/pkg_blacklist.list" || true
grep -v '^#' "$REMOVE_LIST"    2>/dev/null | sort -u > "$TMP_DIR/pkg_remove.list"    || true
grep -v '^#' "$INSTALL_LIST"   2>/dev/null | sort -u > "$TMP_DIR/pkg_install.list"   || true

# Основная часть скрипта
pacman -Qqe | sort | comm -23 - "$TMP_DIR/pkg_exclude.list" > "$TMP_DIR/mypkgs_with_exclusions.txt"

comm -23 "$TMP_DIR/mypkgs_with_exclusions.txt" "$TMP_DIR/pkg_remove.list" > "$TMP_DIR/mypkgs_with_exclusions_without_remove.txt"

comm -12 "$TMP_DIR/mypkgs_with_exclusions.txt" "$TMP_DIR/pkg_remove.list" | comm -23 - "$TMP_DIR/pkg_blacklist.list" > "$TMP_DIR/pkg_toremove.list"

sort -u "$TMP_DIR/mypkgs_with_exclusions_without_remove.txt" "$TMP_DIR/pkg_install.list" | comm -23 - "$TMP_DIR/pkg_remove.list" > "$TMP_DIR/pkg_installed.list"

comm -13 "$TMP_DIR/mypkgs_with_exclusions_without_remove.txt" "$TMP_DIR/pkg_installed.list" | comm -23 - "$TMP_DIR/pkg_blacklist.list" > "$TMP_DIR/pkg_toinstall.list"

comm -23 "$TMP_DIR/pkg_installed.list" "$TMP_DIR/pkg_install.list" | comm -23 - "$TMP_DIR/pkg_blacklist.list" > "$TMP_DIR/pkg_ourinstall.list"

## Установка новых пакетов
if [[ -s "$TMP_DIR/pkg_toinstall.list" ]]
then
    yn=l
    while [[ ! "$yn" =~ ^[YyNnAaQqBb]$ ]]
    do
        read -p "Install new packages? (yes/no/list/abort/blacklist)..." -n 1 yn
        echo
        [[ "$yn" =~ ^[Ll]$ ]] && cat "$TMP_DIR/pkg_toinstall.list"
    done
    [[ "$yn" =~ ^[Yy]$ ]] && yay -S --needed --confirm - < "$TMP_DIR/pkg_toinstall.list"
    [[ "$yn" =~ ^[Bb]$ ]] && cat "$TMP_DIR/pkg_toinstall.list" >> "$BLACKLIST_LIST"
    [[ "$yn" =~ ^[AaQq]$ ]] && exit 1
fi

## Удаление пакетов
if [[ -s "$TMP_DIR/pkg_toremove.list" ]]
then
    yn=l
    while [[ ! "$yn" =~ ^[YyNnAaQqBb]$ ]]
    do
        read -p "Remove packages? (yes/no/list/abort/blacklist)..." -n 1 yn
        echo
        [[ "$yn" =~ ^[Ll]$ ]] && cat "$TMP_DIR/pkg_toremove.list"
    done
    [[ "$yn" =~ ^[Yy]$ ]] && yay -R --confirm - < "$TMP_DIR/pkg_toremove.list"
    [[ "$yn" =~ ^[Bb]$ ]] && cat "$TMP_DIR/pkg_toremove.list" >> "$BLACKLIST_LIST"
    [[ "$yn" =~ ^[AaQq]$ ]] && exit 1
fi

## Добавление новых пакетов в общий лист INSTALL, если таковые имеются
if [[ -s "$TMP_DIR/pkg_ourinstall.list" ]]
then
    yn=l
    while [[ ! "$yn" =~ ^[YyNnAaQqEe]$ ]]
    do
        read -p "Append packages unique to this computer to install list and run finish script? (yes/no/list/abort/exclude)..." -n 1 yn
        echo
        [[ "$yn" =~ ^[Ll]$ ]] && cat "$TMP_DIR/pkg_ourinstall.list"
    done

    if [[ "$yn" =~ ^[Yy]$ ]]; then
        cat "$TMP_DIR/pkg_ourinstall.list" | gum filter --no-limit >> "$INSTALL_LIST"
        comm -23 <(sort "$TMP_DIR/pkg_ourinstall.list") <(sort "$INSTALL_LIST") >> "$EXCLUSION_LIST"
    fi

    if [[ "$yn" =~ ^[Ee]$ ]]; then
        cat "$TMP_DIR/pkg_ourinstall.list" | gum filter --no-limit >> "$EXCLUSION_LIST"
        comm -23 <(sort -u "$TMP_DIR/pkg_ourinstall.list") <(sort -u "$EXCLUSION_LIST") >> "$INSTALL_LIST"
    fi

    [[ "$yn" =~ ^[AaQq]$ ]] && exit 1
fi

## Очистка файла pkg_remove.txt
if [[ -s "$HOME/.dotfiles/.pkgsynclist/pkg_remove.list" ]]
then
    yn=l
    while [[ ! "$yn" =~ ^[YyNnAaQqEe]$ ]]
    do
        read -p "Clear pkg_remove.list? (yes/no/list/abort/exclude)..." -n 1 yn
        echo
        [[ "$yn" =~ ^[Ll]$ ]] && cat "$HOME/.dotfiles/.pkgsynclist/pkg_remove.list"
    done
    [[ "$yn" =~ ^[Yy]$ ]] && truncate -s 0 "$HOME/.dotfiles/.pkgsynclist/pkg_remove.list"
    [[ "$yn" =~ ^[Ee]$ ]] && cat "$HOME/.dotfiles/.pkgsynclist/pkg_remove.list" >> "$EXCLUSION_LIST"
    [[ "$yn" =~ ^[AaQq]$ ]] && exit 1

    ## Запуск finish скрипта, если он существует
    [[ -x "$FINISH_SCRIPT" ]] && "$FINISH_SCRIPT"
fi

## Удаление временных файлов
rm -f "$TMP_DIR/pkg_exclude.list" "$TMP_DIR/pkg_blacklist.list" "$TMP_DIR/pkg_remove.list" "$TMP_DIR/mypkgs_with_exclusions.txt" "$TMP_DIR/mypkgs_with_exclusions_without_remove.txt" "$TMP_DIR/pkg_toremove.list" "$TMP_DIR/pkg_installed.list" "$TMP_DIR/pkg_toinstall.list" "$TMP_DIR/pkg_ourinstall.list"
