---
excerpt_separator: "<!--more-->"
categories:
  - Homelab
tags:
  - Proxmox
  - LXC
  - ZFS
  - Samba
  - NFS
  - Linux
  - Storage
title: "Multi-User Samba/NFS Setup with ZFS Datasets on Proxmox"
date: 2025-11-28
showtoc: true
---

Production-tested guide for setting up a multi-service storage architecture using ZFS datasets, unprivileged LXC containers, ACLs, and Samba/NFS sharing on Proxmox.

<!--more-->

> **Note:** IP addresses, usernames, MAC addresses, and network topology shown are examples from a working configuration. Adjust all values to match your environment.

## Overview

This guide describes a multi-service storage architecture using ZFS datasets, unprivileged LXC containers, ACLs, and Samba/NFS sharing.

### Architecture

```
Proxmox Host (hdd_pool datasets)
├── Cockpit LXC (CTID 100) - Samba + NFS Server
│   ├── Users: mainuser(1000), deviceuser(1001), user1(1002), user2(1003)
│   └── Mounts: main-nas, photo, device-cam, media, nvr
├── NVR LXC (CTID 101) - Network Video Recorder
│   └── Mount: nvr dataset
├── Syncthing LXC (CTID 102) - Photo Sync
│   └── Mount: photo dataset
└── Media Server (Ubuntu) - via NFS from Cockpit LXC
    └── NFS mount: media from Cockpit
```

---

## ZFS Datasets

| Dataset | Primary Use | Primary Owner | Access Method |
|---------|-------------|---------------|---------------|
| `hdd_pool/main-nas` | General file storage | Cockpit (mainuser) | SMB |
| `hdd_pool/photo` | Syncthing photos | Syncthing LXC | SMB (read) |
| `hdd_pool/device-cam` | Dashcam uploads | Cockpit (deviceuser) | SMB, rsync |
| `hdd_pool/media` | Media library (Plex/Jellyfin) | Cockpit (mainuser) | SMB, NFS |
| `hdd_pool/nvr` | NVR recordings | NVR LXC | Direct mount, SMB |

---

## UID/GID Mapping Strategy

### Unprivileged LXC Mapping

Each unprivileged LXC has different UID mapping to avoid conflicts:

**Cockpit LXC (CTID 100):**
```
# Standard unprivileged LXC (default, no manual config needed)
# Automatically uses:
# lxc.idmap: u 0 100000 65536
# lxc.idmap: g 0 100000 65536
```
- Container uid 1000 (mainuser) → Host uid 101000
- Container uid 1001 (deviceuser) → Host uid 101001
- Container uid 1002 (user1) → Host uid 101002
- Container uid 1003 (user2) → Host uid 101003
- Container gid 10000 (nas_share) → Host gid 110000

**NVR LXC (CTID 101):**
```
lxc.idmap: u 0 165536 65536
lxc.idmap: g 0 165536 65536
```
- Container root (0) → Host uid 165536

**Syncthing LXC (CTID 102):**
```
lxc.idmap: u 0 231072 65536
lxc.idmap: g 0 231072 65536
```
- Container root (0) → Host uid 231072

---

## Dataset Configuration on Proxmox Host

### Setup Script

```bash
#!/bin/bash
# setup-dataset-acls.sh - Run on Proxmox host as root

# Cockpit LXC mapped UIDs
COCKPIT_MAINUSER=101000
COCKPIT_DEVICEUSER=101001
COCKPIT_USER1=101002
COCKPIT_USER2=101003
COCKPIT_GROUP=110000  # nas_share group

# Other LXC root UIDs
NVR_ROOT=165536
SYNCTHING_ROOT=231072

echo "=== Configuring main-nas ==="
# Owner: root, ACL: mainuser, (future: user1)
chown -R 0:0 /hdd_pool/main-nas
setfacl -R -m u:${COCKPIT_MAINUSER}:rwx,g:${COCKPIT_GROUP}:rwx \
           -d -m u:${COCKPIT_MAINUSER}:rwx,g:${COCKPIT_GROUP}:rwx \
           /hdd_pool/main-nas

echo "=== Configuring photo ==="
# Owner: root, ACL: syncthing, mainuser, user2
chown -R 0:0 /hdd_pool/photo
setfacl -R -m u:${SYNCTHING_ROOT}:rwx,u:${COCKPIT_MAINUSER}:rwx,u:${COCKPIT_USER2}:rwx \
           -d -m u:${SYNCTHING_ROOT}:rwx,u:${COCKPIT_MAINUSER}:rwx,u:${COCKPIT_USER2}:rwx \
           /hdd_pool/photo

echo "=== Configuring device-cam ==="
# Owner: root, ACL: deviceuser, mainuser
chown -R 0:0 /hdd_pool/device-cam
setfacl -R -m u:${COCKPIT_DEVICEUSER}:rwx,u:${COCKPIT_MAINUSER}:rwx,g:${COCKPIT_GROUP}:rwx \
           -d -m u:${COCKPIT_DEVICEUSER}:rwx,u:${COCKPIT_MAINUSER}:rwx,g:${COCKPIT_GROUP}:rwx \
           /hdd_pool/device-cam

echo "=== Configuring media ==="
# Owner: root, ACL: mainuser, user2
chown -R 0:0 /hdd_pool/media
setfacl -R -m u:${COCKPIT_MAINUSER}:rwx,u:${COCKPIT_USER2}:rwx,g:${COCKPIT_GROUP}:rwx \
           -d -m u:${COCKPIT_MAINUSER}:rwx,u:${COCKPIT_USER2}:rwx,g:${COCKPIT_GROUP}:rwx \
           /hdd_pool/media

echo "=== Configuring nvr ==="
# Owner: root, ACL: nvr + mainuser
chown -R 0:0 /hdd_pool/nvr
setfacl -R -m u:${NVR_ROOT}:rwx,u:${COCKPIT_MAINUSER}:rwx \
           -d -m u:${NVR_ROOT}:rwx,u:${COCKPIT_MAINUSER}:rwx \
           /hdd_pool/nvr

echo "✓ All datasets configured"
```

### Verification

```bash
# Check ACLs on each dataset
getfacl /hdd_pool/main-nas
getfacl /hdd_pool/photo
getfacl /hdd_pool/device-cam
getfacl /hdd_pool/media
getfacl /hdd_pool/nvr
```

Expected output example for main-nas:
```
# file: hdd_pool/main-nas/
# owner: root
# group: root
user::rwx
user:101000:rwx          # mainuser in Cockpit LXC
group::rwx
group:110000:rwx         # nas_share group
mask::rwx
other::---
default:user::rwx
default:user:101000:rwx
default:group::rwx
default:group:110000:rwx
default:mask::rwx
default:other::---
```

---

## LXC Mount Configuration

### Cockpit LXC (`/etc/pve/lxc/100.conf`)

```conf
# ... other config ...
# No manual UID mapping needed - uses standard unprivileged defaults

# Mount datasets
mp0: /hdd_pool/main-nas,mp=/mnt/main-nas
mp1: /hdd_pool/photo,mp=/mnt/photo
mp2: /hdd_pool/device-cam,mp=/mnt/device-cam
mp3: /hdd_pool/media,mp=/mnt/media
mp4: /hdd_pool/nvr,mp=/mnt/nvr
```

### NVR LXC (`/etc/pve/lxc/101.conf`)

```conf
# UID mapping (offset to avoid conflicts)
lxc.idmap: u 0 165536 65536
lxc.idmap: g 0 165536 65536

# Mount dataset
mp0: /hdd_pool/nvr,mp=/mnt/nvr
```

### Syncthing LXC (`/etc/pve/lxc/102.conf`)

```conf
# UID mapping (offset to avoid conflicts)
lxc.idmap: u 0 231072 65536
lxc.idmap: g 0 231072 65536

# Mount dataset
mp0: /hdd_pool/photo,mp=/mnt/photo
```

---

## Samba Configuration (Cockpit LXC)

### User Setup

```bash
# Inside Cockpit LXC container
apt update
apt install cockpit-file-sharing samba

# Create users with specific UIDs
useradd -u 1000 -m mainuser
useradd -u 1001 -m deviceuser
useradd -u 1002 -m user1
useradd -u 1003 -m user2

# Create nas_share group
groupadd -g 10000 nas_share

# Add users to group
usermod -aG nas_share mainuser
usermod -aG nas_share deviceuser
usermod -aG nas_share user1
usermod -aG nas_share user2

# Set Samba passwords (CRITICAL - don't forget!)
smbpasswd -a mainuser
smbpasswd -a deviceuser
smbpasswd -a user1
smbpasswd -a user2
```

### Samba Shares (`/etc/samba/smb.conf`)

```ini
[global]
workgroup = WORKGROUP
server string = Homelab NAS
security = user
map to guest = Bad User
log file = /var/log/samba/%m.log
max log size = 50

[main-nas]
path = /mnt/main-nas
valid users = mainuser, user1
read only = no
browseable = yes
create mask = 0664
directory mask = 0775

[photo]
path = /mnt/photo
valid users = mainuser, user2
read only = no
browseable = yes
create mask = 0664
directory mask = 0775

[device-cam]
path = /mnt/device-cam
valid users = mainuser, deviceuser
read only = no
browseable = yes
create mask = 0664
directory mask = 0775

[media]
path = /mnt/media
valid users = mainuser, user2
read only = no
browseable = yes
create mask = 0664
directory mask = 0775

[nvr]
path = /mnt/nvr
valid users = mainuser
read only = no
browseable = yes
create mask = 0664
directory mask = 0775
```

**Alternative:** Use Cockpit web UI → File Sharing to configure shares graphically.

### Restart Samba

```bash
systemctl restart smbd
systemctl enable smbd
```

---

## NFS Configuration (for Media Server)

### Using Cockpit LXC (Recommended)

**Inside Cockpit LXC:**

1. **Install NFS server:**
```bash
apt update
apt install nfs-kernel-server
```

2. **Configure via Cockpit Web UI:**
   - Navigate to Cockpit web interface
   - Go to **Storage** → **NFS**
   - Click **Add NFS Export**
   - Configure:
     - **Path:** `/mnt/media`
     - **Hosts:** Your media server IP or subnet (e.g., `192.168.1.0/24`)
     - **Options:** `rw,sync,no_subtree_check`
     - **Squash:** `all` with UID/GID `1000:1000` (or your media server user's IDs)

3. **Verify export:**
```bash
exportfs -v
# Should show: /mnt/media  192.168.1.0/24(rw,sync,...)
```

### Alternative: Manual Configuration

If Cockpit NFS isn't available, configure manually:

```bash
# Inside Cockpit LXC - /etc/exports
/mnt/media 192.168.1.0/24(rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=1000)

# Apply changes
exportfs -ra
systemctl restart nfs-kernel-server
```

### On Media Server (Ubuntu)

```bash
# Install NFS client
apt install nfs-common

# Create mount point
mkdir -p /mnt/media

# Add to /etc/fstab (use Cockpit LXC IP, not Proxmox host)
# Replace <cockpit-lxc-ip> with your Cockpit LXC IP address
<cockpit-lxc-ip>:/mnt/media  /mnt/media  nfs  defaults,_netdev  0  0

# Mount
mount -a
```

---

## Access Matrix

| User | main-nas | photo | device-cam | media | nvr |
|------|----------|-------|------------|-------|-----|
| mainuser | ✅ RW | ✅ RW | ✅ RW | ✅ RW | ✅ RW |
| deviceuser | ❌ | ❌ | ✅ RW | ❌ | ❌ |
| user1 | ✅ RW (future) | ❌ | ❌ | ❌ | ❌ |
| user2 | ❌ | ✅ RW | ❌ | ✅ RW | ❌ |
| Syncthing LXC | ❌ | ✅ RW | ❌ | ❌ | ❌ |
| NVR LXC | ❌ | ❌ | ❌ | ❌ | ✅ RW |
| Media Server (NFS) | ❌ | ❌ | ❌ | ✅ RO | ❌ |

---

## Client Mount Examples

### Linux (via fstab)

Create credentials file:
```bash
# ~/.smbcredentials
username=mainuser
password=YourPasswordHere
```

```bash
chmod 600 ~/.smbcredentials
```

Add to `/etc/fstab`:
```fstab
//192.168.1.100/main-nas  /home/mainuser/nas_mount/main-nas  cifs  _netdev,nofail,credentials=/home/mainuser/.smbcredentials,x-systemd.automount  0  0
//192.168.1.100/media     /home/mainuser/nas_mount/media     cifs  _netdev,nofail,credentials=/home/mainuser/.smbcredentials,x-systemd.automount  0  0
```

Mount:
```bash
sudo mount -a
```

### Windows

```
\\192.168.1.100\main-nas
\\192.168.1.100\media
```

Map network drive with credentials: `mainuser` / password

### macOS

Finder → Go → Connect to Server:
```
smb://192.168.1.100/main-nas
```

---

## Troubleshooting

### Issue: Mount fails with error `-13`

**Cause:** Missing Samba password for user

**Fix:**
```bash
# Inside Cockpit LXC
smbpasswd -a username
```

### Issue: Files show as `nobody:nogroup` inside container

**Cause:** Host ownership (uid 0) is outside unprivileged LXC's mapped range

**Status:** **This is normal and expected!** ACLs still work correctly.

**Verification:**
```bash
# Inside Cockpit LXC
getfacl /mnt/main-nas
# Should show: user:mainuser:rwx in ACL entries
```

### Issue: New files don't inherit ACLs

**Cause:** Default ACLs not set on parent directory

**Fix:**
```bash
# On Proxmox host
setfacl -R -d -m u:101000:rwx,g:110000:rwx /hdd_pool/main-nas
```

### Issue: Permission denied when writing from container

**Cause:** ACL not set for container's mapped UID

**Fix:**
```bash
# On Proxmox host - verify ACL includes correct mapped UID
getfacl /hdd_pool/main-nas | grep 101000

# If missing, add it:
setfacl -R -m u:101000:rwx -d -m u:101000:rwx /hdd_pool/main-nas
```

### Issue: NFS mount read-only

**Cause:** Wrong options in `/etc/exports`

**Fix:** Ensure `rw` option is present and `exportfs -ra` was run

---

## Adding New Datasets

When creating a new dataset that needs container access:

```bash
# 1. Create dataset
zfs create hdd_pool/new-dataset

# 2. Set ownership and ACLs on Proxmox host
chown -R 0:0 /hdd_pool/new-dataset
setfacl -R -m u:101000:rwx,g:110000:rwx -d -m u:101000:rwx,g:110000:rwx /hdd_pool/new-dataset

# 3. Add mountpoint to LXC config
# Edit: /etc/pve/lxc/100.conf
mp5: /hdd_pool/new-dataset,mp=/mnt/new-dataset

# 4. Restart container
pct stop 100 && pct start 100

# 5. Configure Samba share (if needed)
# Inside container: edit /etc/samba/smb.conf or use Cockpit UI
```

---

## Adding New Users

### In Cockpit LXC:

```bash
# 1. Create user with next available UID
useradd -u 1004 -m user3

# 2. Add to nas_share group
usermod -aG nas_share user3

# 3. Set Samba password
smbpasswd -a user3

# 4. Grant ACL access on Proxmox host (for datasets user3 needs)
# On Proxmox:
setfacl -R -m u:101004:rwx -d -m u:101004:rwx /hdd_pool/main-nas

# 5. Update Samba share config to add user3 to valid_users list
```

---

## Key Learnings

1. **Unprivileged LXC + ACLs is the correct approach** for multi-container storage sharing
2. **`nobody:nogroup` ownership inside container is normal** when host files are owned by unmapped UIDs
3. **ACLs work transparently with Samba** - no need for `force user` directives
4. **Each ZFS dataset needs its own ACLs** - default ACLs don't cross dataset boundaries
5. **Different LXC UID mapping bases prevent conflicts** when multiple containers need root access
6. **Always set Samba passwords** - even with correct ACLs, Samba authentication still required

---

## Maintenance Commands

```bash
# Check all dataset ACLs
for ds in main-nas photo device-cam media nvr; do
    echo "=== $ds ==="
    getfacl /hdd_pool/$ds
done

# Verify Samba users
pdbedit -L

# Check NFS exports
exportfs -v

# Monitor dataset usage
zfs list -o name,used,avail,refer,mountpoint hdd_pool

# Check LXC mounts
pct config 100 | grep mp
```

---

**Originally Created:** 2025-11-09
**Blog Publication:** 2025-12-02
**Tested On:** Proxmox VE 8.x, TrueNAS SCALE datasets, Ubuntu 24.04 LXC containers
