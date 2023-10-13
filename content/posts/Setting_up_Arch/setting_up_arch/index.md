---
excerpt_separator: "<!--more-->"
categories:
  - Setting up Arch
tags:
  - Linux
title: Setting up Arch - Part 1 - Swap on BTRFS
date: 2021-11-15
lastmod: 2023-01-16
---

This is setup on EndeavourOS/Manjaro, on barebone Arch should be a little bit different (install `yay` before all of these steps)

## Arch setup

Setting up Manjaro/EndeavourOS with Calamares installer using this partition Setup with SWAP file (turn on hibernation option):

| Partition            | Mount Point | Filesystem | Size          | Encryption Status |
| -------------------- | ----------- | ---------- | ------------- | ----------------- |
| EFI system partition | `/boot/efi` | FAT32      | 300-550 MB    | Unencrypted       |
| `/boot` partition    | `/boot/efi` | ext4       | 200-500 MB    | Unencrypted       |
| `root` partition     | `/`         | btrfs/LUKS | Rest of space | Encrypted         |

Note: mount EFI with `boot` flag and `/` with `root` flag.

## Hide `GRUB` at boot

```sh
$ sudo nano /etc/default/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT=1
GRUB_TIMEOUT_STYLE=hidden
```

## Add swap after installation

As of the latest update, EndeavourOS/Manjaro now use latest Calamares installer (resolved this [tracked issue](https://github.com/calamares/calamares/issues/1659)), which supports `swap` file on encrypted `btrfs` natively. The below steps are for reference only.

<s>
Requires `gcc`, `wget` to be installed (default on EndeavourOS)

Just need to run:

```sh
sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/n0k0m3/Personal-Setup/main/Setting_up_Arch/swap_setup.sh)"
```

And Done!
</s>

## References

- https://discovery.endeavouros.com/btrfs/btrfs-resume-and-hibernate-setup/2021/12/
- https://discovery.endeavouros.com/encrypted-installation/btrfsonluks-quick-copy-paste-version/2021/03/
- https://discovery.endeavouros.com/storage-and-partitions/adding-swap-after-installation/2021/03/
