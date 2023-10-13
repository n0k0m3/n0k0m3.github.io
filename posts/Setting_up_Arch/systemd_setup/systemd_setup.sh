#!/usr/bin/env bash

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Must run as root"
    exit
fi

# -x = show every command executed
# -e = abort on failure
set -xe

module_hooks() {
    # :: set modules nvidia or intel (i915) :: #
    local module_nvidia=$(lsmod | grep nvidia)
    local module_intel=$(lsmod | grep i915)
    # :: if lsmod not empty :: #
    if ! [ -z "$module_nvidia" ]
    then
        echo "nvidia nvidia_modeset nvidia_uvm nvidia_drm"
    elif ! [ -z "$module_intel" ]
    then
        echo "i915"
    else
        echo "Non NVIDIA/Intel module detected, exiting"
        exit 1
    fi
}

hooks() {
    # :: Switch to systemd hooks :: #
    sed -ri "s/^(HOOKS=\"base).*(autodetect.+keyboard).+(encrypt) (.+)/\1 systemd \2 sd-vconsole sd-encrypt \4/" /etc/mkinitcpio.conf

    # :: Kernel parameters for systemd hooks :: #
    local luksuuid=($(blkid | grep crypto_LUKS))
    local luksuuid=($(sed -r "s/UUID=\"(.*)\"/\1/" <<< ${luksuuid[1]}))
    # luksdevice=($(echo luks-$luksuuid))
    # lukspart=($(echo /dev/mapper/$luksdevice))
    sed -ri "s/cryptdevice.+ (root)/rd.luks.uuid=$luksuuid \1/" /etc/default/grub
}

plymouth() {
    # :: plymouth hooks :: #
    sed -ri "s/^(HOOKS=\"base systemd)/\1 sd-plymouth/" /etc/mkinitcpio.conf
    local modules=$(module_hooks)
    sed -ri "s/^(MODULES=\")/\1$modules /" /etc/mkinitcpio.conf

    # :: plymouth kernel parameters :: #
    sed -ri "s/^(GRUB_CMDLINE_LINUX_DEFAULT.+)\"/\1 quiet splash vt.global_cursor_default=0 fbcon=nodefer\"/" /etc/default/grub

    # :: plymouth config :: #
    sed -ri "s/^(Theme=).+/\1colorful_loop/" /etc/plymouth/plymouthd.conf
    sed -ri "s/^(ShowDelay=).+/\10/" /etc/plymouth/plymouthd.conf

    # :: plymouth smooth transition :: #
    local displaymanager=($(systemctl status display-manager))
    local plymouthdm=($(sed -r "s/(.*)(\.service)/\1-plymouth\2/" <<< ${displaymanager[1]}))
    systemctl disable ${displaymanager[1]}
    systemctl enable $plymouthdm
}

post_install() {
    # :: Remake images and grub :: #
    grub-mkconfig -o /boot/grub/grub.cfg
    mkinitcpio -P
}

hooks "$@"
plymouth "$@"
post_install "$@"