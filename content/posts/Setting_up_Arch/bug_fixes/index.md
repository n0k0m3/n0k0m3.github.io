---
excerpt_separator: "<!--more-->"
categories:
  - Setting up Arch
tags:
  - Linux
title: Setting up Arch - Part 5 - Bugs Fixes
date: 2022-05-03
lastmod: 2022-05-03
---

## OBS Studio flickering with Intel Graphics

With some Intel graphics cards on XOrg (in my case, Tiger Lake Xe), OBS Studio will flicker with screen capture.

```sh
sudo nano /etc/X11/xorg.conf.d/20-intel.conf
```
```
Section "Device"
    Identifier "Intel Graphics"
    Driver "modesetting"
EndSection
```

Reboot or restart XOrg server to apply the fix.

## Delete Goodix Fingerprint Sensor saved fingerprint data

If you installed Windows and enrolled fingerprints with Goodix Fingerprint Sensor, the saved fingerprint data will prevent new enrollments in Linux.

**Requirements:** 
- `libfprint`, `fprintd` for fingerprint sensor
- `python3` to run the script

Download the following script and run it (adapted from [this issue](https://gitlab.freedesktop.org/libfprint/libfprint/-/issues/415#note_1063158) but use the new `clear_storage_sync()` method instead of `delete_print_sync()` loop):

[Download delete_goodix_fingerprint_data.py](https://raw.githubusercontent.com/n0k0m3/Personal-Setup/main/Setting_up_Arch/delete_goodix_fingerprint_data.py){: .btn .btn--info }

```sh
sudo python3 delete_goodix_fingerprint_data.py
```

**Other Solution** 

Another solution is provided by `Devyn_Cairns` from Framework Community [(Link to the solution)](https://community.frame.work/t/fingerprint-scanner-compatibility-with-linux-ubuntu-fedora-etc/1501/214). The author provided an AppImage to run the script with all dependencies. From my testing it's more stable than my script.

```sh
sudo ./fprint-clear-storage-0.0.1-x86_64.AppImage
```