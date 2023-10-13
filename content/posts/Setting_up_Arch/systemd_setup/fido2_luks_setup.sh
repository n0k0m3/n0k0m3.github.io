#!/usr/bin/env bash

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Must run as root"
    exit
fi

# -x = show every command executed
# -e = abort on failure
set -xe

fido2() {
    # :: FIDO2 systemd-cryptenroll :: #
    local lukspart=($(sudo blkid | grep crypto_LUKS))
    local lukspart=($(sed -r "s/(.*):/\1/" <<< ${lukspart[0]}))
    systemd-cryptenroll --fido2-device=auto $lukspart

    # :: FIDO2 decryption kernel parameters :: #
    local luksuuid=($(blkid | grep crypto_LUKS))
    local luksuuid=($(sed -r "s/UUID=\"(.*)\"/\1/" <<< ${luksuuid[1]}))

    # setup FIDO2 device to unlock luks2 partition, timeout is set to 10 seconds and then secure passphrase is asked
    sed -ri "s/^(luks-.*)/#\1/" /etc/crypttab
    echo "luks-$luksuuid UUID=$luksuuid - fido2-device=auto,token-timeout=10" >> /etc/crypttab
    ln /etc/crypttab /etc/crypttab.initramfs # add crypttab to initramfs
}

post_install() {
    # :: Remake images and grub :: #
    grub-mkconfig -o /boot/grub/grub.cfg
    mkinitcpio -P
}

fido2 "$@"
post_install "$@"