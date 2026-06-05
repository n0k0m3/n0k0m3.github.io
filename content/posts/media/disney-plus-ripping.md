---
excerpt_separator: "<!--more-->"
categories:
  - Media
tags:
  - Web-DL
  - Streaming
  - Tutorial
  - FFmpeg
title: "WEB-DL from Disney Plus (Educational Guide)"
date: 2023-10-12
showtoc: true
---

An educational guide on downloading WEB-DL quality streams from Disney Plus using L3 Widevine decryption. For personal backup and archival purposes only.

<!--more-->

> **⚠️ IMPORTANT LEGAL DISCLAIMER:**
>
> This guide is provided for **educational purposes only** and covers techniques for backing up content you have legally purchased or subscribed to.
>
> **Legal considerations:**
> - Circumventing DRM may violate the DMCA (US) and similar laws in other jurisdictions
> - This is intended for **personal use** and **fair use** purposes only
> - Distributing copyrighted content is illegal
> - Always review your local laws regarding DRM circumvention
> - This guide is for **archival/backup of content you legally access**
>
> The author assumes no responsibility for misuse of this information. Always respect copyright laws and terms of service.

---

## Overview

This tutorial covers **WEB-DL** (Web Download) from Disney Plus, which captures the stream as it's delivered, not screen recording (RIP). WEB-DL provides:

- Original quality (up to 1080p with L3, 4K video requires L1)
- Lossless audio (including Dolby Atmos if you bypass the 1080p limit)
- Subtitle tracks
- No re-encoding

**Important terminology:**
- **L3 Widevine:** Software-based DRM (allows up to 1080p decryption)
- **L1 Widevine:** Hardware-based DRM (required for 4K, cannot be decrypted with this method)

---

## Requirements

### Software

| Tool | Purpose | Download Link |
|------|---------|--------------|
| **Chrome v87 or earlier** | Older Chrome versions with L3 extraction support | [Old Chrome Versions](https://www.slimjet.com/chrome/google-chrome-old-version.php) |
| **Stream Detector** | Detects M3U8 playlist URLs | [GitHub](https://github.com/rowrawer/stream-detector) |
| **Widevine L3 Decryptor** | Extracts decryption keys from Chrome | [GitHub](https://github.com/cryptonek/widevine-l3-decryptor) |
| **N_m3u8DL-CLI v2.9.7** | Downloads M3U8 streams | [GitHub](https://github.com/nilaoda/N_m3u8DL-CLI/releases) |
| **FFmpeg** | Media processing | [ffmpeg.org](https://ffmpeg.org/download.html) |
| **mp4decrypt** | Decrypts video/audio with keys | Part of Bento4 tools |
| **mkvmerge** | Merges video, audio, subtitles | Part of MKVToolNix |
| **disney.bat** | Automation script | [Download link](https://cdn.discordapp.com/attachments/717353037693321250/843113610855317554/disney.bat) |

### Disney Plus Account

You need an active Disney Plus subscription to access content.

---

## Step 1: Setup Extensions

### Install Browser Extensions (Developer Mode)

1. **Download extensions as ZIP files:**
   - [Stream Detector](https://github.com/rowrawer/stream-detector)
   - [Widevine L3 Decryptor](https://github.com/cryptonek/widevine-l3-decryptor)

2. **Extract both ZIP files** to separate folders

3. **Enable Chrome Developer Mode:**
   - Navigate to `chrome://extensions/`
   - Enable **Developer mode** (toggle in top-right)

4. **Load extensions:**
   - Click **Load unpacked**
   - Select the extracted Stream Detector folder
   - Repeat for Widevine L3 Decryptor folder

5. **Verify installation:**

   Should look like this:

   ![Extensions loaded](https://i.imgur.com/QHBoJoI.png)

---

## Step 2: Setup Tools

### Organize Tools Folder

Create a working directory (e.g., `C:\Disney-DL\`) and place:

- `N_m3u8DL-CLI_v2.9.7.exe`
- `ffmpeg.exe`
- `mp4decrypt.exe`
- `mkvmerge.exe` (extract from MKVToolNix installation directory)
- `disney.bat`

**All tools must be in the same folder.**

---

## Step 3: Capture Stream URL

### Play Content and Extract Playlist

1. **Open Chrome and navigate to Disney Plus**

2. **Open Developer Tools** before playing:
   - Press `Ctrl + Shift + I` or right-click → Inspect

3. **Keep Developer Tools open** and start playing the movie/show

4. **Click Stream Detector extension** (top-right corner):

   ![Stream Detector](https://i.imgur.com/w9rGe6Z.png)

5. **Copy the URL starting with `ctr-all`**

   Example:
   ```
   https://disney.cdn.example.com/.../ctr-all.m3u8?params=...
   ```

---

## Step 4: Download Stream

### Run the Batch Script

1. **Run `disney.bat`**

2. **Enter file name** (without extension):
   ```
   Enter filename: Movie_Title_2024
   ```

3. **Paste the M3U8 URL** you copied:

   ![Batch script](https://i.imgur.com/tN3jJuZ.png)

### Optional: Higher Quality Audio

To get Dolby Atmos audio (at the cost of 4K video encryption):

**Remove everything after `.m3u8`** in the URL:

Before:
```
https://.../ctr-all.m3u8?Policy=...&Signature=...
```

After:
```
https://.../ctr-all.m3u8
```

**Note:** This gives you highest quality audio (Atmos), but 4K video will be L1-encrypted (cannot decrypt). 1080p video remains accessible.

![URL modification](https://i.imgur.com/xFptk5Y.png)

---

## Step 5: Select Audio and Subtitles

The script will show available tracks:

**Audio tracks:**
```
1. English (Dolby Atmos)
2. Spanish
3. French
...
```

**Select your preferred language**

**Subtitle tracks:**
```
1. English (SDH)
2. Spanish
3. None
...
```

**Select subtitles** (or choose "None")

**Download begins automatically:**

![Downloading](https://i.imgur.com/mIZUo9q.png)

---

## Step 6: Extract Decryption Keys

### Get Keys from Console

1. **Go back to Chrome Developer Tools**

2. **Switch to Console tab:**

   ![Console tab](https://i.imgur.com/caAYxiJ.png)

3. **Find the Widevine keys:**
   ```
   WidevineDecryptor: Found key: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6 (KID=0123456789abcdef0123456789abcdef)
   ```

4. **Copy both the key and KID:**
   - First part: `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6` (KEY)
   - Second part: `0123456789abcdef0123456789abcdef` (KID)

5. **Paste into the batch script when prompted:**
   ```
   Enter video decryption key: <paste KEY>
   Enter video KID: <paste KID>
   ```

**The script will decrypt and merge** the video, audio, and subtitles automatically.

---

## Step 7: Retrieve Final File

The finished file will be in:
```
C:\Rips\Rips\
```

**Format:** `.mkv` file with video, audio, and subtitles muxed together

---

## Troubleshooting

### Issue: No decryption keys in console

**Cause:** Content didn't start playing or Widevine decryptor not working

**Fix:**
1. Ensure both extensions are enabled
2. Refresh page and start playback again
3. Check Console tab is showing "WidevineDecryptor" messages

### Issue: Download fails with "403 Forbidden"

**Cause:** Stream URL expired or invalid

**Fix:**
1. Stream URLs expire quickly - recapture URL immediately before downloading
2. Ensure you're logged into Disney Plus
3. Don't modify URL beyond removing query parameters (if doing Atmos trick)

### Issue: Audio/video out of sync

**Cause:** Incorrect FFmpeg parameters or stream timing issues

**Fix:**
1. Use latest FFmpeg version
2. Re-download with fresh URL
3. Check batch script is using correct merge commands

### Issue: Can't find mkvmerge.exe

**Location:** MKVToolNix installs to:
- Windows: `C:\Program Files\MKVToolNix\mkvmerge.exe`
- Copy to your tools folder

---

## Advanced: Manual Process

For those who want more control:

### 1. Download M3U8 Stream

```bash
N_m3u8DL-CLI_v2.9.7.exe -H "User-Agent: ..." "<m3u8-url>" --workDir "output"
```

### 2. Decrypt Video/Audio

```bash
mp4decrypt --key <KID>:<KEY> encrypted_video.mp4 decrypted_video.mp4
mp4decrypt --key <KID>:<KEY> encrypted_audio.mp4 decrypted_audio.mp4
```

### 3. Merge with FFmpeg

```bash
ffmpeg -i decrypted_video.mp4 -i decrypted_audio.mp4 -i subtitles.srt \
  -c copy -c:s mov_text output.mkv
```

---

## Quality Comparison

| Method | Video Quality | Audio Quality | Subtitles | Encryption |
|--------|---------------|---------------|-----------|------------|
| **Standard URL** | Up to 1080p | AAC 5.1 | Yes | L3 (can decrypt) |
| **Modified URL (Atmos)** | 1080p max | Dolby Atmos | Yes | L3 video, L1 4K |
| **L1 (not supported)** | 4K | Atmos | Yes | Hardware (can't decrypt) |

---

## Ethics and Legal Reminder

**This guide is for:**
- Personal backups of content you legally access
- Archiving content you subscribe to
- Educational understanding of DRM systems

**This guide is NOT for:**
- Piracy or illegal distribution
- Circumventing DRM for unauthorized access
- Sharing copyrighted content

Always respect content creators and copyright holders. Support the services you use.

---

## References

- [Stream Detector GitHub](https://github.com/rowrawer/stream-detector)
- [Widevine L3 Decryptor GitHub](https://github.com/cryptonek/widevine-l3-decryptor)
- [N_m3u8DL-CLI GitHub](https://github.com/nilaoda/N_m3u8DL-CLI)
- [FFmpeg Documentation](https://ffmpeg.org/documentation.html)