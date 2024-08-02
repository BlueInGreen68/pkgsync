Форк [pkgsync](https://github.com/moparisthebest/pkgsync). Описание работы скрипта в данном `README.md` является субъективным и не относится к оригинальному проекту. 

# pkgsync

Простой скрипт для синхронизации установленных пакетов между машинами на базе Arch Linux.

# Настройка

## Конфигурационный файл

Конфигурационный файл, по задумке, содержит только пути до основных файлов в виде bash-переменных `EXCLUSION_LIST=/путь/до/EXLUSION_LIST`, основные переменные это:

- [`EXCLUSION_LIST`](#exclusion-list);
- [`BLACKLIST_LIST`](#black-list); 
- [`REMOVE_LIST`](#remove-list); 
- [`INSTALL_LIST`](#install-list); 
- [`PRESTART_SCRIPT`](#prestart-list);
- [`FINISH_SCRIPT`](#finish-list);
- [`TMP_DIR`](#tmp-dir).

В целом, даже если конфигурационного файла и не будет существовать, все переменные путей до основных файлов в скрипте `pkgsync` будут установлены по умолчанию:

```bash
EXCLUSION_LIST="${EXCLUSION_LIST:-/etc/pkgsync/pkg_exclude.list}"
BLACKLIST_LIST="${BLACKLIST_LIST:-/etc/pkgsync/pkg_blacklist.list}"
REMOVE_LIST="${REMOVE_LIST:-/etc/pkgsync/pkg_remove.list}"
INSTALL_LIST="${INSTALL_LIST:-/etc/pkgsync/pkg_install.list}"
PRESTART_SCRIPT="${PRESTART_SCRIPT:-/etc/pkgsync/pkg_prestart.sh}"
FINISH_SCRIPT="${FINISH_SCRIPT:-/etc/pkgsync/pkg_finish.sh}"
TMP_DIR="${TMP_DIR:-/tmp}"
```

По умолчанию конфигурационный файл должен находиться в `/etc/default/pkgsync`, но путь можно поменять путём изменения 5 строчки кода файла `pkgsync`:

```bash
#!/bin/bash

set -e

[[ -e /ваш/путь/до_конфигурационного_файла ]] && . /ваш/путь/до_конфигурационного_файла
```

[Пример](https://github.com/BlueInGreen68/pkgsync/blob/master/config/pkgsync) оригинального конфигурационного файла.

> Все списки содержащие пакеты могут иметь комментарии начинающиеся с `#`, а также могут быть не сортированы

## EXCLUSION LIST

Данный файл содержит список пакетов **текущей системы**, которые нужно исключить из общего списка [INSTALL](#install-list).

Например:
```bash
# /etc/pkgsync/pkg_exclude.list

## Данные пакеты нужны только текущей машине, например пакеты ниже, в большинстве случаев, нужны на ноутбуках, а на стационарном компьютере нет 
blueman
bluez
bluez-utils
```
Данный список будет на **разных машинах** соответственно разным, учитывайте это.

## BLACKLIST LIST

Данный файл содержит список пакетов, которые **нельзя** ни удалять ни устанавливать на текущей системе, именно этим он отличается от списка [EXCLUDE](#exclude-list).

Это означает, что даже если, например, пакет `neovim` будет находиться в списке на установку или удаление, он по итогу не установится или не удалится (если будет находиться на текущей системе).

## REMOVE LIST

Данный файл содержит список пакетов, которые будут удалены из текущей системы. Данный список должен обновляться постоянно из сессии к сессии, он не должен хранить **постоянный** список пакетов на удаление, как например [INSTALL](#install-list), а также он не должен иметь с ним совпадений, потому что в таком случае пакет не установится и не удалится (для подобного поведения существует [BLACKLIST](#blacklist-list)).

## INSTALL LIST

Данный файл содержит общий список пакетов, которые должны быть установлены **на всех машинах**. Список должен постоянно обновляться из сессии к сессии, список можно расширить через `pkgsync`, но не сократить, а также Вы должны позаботиться о синхронизации этого списка между всеми Вашими машинами.

## PRESTART SCRIPT

Ваш cкрипт, который запускается **перед** обновлением, удалением пакетов. Скрипт должен быть исполняемым `chmod +x prestart.sh` и выполнятся без ошибок. 

## FINISH SCRIPT

Ваш скрипт, который запускается **после** обновления, удаления пакетов. Скрипт должен быть исполняемым `chmod +x finish.sh` и выполнятся без ошибок.

## TMP DIR

Переменная, которая содержит путь до директории временных файлов скрипта `pkgsync`, временные файлы после выполнения скрипта удаляются.
# Как работает 

Ключевой момент работы скрипта основан на команде `comm`. Поочерёдно сравниваются разные списки с наименованием пакетов и от их вывода будет зависить итоговый результат. [Подробнее](https://linux-faq.ru/page/komanda-comm) о аргументах команды `comm` использованных в скрипте `pkgsync`. ## Алгоритм работы Пройдёмся по основым 6 командам, где происходит всё.

## Получение списка пакетов текущей системы без пакетов из списка exclude
```bash
pacman -Qq | sort | comm -23 - "$TMP_DIR/pkg_exclude.list" > "$TMP_DIR/mypkgs_with_exclusions.txt"
```

На выходе получаем `mypkgs_with_exclusions.txt`.

Используется далее для:
- [получение списка пакетов без пакетов на удаление](#получение-списка-пакетов-текущей-системы-без-пакетов-из-списка-exclude-и-remove);
- [получение списка пакетов на удаление](#получение-списка-пакетов-текущей-системы-на-удаление);

## Получение списка пакетов текущей системы без пакетов из списка exclude и remove
```bash
comm -23 "$TMP_DIR/mypkgs_with_exclusions.txt" "$TMP_DIR/pkg_remove.list" > "$TMP_DIR/mypkgs_with_exclusions_without_remove.txt"
```

На выходе получаем `mypkgs_with_exlusions_without_remove.txt`.

Используется далее для:
- [получение списка пакетов установленных на текущей системе](#получение-списка-пакетов-установленных-на-текущей-системе);
- [получение списка пакетов, которые будут установлены на текущей системе](#получение-списка-пакетов-которые-будут-установлены-на-текущей-системе);

## Получение списка пакетов текущей системы на удаление
```bash
comm -12 "$TMP_DIR/mypkgs_with_exclusions.txt" "$TMP_DIR/pkg_remove.list" | comm -23 - "$TMP_DIR/pkg_blacklist.list" > "$TMP_DIR/pkg_toremove.list"
```

На выходе получаем `pkg_toremove.list`. Данный файл содержит список пакетов, которые будут удалены с текущей системы.

## Получение списка пакетов установленных на текущей системе
```bash
sort -u "$TMP_DIR/mypkgs_with_exclusions_without_remove.txt" "$TMP_DIR/pkg_install.list" | comm -23 - "$TMP_DIR/pkg_remove.list" > "$TMP_DIR/pkg_installed.list"
```

На выходе получаем `pkg_installed.list`. Данный файл содержит список пакетов, которые будут установлены, а также уже действительно установленных пакетов текущей системы. 

Используется далее для:
- [получение списка пакетов, которые будут установлены на текущей системе](#получение-списка-пакетов-которые,-будут-установлены-на-текущей-системе);
- [получение списка новых пакетов, которые будут добавлены в общий список `pkg_install.txt`](#получение-списка-пакетов-которые,-будут-установлены-на-текущей-системе);


## Получение списка пакетов которые будут установлены на текущей системе
```bash
comm -13 "$TMP_DIR/mypkgs_with_exclusions_without_remove.txt" "$TMP_DIR/pkg_installed.list" | comm -23 - "$TMP_DIR/pkg_blacklist.list" > "$TMP_DIR/pkg_toinstall.list"
```

На выходе получаем `pkg_toinstall.list`. Данный файл содержит список пакетов, которые будут установлены на текущую систему.

## Получение списка новых пакетов, которые будут добавлены в общий список `pkg_install.txt` 
```bash
comm -23 "$TMP_DIR/pkg_installed.list" "$TMP_DIR/pkg_install.list" > "$TMP_DIR/pkg_ourinstall.list"
```

На выходе получаем `pkg_ourinstall.list`. Данный файл содержит список пакетов, которые будут добавлены в общий лист `pkg_install.txt`.

# Дополнительно

Важно! Если машин больше 2, то перед внесением изменений в общий установочный список или список пакетов на удаление нужно на всех машинах синхронизировать текущее состояние репозитория и применить изменения, только затем отправлять новые.

## Хуки

В папке `pacman_hooks` находятся три специальный хука для пакетного менеджера `pacman`:
- `pkg_backup.example.hook` - хук, которые создаёт список со всеми пакетами на системе (с явно установленными и нет);
- `pkg_install.exapmle.hook` - хук, который в случает установки нового пакета, удаляет пакет из списка `pkg_remove`, если этот пакет есть в этом списке;
- `pkg_remove.example.hook` - хук, который создаёт список со всеми удалёнными пакетами в текущем сеансе.

Данные хуки должны распологаться в папке `/etc/pacman.d/hooks/`.

[Подробнее](https://wiki.archlinux.org/title/Pacman#Hooks) о хуках.

## Вариант использования

Списки `pkg_blacklist.list` и `pkg_exclude.list` хранятся в `$HOME/.config/pkgsync/`, так как они уникальны для каждой системы.

Списки `pkg_install.list`, `pkg_remove.list`, `pkg_backup.list` должны хранится в папке, например `pkgsynclist`. В папке должны находится списки и файл конфигурации `config`. 

Сама же папка `pkgsynclist` должна хранится в репозитории или, например, в облачном хранилище.

## Выбор пакетов

При вопросе скрипта `Append packages unique to this computer to install list and run finish script? (yes/no/list/abort/exclude/delete)...`, при выборе `yes` или `exclude` запустится пакет `gum` и предложить выбрать, какие именно пакеты попадут в `pkg_install.list` при выборе - `yes` или в `pkg_exclude` при выборе - `exclude`.

Если, например, выбрать `yes`, отметить нужные пакеты с помощью `gum` и нажать `Enter`, то все пакеты, которые не были выбранны попадут в `pkg_exclude`. Также это работает и наоборот, если выбрать `exclude` вместо `yes`, все невыбранные пакеты попадут в `pkg_install`.

# Зависимости

Этот скрипт предназначен только для тех дистрибутивов Linux, которые используют pacman для управления пакетами. Все зависимости включены в базовую группу Arch Linux, но приведены здесь для общей информации:

Исполняемый | Arch пакет
--- | ---
bash | bash
xargs | findutils
pacman | pacman
comm | coreutils
sort | coreutils
gum | gum

## Ссылки

AUR Пакет: https://aur.archlinux.org/packages/pkgsync
