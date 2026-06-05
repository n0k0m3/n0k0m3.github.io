---
excerpt_separator: "<!--more-->"
categories:
  - Networking
tags:
  - Cloudflare
  - SSH
  - Tunnel
  - Remote Access
  - Linux
title: "Secure SSH Access with Cloudflare Tunnel"
date: 2024-08-17
showtoc: true
---

Access your servers securely through Cloudflare's Zero Trust network without exposing SSH ports or setting up VPNs.

<!--more-->

## Overview

Cloudflare Tunnel (formerly Argo Tunnel) provides secure remote access to your servers without opening firewall ports or exposing SSH to the internet. It creates an encrypted tunnel between your server and Cloudflare's network, accessible only via Cloudflare Access authentication.

**Benefits:**
- No port forwarding required
- No public IP needed
- Built-in DDoS protection
- Cloudflare Access authentication
- Short-lived certificates for enhanced security

---

## Prerequisites

- Cloudflare account (free tier works)
- Domain configured on Cloudflare
- Server with Cloudflare Access configured for SSH
- Linux or macOS client (Windows with WSL2 also works)

---

## Quick Start: One-Liner Setup

For Linux clients, use this automated setup script:

```bash
bash <(curl -sfL https://gist.githubusercontent.com/n0k0m3/89ffc6a463a007d79fc4b234c58bf77a/raw/280291bb2edb2f271914838e07cc9af81c3567b8/setup-cf-tunnel.sh)
```

**Prompts:**
1. Enter the domain name/host name of the tunnel: `server.example.com`
2. Enter the username for the server: `your_username`

**Example output:**
```sh
Enter the domain name/host name of the tunnel: subdomain.example.com
Enter the username for the server: your_username

Installing cloudflared, input sudo password when asked...
Generating ssh config for the tunnel...

Setting up done, use "ssh your_username@subdomain.example.com" to login
```

---

## Manual Setup: Linux

### Step 1: Install `cloudflared`

```bash
curl -sfL https://gist.githubusercontent.com/n0k0m3/49b26f4359a70d2f36e5a263b3dd5f24/raw/037e5f38fd027012bb0aa5f12d1d6fb2bdd59ca8/install-cloudflared.sh | sh
```

**Or manual install:**
```bash
# Debian/Ubuntu
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb

# Arch Linux
yay -S cloudflared

# Other distributions (manual)
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
chmod +x cloudflared-linux-amd64
sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
```

### Step 2: Generate SSH Config

Replace `<hostname>` with your server's domain:

```bash
cloudflared access ssh-config --hostname <hostname> --short-lived-cert
```

**Example command:**
```bash
cloudflared access ssh-config --hostname server.example.com --short-lived-cert
```

**Sample output:**
```sh
Host server.example.com
  ProxyCommand bash -c '/usr/bin/cloudflared access ssh-gen --hostname %h; ssh -tt %r@cfpipe-server.example.com >&2 <&1'

Host cfpipe-server.example.com
  HostName server.example.com
  ProxyCommand /usr/bin/cloudflared access ssh --hostname %h
  IdentityFile ~/.cloudflared/server.example.com-cf_key
  CertificateFile ~/.cloudflared/server.example.com-cf_key-cert.pub
```

### Step 3: Add Config to SSH

Copy the generated output to `~/.ssh/config`:

```bash
cloudflared access ssh-config --hostname server.example.com --short-lived-cert >> ~/.ssh/config
```

Or manually edit:
```bash
nano ~/.ssh/config
# Paste the generated config
```

### Step 4: Connect

```bash
ssh your_username@server.example.com
```

**What happens:**
1. `cloudflared` requests a short-lived certificate from Cloudflare Access
2. Your browser opens for authentication (first time only)
3. After auth, a temporary SSH certificate is generated
4. SSH connection is established through the Cloudflare tunnel

---

## Manual Setup: Windows

> **Recommendation:** Use WSL2 and follow the Linux instructions above for the best experience.

If you must use native Windows:

### Step 1: Download `cloudflared`

Download from [GitHub Releases](https://github.com/cloudflare/cloudflared/releases/latest/):
- [cloudflared-windows-amd64.exe](https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe)

Place in a permanent location (e.g., `C:\Program Files\cloudflared\`)

### Step 2: Configure SSH

Add to `C:\Users\<username>\.ssh\config`:

```ssh-config
Host cfpipe-<hostname>
  HostName <hostname>
  ProxyCommand C:\path\to\cloudflared.exe access ssh --hostname <hostname>
  IdentityFile "C:\Users\<username>\.cloudflared\<hostname>-cf_key"
  CertificateFile "C:\Users\<username>\.cloudflared\<hostname>-cf_key-cert.pub"
```

**Replace:**
- `<hostname>` with your server domain (e.g., `server.example.com`)
- `C:\path\to\cloudflared.exe` with actual path to cloudflared

### Step 3: Connect

```powershell
cmd /c "C:\path\to\cloudflared.exe access ssh-gen --hostname <hostname> && ssh -tt <username>@cfpipe-<hostname>"
```

---

## Bonus: Setting Static IP on Server

If your server needs a static IP instead of DHCP, configure with `netplan`.

### Find Current Network Info

```bash
# Find current IP and interface
ip a

# Find gateway
ip r
```

### Configure Static IP

Edit netplan configuration:

```bash
sudo nano /etc/netplan/00-installer-config.yaml
```

**Example configuration:**
```yaml
network:
  ethernets:
    eth0:  # Replace with your interface name
      dhcp4: no
      addresses:
        - 192.168.1.100/24  # Replace with desired static IP
      routes:
        - to: default
          via: 192.168.1.1  # Replace with your gateway
      nameservers:
          addresses: [1.1.1.1, 1.0.0.1]  # Cloudflare DNS
  version: 2
```

**Apply changes:**
```bash
sudo netplan apply
```

**Revert to DHCP:**
```yaml
network:
  ethernets:
    eth0:
      dhcp4: true
  version: 2
```

---

## Troubleshooting

### Issue: Browser doesn't open for authentication

**Cause:** Headless server or SSH session without display

**Fix:** Copy the authentication URL and open it in a browser on your local machine:
```
Please complete authentication in your browser at:
https://example.cloudflareaccess.com/cdn-cgi/access/login/...
```

### Issue: Certificate expired

**Symptoms:** SSH fails with "permission denied" after previously working

**Cause:** Short-lived certificates expire (typically after 24 hours)

**Fix:** Reconnect - `cloudflared` will automatically request a new certificate:
```bash
ssh your_username@server.example.com
```

### Issue: `cloudflared` not found

**Cause:** Binary not in PATH

**Fix for Linux:**
```bash
# Check if installed
which cloudflared

# If not in PATH, add to ~/.bashrc or ~/.zshrc
export PATH="$PATH:/usr/local/bin"
source ~/.bashrc
```

**Fix for Windows:** Use full path to `cloudflared.exe` in SSH config

### Issue: Connection timeout

**Possible causes:**
1. Cloudflare Tunnel not configured on server
2. Server `cloudflared` daemon not running
3. Cloudflare Access policy blocking connection

**Check server-side:**
```bash
# On the server
sudo systemctl status cloudflared
sudo journalctl -u cloudflared -f
```

---

## Advanced: Multiple Servers

Add multiple servers to `~/.ssh/config`:

```ssh-config
# Server 1
Host server1.example.com
  ProxyCommand bash -c '/usr/bin/cloudflared access ssh-gen --hostname %h; ssh -tt %r@cfpipe-server1.example.com >&2 <&1'

Host cfpipe-server1.example.com
  HostName server1.example.com
  ProxyCommand /usr/bin/cloudflared access ssh --hostname %h
  IdentityFile ~/.cloudflared/server1.example.com-cf_key
  CertificateFile ~/.cloudflared/server1.example.com-cf_key-cert.pub

# Server 2
Host server2.example.com
  ProxyCommand bash -c '/usr/bin/cloudflared access ssh-gen --hostname %h; ssh -tt %r@cfpipe-server2.example.com >&2 <&1'

Host cfpipe-server2.example.com
  HostName server2.example.com
  ProxyCommand /usr/bin/cloudflared access ssh --hostname %h
  IdentityFile ~/.cloudflared/server2.example.com-cf_key
  CertificateFile ~/.cloudflared/server2.example.com-cf_key-cert.pub
```

**Connect to any server:**
```bash
ssh user@server1.example.com
ssh user@server2.example.com
```

---

## Security Benefits

1. **No exposed SSH ports** - Server SSH port doesn't need to be publicly accessible
2. **Authentication via Cloudflare Access** - Add Google Workspace, GitHub, or other SSO providers
3. **Short-lived certificates** - Certificates expire automatically, limiting exposure window
4. **Audit logging** - Cloudflare Access logs all authentication attempts
5. **DDoS protection** - Cloudflare's network protects against DDoS attacks

---

## References

- [Cloudflare Zero Trust Documentation](https://developers.cloudflare.com/cloudflare-one/)
- [cloudflared GitHub Repository](https://github.com/cloudflare/cloudflared)
- [Cloudflare Access SSH Guide](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/use_cases/ssh/)

---

**Created:** 2025-12-02
**Tested On:** Ubuntu 22.04+, Arch Linux, macOS, Windows 11 (WSL2)
