---
excerpt_separator: "<!--more-->"
categories:
  - Homelab
tags:
  - TrueNAS
  - Proxmox
  - Docker
  - Networking
  - VLAN
  - Migration
title: "Migrating from Proxmox-hosted NAS to TrueNAS with Docker Apps"
date: 2025-10-22
showtoc: true
---

A practical migration guide from a Proxmox-hosted Synology NAS to TrueNAS SCALE with Docker Compose applications, including network topology planning and macvlan configuration.

<!--more-->

> **⚠️ WARNING:** This document contains configuration examples with placeholder values. Replace all passwords, API keys, IP addresses, and MAC addresses with your own values before use.

## Current Setup

Starting point: Proxmox hosting multiple VMs and LXCs, including a virtualized NAS.

Target: TrueNAS SCALE hosting all storage datasets AND running containerized applications via Docker Compose.

---

## Migration Inventory

### VMs/LXC Containers to Migrate

**Network Controller LXC:**
- IP: 172.25.251.2, VLAN 251
- MAC: XX:XX:XX:XX:XX:01
- Service: Omada Controller
- Backup: Configuration export

**NVR (Network Video Recorder) LXC:**
- IP: 172.25.100.10, VLAN 100
- Bridged backend IP: 192.168.1.10 (for NFS)
- MAC: XX:XX:XX:XX:XX:02, XX:XX:XX:XX:XX:03
- Services: Scrypted, Frigate
- Migration: Will use Docker Compose on TrueNAS

**DMZ VM:**
- IP: 172.16.1.2, VLAN 2048
- Bridged IP: 192.168.1.11 (for NFS)
- Backup: Full VM backup
- NFS mounts: media, main-nas

**Home Automation VM:**
- IP: 172.25.50.2, VLAN 50
- Backup: Full VM backup

**NAS VM (to be replaced):**
- IP: 172.25.10.10, VLAN 10
- Bridged IP: 192.168.1.3
- Action: Migrate data to TrueNAS datasets

---

## TrueNAS Configuration Plan

### Network Setup

**Link Aggregation (LAGG):**
- Setup: [Bond/LAGG configuration](https://www.truenas.com/docs/scale/25.04/scaletutorials/network/interfaces/settinguplagg/)
- Benefits: Increased bandwidth and redundancy

**VLAN Configuration:**
- Primary interface: Stay on VLAN 10 for storage network
- Setup guide: [Setting up VLANs](https://www.truenas.com/docs/scale/25.04/scaletutorials/network/interfaces/settingupvlan/)

**Internal Bridge:**
- Purpose: Container networking for NVR applications
- Setup guide: [Setting up Bridge](https://www.truenas.com/docs/scale/25.04/scaletutorials/network/interfaces/settingupbridge/)

### Dataset Migration

Datasets to create on TrueNAS (matching current NAS structure):
- `main-nas` - General file storage
- `photo` - Photo sync (Syncthing)
- `device-cam` - Dashcam/device uploads
- `media` - Media library (Plex/Jellyfin)
- `nvr` - NVR recordings (Frigate/Scrypted)

---

## Docker Compose with macvlan Networking

### macvlan Template

macvlan allows containers to have their own IP addresses on VLANs, appearing as physical devices on your network.

**Basic macvlan template:**
```yaml
services:
  service_name:
    networks:
      iot_macvlan:
        ipv4_address: 192.168.20.202

networks:
  iot_macvlan:
    driver: macvlan
    driver_opts:
      parent: eth0.20  # VLAN 20 interface
    ipam:
      config:
       - subnet: 192.168.20.0/24
         ip_range: 192.168.20.248/29  # Optional: reserve range for containers
         gateway: 192.168.20.1
        aux_addresses:  # Reserve these IPs (don't assign to containers)
            host1: 192.168.20.5
            host2: 192.168.20.6
            host3: 192.168.20.7
```

### Multi-VLAN Example

For environments with multiple VLANs (e.g., camera network, IoT network):

```yaml
# Define the macvlan networks
networks:
  cam_net:
    driver: macvlan
    driver_opts:
      # Parent interface - Docker will auto-create bond0.100 sub-interface
      parent: bond0.100
    ipam:
      config:
        - subnet: 172.25.100.0/24       # Camera network subnet
          gateway: 172.25.100.1         # Gateway
          ip_range: 172.25.100.48/28    # Optional: small range for Docker

  iot_net:
    driver: macvlan
    driver_opts:
      # Parent interface for IoT VLAN
      parent: bond0.50
    ipam:
      config:
        - subnet: 172.25.50.0/24        # IoT network subnet
          gateway: 172.25.50.1          # Gateway
          ip_range: 172.25.50.8/29      # Optional: small range for Docker
```

---

## Migrated Application Configurations

### Omada Controller (Network Management)

Omada runs on the management VLAN with a static IP.

**Create external network first:**
```yaml
# Create the network separately if needed, or define in first compose file
networks:
  mgmt_net:
    external: true
```

**Omada Controller docker-compose.yml:**
```yaml
networks:
  mgmt_net:
    external: true

services:
  omada-controller:
    container_name: omada-controller
    environment:
      - PUID=568
      - PGID=568
      - TZ=America/New_York
    image: mbentley/omada-controller:6
    networks:
      mgmt_net:
        ipv4_address: 172.25.251.2
    restart: unless-stopped
    stop_grace_period: 60s
    ulimits:
      nofile:
        hard: 8192
        soft: 4096
    volumes:
      - /mnt/ssd_pool/docker/omada/data:/opt/tplink/EAPController/data
      - /mnt/ssd_pool/docker/omada/logs:/opt/tplink/EAPController/logs
```

**Storage notes:**
- Uses SSD pool for performance (frequent DB writes)
- Persist data and logs directories

---

### NVR Stack (Scrypted + Frigate + Watchtower)

This configuration runs Scrypted (for HomeKit/camera management) and Frigate (NVR) together, sharing a network namespace. Watchtower provides automatic updates.

**Create external VLAN 100 network:**
```yaml
networks:
  vlan100:
    external: true
```

**NVR docker-compose.yml:**
```yaml
networks:
  vlan100:
    external: true

services:
  scrypted:
    container_name: scrypted
    devices:
      - /dev/dri:/dev/dri    # Intel/AMD GPU for hardware acceleration
      - /dev/kfd:/dev/kfd    # AMD GPU (ROCm)
    environment:
      # Watchtower webhook integration
      - >-
        SCRYPTED_WEBHOOK_UPDATE_AUTHORIZATION=Bearer
        ${WATCHTOWER_HTTP_API_TOKEN:-your_watchtower_token}
      - SCRYPTED_WEBHOOK_UPDATE=http://localhost:10444/v1/update
    healthcheck:
      interval: 30s
      retries: 5
      start_period: 15s
      test:
        - CMD
        - curl
        - '-f'
        - '-k'
        - '-L'
        - http://127.0.0.1:11080/endpoint/@scrypted/core/public/#/
      timeout: 5s
    image: ghcr.io/koush/scrypted
    labels:
      - com.centurylinklabs.watchtower.scope=scrypted
    networks:
      vlan100:
        ipv4_address: 172.25.100.10
    restart: unless-stopped
    security_opt:
      - apparmor:unconfined
    volumes:
      - /var/run/dbus:/var/run/dbus
      - /var/run/avahi-daemon/socket:/var/run/avahi-daemon/socket
      - /mnt/ssd_pool/docker/scrypted/volume:/server/volume

  frigate:
    container_name: frigate
    depends_on:
      - scrypted
    devices:
      - /dev/dri        # GPU for hardware acceleration
      - /dev/kfd        # AMD GPU (ROCm)
    environment:
      FRIGATE_RTSP_PASSWORD: <your_secure_password>
      HSA_OVERRIDE_GFX_VERSION: 11.0.0      # For AMD GPU compatibility
      LIBVA_DRIVER_NAME: radeonsi           # AMD GPU driver
      PLUS_API_KEY: <your_frigate_plus_api_key>
    image: ghcr.io/blakeblackshear/frigate:stable-rocm
    labels:
      - com.centurylinklabs.watchtower.scope=scrypted
    network_mode: service:scrypted    # Share network namespace with Scrypted
    privileged: true
    restart: unless-stopped
    shm_size: 512mb    # Shared memory for object detection
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /mnt/ssd_pool/docker/frigate/config:/config
      - /mnt/hdd_pool/surveillance/frigate:/media/frigate
      - target: /tmp/cache
        tmpfs:
          size: 1000000000    # 1GB tmpfs for detection cache
        type: tmpfs

  watchtower:
    command: '--interval 3600 --cleanup --scope scrypted'
    container_name: nvr-watchtower
    environment:
      - WATCHTOWER_SCOPE=scrypted
      - WATCHTOWER_HTTP_API_TOKEN=${WATCHTOWER_HTTP_API_TOKEN}
    image: containrrr/watchtower
    labels:
      - com.centurylinklabs.watchtower.scope=scrypted
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```

**Key features:**
- **Shared network namespace:** Frigate uses `network_mode: service:scrypted` to share Scrypted's network stack
- **GPU acceleration:** Hardware decode/encode for video streams (adjust for Intel or NVIDIA GPUs)
- **Watchtower auto-updates:** Checks hourly for new images
- **Storage separation:** Config on SSD, recordings on HDD array

**GPU Support Notes:**
- AMD (ROCm): Shown above with `HSA_OVERRIDE_GFX_VERSION` and `radeonsi` driver
- Intel (VAAPI): Use `LIBVA_DRIVER_NAME=i965` or `iHD`
- NVIDIA: Use `frigate:stable` image and add `runtime: nvidia` + `NVIDIA_VISIBLE_DEVICES=all`

---

## SMB User Accounts

Accounts to create in TrueNAS for Samba sharing:

- `isouser` - For ISO files and Linux installation media
- `mainuser` - Primary user account
- `deviceuser` - For device uploads (dashcam, etc.)
- `backupuser` - For Time Machine or backup operations

---

## Migration Steps Summary

### Phase 1: Preparation
1. ✅ Inventory all VMs/LXCs and their network configurations
2. ✅ Backup all VM disks and LXC configurations
3. ✅ Document all Docker Compose configurations
4. ✅ Export Omada Controller configuration

### Phase 2: TrueNAS Setup
1. Install TrueNAS SCALE
2. Configure bond/LAGG for network interfaces
3. Setup VLANs (10, 50, 100, 251, 2048)
4. Create internal bridge for container networking
5. Create ZFS datasets matching current structure

### Phase 3: Data Migration
1. Copy NAS data to TrueNAS datasets (rsync or ZFS send/receive)
2. Verify data integrity
3. Setup SMB shares with user accounts
4. Test client connectivity

### Phase 4: Docker Migration
1. Create macvlan networks for each VLAN
2. Deploy Omada Controller with persistent storage
3. Deploy NVR stack (Scrypted + Frigate)
4. Verify container connectivity and functionality
5. Restore Omada Controller configuration

### Phase 5: VM Migration
1. Migrate Home Automation VM (convert or rebuild)
2. Migrate DMZ VM
3. Update NFS mount points to new TrueNAS IP
4. Test all services

### Phase 6: Validation & Cleanup
1. Verify all services are operational
2. Test backups and snapshots
3. Decommission old Proxmox NAS VM
4. Update documentation

---

## Networking Best Practices

### VLAN Segmentation Rationale

- **VLAN 10 (Storage):** NAS access, trusted devices
- **VLAN 50 (IoT):** Smart home devices, isolated from main network
- **VLAN 100 (Cameras):** IP cameras, NVR, isolated for security
- **VLAN 251 (Management):** Network infrastructure (Omada, switches)
- **VLAN 2048 (DMZ):** Internet-facing services

### macvlan Limitations

**Important:** The TrueNAS host cannot directly communicate with macvlan containers using their IP addresses. This is a Docker limitation.

**Workarounds:**
1. Use container names for inter-container communication
2. Create a separate bridge network for host-to-container communication
3. Use host ports published with `-p` for services that need host access

---

## Troubleshooting

### Issue: Container can't reach network

**Check:**
1. Verify VLAN interface exists on host: `ip link show bond0.100`
2. Check macvlan network created: `docker network ls`
3. Verify IP address not in use: `ping <container_ip>`

**Fix:**
```bash
# Recreate macvlan network
docker network rm vlan100
docker network create -d macvlan \
  --subnet=172.25.100.0/24 \
  --gateway=172.25.100.1 \
  --ip-range=172.25.100.48/28 \
  -o parent=bond0.100 vlan100
```

### Issue: AMD GPU not detected in Frigate

**Check:**
```bash
# Verify render group permissions
ls -la /dev/dri
# Should show: crw-rw---- 1 root render /dev/dri/renderD128
```

**Fix:**
```bash
# Add TrueNAS user to render group (if running as non-root)
usermod -aG render <your_user>
```

### Issue: Frigate recordings filling up disk

**Solution:**
- Configure retention policies in Frigate config
- Monitor dataset usage: `zfs list -o name,used,avail`
- Set ZFS quotas: `zfs set quota=500G hdd_pool/nvr`

---

## Future Enhancements

- [ ] Implement ZFS snapshots for datasets
- [ ] Setup automated backups to off-site location
- [ ] Configure Prometheus + Grafana for monitoring
- [ ] Add Traefik reverse proxy for HTTPS access
- [ ] Implement Authentik for SSO across services

---

**Migration Planned:** 2025-11
**Blog Publication:** 2025-12-02
**Target Platform:** TrueNAS SCALE 25.04+, Docker Compose v2+
