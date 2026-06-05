---
excerpt_separator: "<!--more-->"
categories:
  - Containers
tags:
  - Docker
  - macOS
  - QEMU
  - Virtualization
  - Headless
title: "Running macOS in Docker (Headless with VNC)"
date: 2024-02-14
showtoc: true
---

A streamlined guide to running macOS in Docker using Docker-OSX, with headless VNC access for servers and remote setups.

<!--more-->

## Why Docker-OSX?

Docker-OSX is actually a QEMU VM running under a Docker container, but the setup is significantly more streamlined than configuring QEMU from scratch. It handles all the complex QEMU arguments and macOS-specific configurations for you.

## Important Notes

- **VNC Security:** This setup does NOT secure VNC with a password by default. Only use local VNC or SSH tunnel for remote access.
- **Headless Option:** Remove `-e EXTRA="-display none"` to use head-attached display
- **Port Exposure Warning:** `-p 5999:5999` forwards the VNC port to localhost. **DO NOT** expose this port to public networks without proper encryption
- **VNC Password:** The `Docker-OSX` repo includes a `nakedvnc` dockerfile with encrypted VNC, but no prebuilt image. Build it yourself if you need password protection
- **Screen Resolution:** `WIDTH/HEIGHT` can be modified freely. 1366x768 works well for most use cases

---

## Prerequisites

- Linux host with KVM support enabled
- Docker installed and running
- [Docker-OSX initial setup completed](https://github.com/sickcodes/Docker-OSX#initial-setup)
- VNC viewer: TigerVNC-Viewer or equivalent
- (Optional) `screen` for interacting with Docker in attached mode

---

## Step 1: Create Base macOS Image

Run this script to create the initial macOS installation:

```bash
#!/bin/bash
sudo docker run -it \
    --name macos_base \
    --device /dev/kvm \
    -p 50922:10022 \
    -p 5999:5999 \
    -e NOPICKER=true \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e "DISPLAY=${DISPLAY:-:0.0}" \
    -e EXTRA="-display none -vnc 0.0.0.0:99" \
    -e WIDTH=1366 \
    -e HEIGHT=768 \
    sickcodes/docker-osx:latest
```

**Connect via VNC:**
- **Local:** Connect to `localhost:5999` (no password)
- **Remote (LAN only):** Connect to `<host-ip>:5999`

**⚠️ Security Note:** VNC is unencrypted. For remote access, use SSH tunnel:
```bash
ssh -L 5999:localhost:5999 user@remote-server
# Then connect VNC to localhost:5999
```

---

## Step 2: Install macOS

1. **Partition the disk:**
   - Follow [Docker-OSX boot instructions](https://github.com/sickcodes/Docker-OSX#additional-boot-instructions-for-when-you-are-creating-your-container)
   - Open Disk Utility in the macOS installer
   - Erase the virtual disk as APFS

2. **Install macOS:**
   - Complete macOS installation as normal
   - Login with iCloud if needed
   - **Important:** Do NOT open iMessage yet (wait until after serial number setup)

3. **Shutdown:**
   - Either shutdown from within the VNC session
   - Or use QEMU command: `quit`

---

## Step 3: Extract the Disk Image

Find and copy the `mac_hdd_ng.img` file from Docker storage:

```bash
#!/bin/bash
sudo cp `sudo find /var/lib/docker -size +10G -name mac_hdd_ng.img | head -1` .
```

**Why this works:** Docker-OSX creates the disk image somewhere in `/var/lib/docker`. This finds files named `mac_hdd_ng.img` larger than 10GB and copies the first match to your current directory.

**Cleanup:**
```bash
sudo docker rm macos_base
```

---

## Step 4: Generate Unique Serial Number

Generate a unique serial number for your macOS installation (required for iMessage, iCloud):

```bash
#!/bin/bash
mkdir tmp && cd tmp
curl https://raw.githubusercontent.com/sickcodes/Docker-OSX/master/custom/generate-unique-machine-values.sh -O
chmod +x generate-unique-machine-values.sh
./generate-unique-machine-values.sh --count 1 --output-env ../my_permanent_serial_number.sh
cd ..
rm -rf tmp
```

### Alternative: Use Existing Serial

If you already have a working serial configuration (e.g., from a physical Mac or previous Hackintosh):

```bash
nano my_permanent_serial_number.sh
```

**Content:**
```bash
export DEVICE_MODEL="DEVICE_MODEL_HERE"
export SERIAL="SERIAL_HERE"
export BOARD_SERIAL="BOARD_SERIAL_HERE"
export UUID="UUID_HERE"
export MAC_ADDRESS="MAC_ADDRESS_HERE"
export WIDTH="1366"
export HEIGHT="768"
```

Save and exit: `Ctrl+X`, `Y`, `Enter`

---

## Step 5: First Run with Serial Number

```bash
#!/bin/bash
source ./my_permanent_serial_number.sh
sudo docker run -i \
    --name macos \
    --privileged \
    --device /dev/kvm \
    -v "${PWD}/mac_hdd_ng.img:/image" \
    -p 5999:5999 \
    -p 1234:1234 \
    -p 50922:10022 \
    -e TERMS_OF_USE=i_agree \
    -e NOPICKER=true \
    -e GENERATE_SPECIFIC=true \
    -e DEVICE_MODEL="${DEVICE_MODEL}" \
    -e SERIAL="${SERIAL}" \
    -e BOARD_SERIAL="${BOARD_SERIAL}" \
    -e UUID="${UUID}" \
    -e MAC_ADDRESS="${MAC_ADDRESS}" \
    -e "DISPLAY=${DISPLAY:-:0.0}" \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e EXTRA="-display none -vnc 0.0.0.0:99" \
    -e WIDTH="${WIDTH}" \
    -e HEIGHT="${HEIGHT}" \
    sickcodes/docker-osx:naked
```

**What's different:**
- Uses `sickcodes/docker-osx:naked` (lighter image without installer)
- Mounts your extracted disk image: `-v "${PWD}/mac_hdd_ng.img:/image"`
- Injects serial number variables

---

## Step 6: Setup iMessage (Optional)

1. Connect via VNC
2. Open iMessage and setup iCloud Sync
3. **If iMessage activation fails:** Follow the [How to Fix iMessage guide from tonymacx86](https://www.tonymacx86.com/threads/how-to-fix-imessage.110471/#TOP8)
4. Setup BlueBubbles or AirMessage for remote messaging (optional)

---

## Subsequent Runs

Use `screen` to run Docker in the background with attached stdio (useful for QEMU shell access):

```bash
#!/bin/bash
screen -dmS macos-docker docker start -ai macos
```

**Attach to the session:**
```bash
screen -r macos-docker
```

**Detach:** `Ctrl+A`, `D`

**Or run without screen:**
```bash
docker start macos
```

---

## Post-Install Tips

### SSH Access

The container forwards port `50922` to macOS SSH port `10022`:

```bash
ssh -p 50922 username@localhost
```

**Enable SSH in macOS:**
1. System Preferences → Sharing
2. Enable "Remote Login"

### File Transfer

Use `scp` to transfer files between host and macOS:

```bash
# From host to macOS
scp -P 50922 file.txt username@localhost:/Users/username/

# From macOS to host
scp -P 50922 username@localhost:/Users/username/file.txt .
```

### Secure VNC Access

For remote access, use SSH tunneling instead of exposing VNC directly:

```bash
# On your local machine
ssh -L 5999:localhost:5999 user@remote-server

# Then connect VNC to localhost:5999
```

### Port Mapping Reference

| Service | Container Port | Host Port |
|---------|---------------|-----------|
| SSH | 10022 | 50922 |
| VNC | 5999 | 5999 |
| QEMU Monitor | 1234 | 1234 |

---

## Troubleshooting

### Issue: KVM not available

**Error:** `/dev/kvm: Permission denied`

**Fix:**
```bash
# Add your user to kvm group
sudo usermod -aG kvm $USER
# Logout and login again

# Verify KVM is enabled
lsmod | grep kvm
```

### Issue: VNC shows black screen

**Possible causes:**
1. macOS is still booting (wait 2-3 minutes)
2. QEMU crashed (check Docker logs)

**Check logs:**
```bash
docker logs macos
```

### Issue: Out of disk space

The macOS disk image can grow to 200GB+.

**Check image size:**
```bash
ls -lh mac_hdd_ng.img
```

**Expand disk if needed:**
```bash
qemu-img resize mac_hdd_ng.img +50G
# Then expand the APFS container in macOS Disk Utility
```

### Issue: iMessage not activating

**Troubleshooting steps:**
1. Verify serial number is unique (not used elsewhere)
2. Check system information matches (System Information → Hardware → Model)
3. Follow the [tonymacx86 iMessage fix guide](https://www.tonymacx86.com/threads/how-to-fix-imessage.110471/)
4. Contact Apple Support if necessary

---

## Use Cases

**Development:**
- Build and test iOS/macOS applications
- Xcode development on non-Mac hardware
- Cross-platform testing

**Automation:**
- CI/CD pipelines for Apple platform builds
- Automated app signing and distribution
- iMessage/SMS automation via BlueBubbles

**Utility:**
- Access macOS-exclusive applications
- iMessage on Linux/server environments
- AirDrop functionality (with proper hardware passthrough)

---

## Performance Tuning

### CPU Allocation

Add CPU pinning for better performance:

```bash
-e EXTRA="-display none -vnc 0.0.0.0:99 -smp 4,cores=2"
```

### Memory Allocation

Default is ~4GB. Increase with:

```bash
-e RAM=8  # 8GB RAM
```

### GPU Passthrough (Advanced)

For graphics-intensive workloads, consider GPU passthrough (requires additional QEMU configuration and compatible hardware).

---

## References

- [Docker-OSX GitHub Repository](https://github.com/sickcodes/Docker-OSX)
- [tonymacx86 Forums](https://www.tonymacx86.com/)
- [QEMU Documentation](https://www.qemu.org/documentation/)

---

**Created:** 2025-12-02
**Tested On:** Arch Linux, Ubuntu 22.04+, Docker 24.0+
**macOS Versions:** Monterey, Ventura, Sonoma
