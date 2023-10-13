---
excerpt_separator: "<!--more-->"
categories:
  - Personal Projects
tags:
  - PSVita
  - Linux
title: Guide for hacking PSVita on Linux
date: 2022-03-14
last_modified_at: 2022-04-24
---

Follow instructions from https://guide.13375384.xyz/start or https://vita.hacks.guide/.

- Documents for compiling from sources for tools.
- Guide to mount TexFAT

**Note:** Put device in airplane mode during the `Content Manager` connection process will make the steps much easier to do.

DON'T MANUALLY SETTING YAMT, JUST USE YAMT SETUP USING VITADEPLOY ([guide](https://guide.13375384.xyz/start))

## FinalHE

Check prerequisites (https://github.com/soarqin/finalhe)

```sh
git clone https://github.com/soarqin/finalhe
cd finalhe
qmake && make
```

Build artifacts in `src/FinalHE`. Copy `VitaDeploy` zip in the same folder as `FinalHE` binary

## YAMT TexFAT mount

Install `exfat-nofuse`. [[Arch AUR]](https://aur.archlinux.org/packages/exfat-utils-nofuse/) [[Other distros build from source]](https://github.com/relan/exfat)

**Note:** Use `rsync` to copy files from host to sd2vita instead of Nautilus or other GUI File Manager.

### Build `exfat-nofuse` from source

```sh
git clone https://github.com/relan/exfat
cd exfat
git checkout v1.3.0
# Patch for `exfat-nofuse`
sed -i "/fuse/d" configure.ac
sed -i "s/ fuse//" Makefile.am
# Build
autoreconf -fiv
./configure --prefix=/usr --sbindir=/usr/bin
make CCFLAGS="${CFLAGS} ${CPPFLAGS} -std=c99" LINKFLAGS="${LDFLAGS}"
# Install
sudo make install
```

### After installing `exfat-nofuse`:

```sh
sudo modprobe exfat
```

## xdelta3

`xdelta3` is a binary diff tool used by some modders (for example, MrComputerRevo on Grisaia Triology + Spin off patch).  
Binary of this library is only available for windows. Build steps are documented below.

```sh
git clone https://github.com/jmacd/xdelta
cd xdelta/xdelta3
git checkout 4b4aed71a959fe11852e45242bb6524be85d3709

export CFLAGS="$CFLAGS -w"
export CXXFLAGS="$CFLAGS -w"

aclocal
autoreconf --install
libtoolize
autoconf
autoheader
automake --add-missing
automake

./configure --disable-dependency-tracking --prefix=/usr --with-liblzma
make
```

Build artifacts in `xdelta/xdelta3/xdelta3`

## NPS Browser and pkg2zip

Use `NPS Browser` and `pkg2zip` with `wine` + `wine-mono`. You don't really need `wine-gecko` for patch checking but if you REALLY want you can just install it.
