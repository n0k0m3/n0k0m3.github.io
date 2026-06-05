---
excerpt_separator: "<!--more-->"
categories:
  - Gaming
tags:
  - PS Vita
  - Game Preservation
  - NoPayStation
  - Tutorial
title: "NoPayStation: PS Vita Game Preservation on Linux"
date: 2023-08-25
---

A guide to using NoPayStation for PS Vita game preservation and backup, enabling legal owners to archive their digital purchases.

<!--more-->

> **Legal Notice:** This guide is for game preservation and backing up games you legally own. NoPayStation provides access to Sony's CDN for downloading legally purchased content. Always respect copyright laws in your jurisdiction.

## What is NoPayStation?

NoPayStation is a community database that catalogs download links for PS Vita, PSP, and PSX games from Sony's own content delivery network (CDN). It's primarily used for:

- **Digital preservation:** Archiving games before Sony's servers shut down
- **Backup purposes:** Re-downloading legally owned content
- **Game preservation community:** Maintaining access to digital-only releases

---

## Prerequisites

- Windows, Linux, or macOS
- Internet connection
- PS Vita with custom firmware (for installing downloaded content)
- See my [PS Vita Hacking Guide](../../ps-vita-hacking/) for CFW setup

---

## Step 1: Download Required Tools

### pkg2zip

Download from [GitHub Releases](https://github.com/mmozeiko/pkg2zip/releases/latest)

**Purpose:** Decrypts and extracts PKG files from Sony's CDN

**Platform support:**
- Windows: `pkg2zip.exe`
- Linux: `pkg2zip-linux`
- macOS: `pkg2zip-mac`

Place the executable anywhere convenient (you'll reference it later).

### NPS Browser

Download from [GitHub Releases](https://github.com/jhonhenry10/NPS_Browser/releases/latest)

**Purpose:** GUI browser for the NoPayStation database

**Platform support:**
- Windows: NPS_Browser.exe
- Linux/macOS: Run via Mono or Wine

---

## Step 2: Configure NPS Browser

### Initial Setup

1. **Run NPS_Browser**
2. **Configure database sources** with the following URLs:

**Game links (TSV URL):**
```
https://docs.google.com/spreadsheets/u/0/d/18PTwQP7mlwZH1smpycHsxbEwpJnT8IwFP7YZWQT7ZSs/export?format=tsv&id=18PTwQP7mlwZH1smpycHsxbEwpJnT8IwFP7YZWQT7ZSs&gid=1180017671
```

**DLC links (TSV URL):**
```
https://docs.google.com/spreadsheets/u/0/d/18PTwQP7mlwZH1smpycHsxbEwpJnT8IwFP7YZWQT7ZSs/export?format=tsv&id=18PTwQP7mlwZH1smpycHsxbEwpJnT8IwFP7YZWQT7ZSs&gid=743196745
```

**PSM links (PlayStation Mobile) (TSV URL):**
```
https://docs.google.com/spreadsheets/d/18PTwQP7mlwZH1smpycHsxbEwpJnT8IwFP7YZWQT7ZSs/export?format=tsv&id=18PTwQP7mlwZH1smpycHsxbEwpJnT8IwFP7YZWQT7ZSs&gid=1652602430
```

**PSX links (PS1 classics) (TSV URL):**
```
https://docs.google.com/spreadsheets/u/0/d/18PTwQP7mlwZH1smpycHsxbEwpJnT8IwFP7YZWQT7ZSs/export?format=tsv&id=18PTwQP7mlwZH1smpycHsxbEwpJnT8IwFP7YZWQT7ZSs&gid=859874385
```

3. **Set download directory:** Choose where you want to save extracted games

4. **Configure pkg decryption tool:**
   - **Path:** Browse and select the `pkg2zip` executable you downloaded
   - **Parameters:** `-x {pkgFile} {zRifKey}`

5. **Close NPS_Browser** and **restart** it to load the database

---

## Step 3: Browse and Download Games

After restarting, you should see the game database:

**Tabs available:**
- **PS Vita Games:** Full game downloads
- **PS Vita DLC:** Downloadable content
- **PSM:** PlayStation Mobile games
- **PSX:** PS1 classics for Vita/PSP

**To download:**
1. Browse or search for the game you want
2. Right-click → Download
3. NPS Browser will:
   - Download the PKG file from Sony's CDN
   - Automatically decrypt it using pkg2zip
   - Extract to your configured directory

---

## Step 4: Install on PS Vita

### For Vita Games & DLCs

1. **Connect PS Vita via USB** (using VitaShell or molecular shell)
2. **Copy the extracted folders** to Vita's root:
   - `app/` folder → `ux0:/app/`
   - `addcont/` folder (DLC) → `ux0:/addcont/`

3. **Refresh LiveArea:**
   - Open VitaShell
   - Press **Triangle** to open menu
   - Select **Refresh LiveArea**
   - Wait for completion

4. **Games should appear on home screen**

### For PSX Games (PS1 Classics)

1. **Copy the `/pspemu/` directory** to Vita's root: `ux0:/pspemu/`
2. **Run via Adrenaline** (PSP emulator for Vita)
3. **Games appear in Adrenaline's XMB menu**

---

## Troubleshooting

### Issue: NPS Browser shows empty database

**Cause:** Network error or outdated URLs

**Fix:**
1. Check internet connection
2. Verify TSV URLs are correct (they may update occasionally)
3. Check [NoPayStation website](https://nopaystation.com/) for latest links

### Issue: pkg2zip fails to decrypt

**Error:** `Error: Invalid pkg file` or similar

**Possible causes:**
1. Corrupted download - retry download
2. Wrong pkg2zip version - download latest release
3. Incorrect parameters - verify: `-x {pkgFile} {zRifKey}`

**Fix:**
```bash
# Manual decryption (Linux/macOS)
./pkg2zip -x game.pkg zRIF_KEY_HERE

# Windows
pkg2zip.exe -x game.pkg zRIF_KEY_HERE
```

### Issue: Game doesn't appear after installation

**Possible causes:**
1. Files copied to wrong location
2. LiveArea not refreshed
3. Incorrect folder structure

**Fix:**
1. Verify folder structure:
   ```
   ux0:/app/GAME_ID/
   ux0:/addcont/GAME_ID/ (for DLC)
   ```
2. Re-run **Refresh LiveArea** in VitaShell
3. Reboot Vita

### Issue: "License expired" error

**Cause:** Missing or invalid license file

**Fix:** Use **NoNpDrm** plugin (should be installed with CFW)
- The `.rif` file is generated during pkg2zip extraction
- Ensure `nonpdrm` plugin is active in `tai/config.txt`

---

## Alternative: Command-Line Usage (Advanced)

For Linux/macOS users who prefer command-line:

```bash
# Download PKG manually (from NPS database)
wget -O game.pkg "PKG_URL_FROM_NPS"

# Decrypt with pkg2zip
./pkg2zip -x game.pkg zRIF_KEY

# Copy to Vita
rsync -av app/ /path/to/vita/ux0/app/
```

**Get PKG URLs:** Export TSV from Google Sheets and parse with scripts

---

## Data Management Tips

### Organizing Downloads

Create folder structure:
```
PSVita_Backups/
├── Games/
├── DLC/
├── PSM/
└── PSX/
```

### Verify Game Integrity

Use hash verification if available:
```bash
# SHA256 checksums (if provided by NPS)
sha256sum game_folder/*
```

### Backup Strategy

- **Keep PKG files:** For re-extraction if needed
- **Archive extracted folders:** Ready-to-install format
- **Document zRIF keys:** Store separately for future decryption

---

## Contributing to NoPayStation

The NoPayStation database is community-maintained. If you have legitimate purchases that aren't in the database:

1. Visit [NoPayStation website](https://nopaystation.com/)
2. Follow contribution guidelines
3. Submit missing content details (with proof of purchase)

**Note:** Only submit content you legally own.

---

## Legal and Ethical Considerations

**Legal uses:**
- Backing up your own purchased games
- Preserving digital-only releases
- Archiving content from discontinued services

**Important:**
- NoPayStation does **not** host any game files
- All downloads come from Sony's official CDN
- You should own the games you download
- Respect copyright laws in your jurisdiction

**Historical context:** With Sony's announcement of PS Vita/PSP/PS3 store closures (later reversed, then partially closed), game preservation efforts have become crucial for maintaining access to digital content.

---

## Related Guides

- [PS Vita Hacking Guide on Linux](../../ps-vita-hacking/) - Custom firmware setup
- [Vita PKG Tools](https://github.com/mmozeiko/pkg2zip) - Manual PKG decryption

---

## References

- [NoPayStation Official Site](https://nopaystation.com/)
- [pkg2zip GitHub](https://github.com/mmozeiko/pkg2zip)
- [NPS Browser GitHub](https://github.com/jhonhenry10/NPS_Browser)
- [Vita Hacks Guide](https://vita.hacks.guide/)

---

**Created:** 2025-12-02
**Platforms:** Windows, Linux, macOS
**Game Platforms:** PS Vita, PSP, PS1 (via Vita)
