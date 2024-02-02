Fork [pkgsync](https://github.com/moparisthebest/pkgsync)

# pkgsync
Простой скрипт для синхронизации установленных пакетов между машинами на базе Arch Linux.

# Использование

## Конфигурационный файл
Конфигурационный файл, по задумке, содержит только пути до основных файлов и ничего больше в формате `EXCLUSION_LIST=PATH`:

- [`EXCLUSION_LIST`](##EXCLUSION_LIST);
- [`BLACKLIST_LIST`](##BLACKLIST_LIST); 
- [`REMOVE_LIST`](##REMOVE_LIST); 
- [`INSTALL_LIST`](##INTSALL_LIST); 
- [`PRESTART_SCRIPT`](##PRESTART_SCRIPT);
- [`FINISH_SCRIPT`](##FINISH_SCRIPT);
- [`TMP_DIR`](##TMP_DIR).

В целом, даже если конфигурационного файла и не будет существовать, все пути до основных файлов в скрипте `pkgsync` будут утсановлены по умолчанию:

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

[ -e /ваш/путь/до_файла ] && . /ваш/путь/до_файла
```

# Зависимости
Этот скрипт предназначен только для тех дистрибутивов Linux, которые используют pacman для управления пакетами. Все зависимости включены в базовую группу Arch Linux, но приведены здесь для общей информации:
Исполняемый | Arch пакет
--- | ---
bash | bash
xargs | findutils
pacman | pacman
comm | coreutils
sort | coreutils

## Ссылки
AUR Пакет: https://aur.archlinux.org/packages/pkgsync
