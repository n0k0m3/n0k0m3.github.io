---
title: Games Reverse Engineering and Data Mining Projects
excerpt: "I do enjoy playing games, but more than that, I enjoy breaking down the code, reverse engineering and data mining games."
weight: 4
---

### Date A Live: Spirit Pledge Game Analysis

- [Assets Decryption Tool](https://github.com/n0k0m3/DALSP-Assets-Decryption-tool):
  - Reverse Engineer mobile game Date A Live: Spirit Pledge using Static analysis tool from NSA ghidra and dynamic analysis tool frida.
  - Re-implement decryption functions using Python, implement methods to convert PowerVR, Ericsson Texture Compression format to digital images format (JPEG/PNG)
- [Assets Mining CD/CI](https://github.com/n0k0m3/DateALiveData): - Data-mined source logics to find insecure API/server that allows easy download/extraction of new game contents. - Datamining repository above developed decryption tool. Using cronjob
  and Github Action to automate fetch, decrypt and datamine new contents.
- Usable mined data examples:
  - Extract Live2D assets compatible with Live2DViewerEX: [Link](https://github.com/n0k0m3/DALSP-Live2D)
  - Dating Route and Favorites: [Link](https://github.com/n0k0m3/DALSP-Dating-Routes-Dump)

### Other games reverse engineering/analysis

- [Azur Lane (Autopatcher)](https://github.com/n0k0m3/Azur-Lane-Scripts-Autopatcher): Reverse engineer Azur Lane game client and edit (patch) the game logic automatically.
- [Arknights Assets Decryption](https://github.com/n0k0m3/Arknights-Lua-Decrypter): Decrypt Arknights game assets by extracting AES encryption key via dynamic analysis (Frida).
<!-- - [D4DJ Assets Decryption](https://github.com/n0k0m3/D4DJ) -->
