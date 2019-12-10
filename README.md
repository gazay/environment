# Как я настраиваю свою систему

Идея взята у @ai, плюс по ходу дела есть ссылки на информацию для определенных
шагов.

## Установка системы

1. Bootable usb from mac
[https://tutorials.ubuntu.com/tutorial/tutorial-create-a-usb-stick-on-macos#0](https://tutorials.ubuntu.com/tutorial/tutorial-create-a-usb-stick-on-macos#0)

2. Заходим в bios и выключаем secured boot

3. Создаем нужные нам шифрованные партишены:

    Информация взята из статьи
    [https://vitobotta.com/2018/01/11/ubuntu-full-disk-encryption-manual-partitioning-uefi/](https://vitobotta.com/2018/01/11/ubuntu-full-disk-encryption-manual-partitioning-uefi/)

    - Загружаемся в live usb в try ubuntu
    - Запускаем gparted и удаляем все существующие партишены, нажимаем apply
    - Создаем партишен fat32 partition of 256MB with name “EFI System Partition”
      and label “ESP”, нажимаем apply
    - right-click на партишен, manage flags, ставим esp, нажимаем apply

    Получили партишен /dev/nvme0n1p1

4. Запускаем установщик:

    - Выбираем minimal install, галка на download updates если есть сеть
    - Выбираем тип Something else чтоб использовать созданный партишен
    - ext2 partition of 512MB that will be used as /boot (the partition will be
      identified as /dev/nvme0n1p2)
    - создаем партишен на оставшееся место с типом “physical volume for
      encryption”, и вводим пароль для расшифровки (the partition will be
      identified as /dev/nvme0n1p3)

    выходим из установщика

5. Запускаем терминал:

    ```bash sudo -s vgcreate system /dev/disk/by-id/dm-name-nvme0n1p3_crypt
    lvcreate -L 20G -n swap system # (нам нужен большой свап для хибернейта)
    lvcreate -L 30G -n root system lvcreate -L 300G -n home system # (оставим в
    запасе неразмеченным еще гигов под 100+ чтоб можно было куда угодно его
    присунуть ```

6. Не закрываем терминал, запускаем установщик опять, опять доходим до Something
else:

    - Правый клик на /dev/nvme0n1p1, Change - проверяем что выставлено use as
      EFI System Partition
    - Правый клик на /dev/nvme0n1p2, Change - смотрим что там выставлено ext2
      file system, кликаем на Format и маунт поинт должен быть на /boot
    - Правый клик на /dev/mapper/system-swap – Change, use as swap area
    - Правый клик на /dev/mapper/system-root – Change, use as ext4, mount '/'
    - Правый клик на /dev/mapper/system-home – Change, use as ext4, mount
      '/home'
    - Выбираем в выпадашке ниже разделов /dev/nvme0n1 в качестве диска для бута
    - Продолжаем инсталляцию, но не закрываем ее по завершению

7. Возвращаемся в терминал

    ```bash blkid /dev/nvme0n1p3 # записываем UUID из команды echo
    'nvme0n1p3_crypt UUID=(uuid without quotes) none luks,discard' >
    /target/etc/crypttab mount -t proc proc /target/proc && mount --rbind /sys
    /target/sys && mount --rbind /dev /target/dev && chroot /target grub-install
    --target=x86_64-efi --efi-directory=/boot/efi --bootloader=ubuntu
    --boot-directory=/boot/efi/EFI/ubuntu --recheck /dev/nvme0n1 grub-mkconfig
    --output=/boot/efi/EFI/ubuntu/grub/grub.cfg update-initramfs -ck all exit
    reboot ```

    `grub-mkconfig` работает сейчас очень медленно в этом случае в связи с
    изменениями в lvm. Прям пару часов. Фиксов для убунты рабочих не нашел.

8. В системе проверяем что у нас доступно hibernate - `cat /sys/power/state`
должен содержать disk

9. `sudo apt install neovim`

10. Фиксим хибернейт:

    - `sudo vim /etc/initramfs-tools/conf.d/resume` прописываем
      `RESUME=/dev/mapper/system-swap`
    - `sudo vim /etc/default/grub` добавляем в `GRUB_CMDLINE_LINUX_DEFAULT` в
      конец

        `resume=/dev/mapper/system-swap`

    - `sudo update-initramfs -u -k all && sudo update-grub`
    - `sudo reboot`

11. Проверяем что хибернейт работает из терминала - `sudo systemctl hibernate`
(после того как комп включите опять должна остаться сессия и терминал в котором
вы вызывали хибернейт

12. Для добавления кнопки
[http://ubuntuhandbook.org/index.php/2018/05/add-hibernate-option-ubuntu-18-04/](http://ubuntuhandbook.org/index.php/2018/05/add-hibernate-option-ubuntu-18-04/)

## Настройка системы

Взял за шаблон репо https://github.com/BenOvermyer/bootstrap-desktop

### Bootstrap с Ansible Playbook

Скрипт, который помогает настроить ubuntu

Он реализован так, что его надо запустить как можно раньше после установки. Надо
лишь установить git (чтоб слить это репо) и соответственно интернет.

### Шаги

1. `sudo apt install git` 2. `git clone https://github.com/gazay/environment` 3.
`sudo ./bootstrap.sh desktop`

В шаге три можно запускать скрипт как с `desktop` так и с другими типами машины
- например `server`

Если это не gazay использует этот скрипт - надо заменить `primary_user`
переменную на свое имя

### Возможный фикс проблем с тачпадом:

https://int3ractive.com/2018/09/make-the-best-of-MacBook-touchpad-on-Ubuntu.html

Для настройки [dispad](https://github.com/BlueDragonX/dispad) для работы с
libinput драйвером надо в конфиге выставить:

```
# ~/.dispad
# name of the property used to enable/disable the trackpad
property = "libinput Tapping Enabled"

# the value used to enable the trackpad
enable = 1

# the value used to disable the trackpad
disable = 0
```
