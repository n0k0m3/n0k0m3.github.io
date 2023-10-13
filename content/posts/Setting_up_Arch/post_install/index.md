---
excerpt_separator: "<!--more-->"
categories:
  - Setting up Arch
tags:
  - Linux
title: Setting up Arch - Part 3 - Post-Installation Setup
date: 2021-11-17
lastmod: 2022-06-19
---

## Install [`zsh4humans`](https://github.com/romkatv/zsh4humans)

I don't need anything more fancy than romkatv's `zsh4humans`

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/n0k0m3/Personal-Setup/main/Setting_up_Arch/setup.sh)"
```

## Install Nextcloud

```sh
sudo pacman -S nextcloud-client
```

Sync `.dotfiles` with Nextcloud + `flameshot` shortcut

## Setting up `pacman` and `makepkg` config

```sh
sudo nano /etc/pacman.conf
```

Set `ParallelDownloads = 10`:

```sh
sudo nano /etc/makepkg.conf
```

Set compile flags `CFLAGS="-march=native -mtune=native ..."` and `MAKEFLAGS="-j12"` for `12` being total number of available cores/threads:

## Comparing current installation with installed packages of previous dist

```sh
python3 read_install.py <installed.log file>
```

### Update `installed.log` with current setup

[Download export_install_deps.py](https://raw.githubusercontent.com/n0k0m3/Personal-Setup/main/Setting_up_Arch/export_install_deps.py){: .btn .btn--info }

```sh
python export_install_deps.py --installed -q > installed.log
```