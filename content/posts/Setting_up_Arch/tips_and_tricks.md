---
excerpt_separator: "<!--more-->"
categories:
  - Setting up Arch
tags:
  - Linux
title: Setting up Arch - Part 4 - Tips and Tricks
date: 2021-11-18
lastmod: 2022-05-03
---

## `fstab` mount with user permssion

Use KDE/GNOME partition manager to manage mount point and use mount options: `uid=1000,gid=1001,umask=022`  
Or append to `/etc/fstab`:

```
UUID=<disk_UUID>   <mount_point>    <format>    uid=1000,gid=1001,umask=022,noatime 0 1
```

## `fstab` mount NTFS with kernel `NTFS3` driver from kernel 5.15

Use KDE/GNOME partition manager to manage mount point, this will use the default `mount.ntfs -> ntfs-3g` driver. We need to change the mount driver to `mount.ntfs3` in `/etc/fstab`:

```
UUID=<disk_UUID>   <mount_point>    ntfs3       discard,noatime                     0 0
```