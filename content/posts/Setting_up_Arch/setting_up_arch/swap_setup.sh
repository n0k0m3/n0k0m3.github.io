#!/usr/bin/env bash

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Must run as root"
    exit
fi

# -x = show every command executed
# -e = abort on failure
set -xe

main() {
    # :: swap :: #
    SWAP_SIZE=`free -m | awk '/^Mem:/ {print $2+4096}'`

    luksdevice=`sudo blkid -o device | grep luks`

    # :: Create swap subvolume :: #
    mount $luksdevice /mnt
    btrfs subvolume create /mnt/@swap
    umount /mnt
    mkdir /swap
    mount -o subvol=@swap $luksdevice /swap

    # :: Create swap file :: #
    truncate -s 0 /swap/swapfile
    chattr +C /swap/swapfile

    btrfs property set /swap/swapfile compression none

    dd if=/dev/zero of=/swap/swapfile bs=1M count=$SWAP_SIZE status=progress
    chmod 600 /swap/swapfile
    mkswap /swap/swapfile
    swapon /swap/swapfile

    # :: btrfs_map_physical :: #
    wget https://raw.githubusercontent.com/osandov/osandov-linux/master/scripts/btrfs_map_physical.c
    gcc -O2 -o btrfs_map_physical btrfs_map_physical.c

    # :: edit grub, mkinitcpio :: #
    offset=$(./btrfs_map_physical /swap/swapfile)
    offset_arr=($(echo ${offset}))
    offset_pagesize=($(getconf PAGESIZE))
    offset=$((offset_arr[25] / offset_pagesize))
    btrfsonluks=`sudo blkid -o device | grep luks`

    sed -ri "s#^(GRUB_CMDLINE_LINUX_DEFAULT.+)\"#\1 resume=$btrfsonluks resume_offset=$offset\"#" /etc/default/grub
    sed -ri "s/^(HOOKS.*filesystems)/\1 resume/" /etc/mkinitcpio.conf

    # :: Add swap to fstab :: #
    echo "$btrfsonluks /swap          btrfs   subvol=/@swap,defaults,compress=no 0 0" >> /etc/fstab
    echo '/swap/swapfile none swap defaults 0 0' >> /etc/fstab
    # :: remake images :: #
    grub-mkconfig -o /boot/grub/grub.cfg
    mkinitcpio -P

    # :: cleanup :: #
    rm -f btrfs_map_physical.c
    rm -f btrfs_map_physical

    echo 'All done, please reboot!'
}

main "$@"
