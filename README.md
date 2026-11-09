# ScreenUp

[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)
![Platform: Linux](https://img.shields.io/badge/platform-Linux-blue)
![Language: Python](https://img.shields.io/badge/language-Python-3776AB)

ScreenUp is a Linux app: paste a URL and it opens in a popup that stays on top of all other apps. I felt Linux was missing this.

## Install

You need **Linux** and **Node.js** (only to run the installer). The script takes care of the rest.

```bash
git clone https://github.com/brayanspagnol/screenup.git
cd screenup
npm run install
```

The first time, the installer may ask for your password (`sudo`) to download `mpv`, `yt-dlp` and anything else missing from your system. After that, **ScreenUp** shows up in your applications menu.

> It's not on npm as a global package yet (`npm install screenup` from outside the repo). For now, clone the repository and run `npm run install` inside the folder.

## Usage

1. Open **ScreenUp** from the menu.
2. Paste the YouTube URL and the video opens by itself.
3. The small window stays on top while you use other programs.

**Video controls** (hover with the mouse):

- Left: back 10s
- Center: pause / play
- Right: forward 10s

## Troubleshooting

```bash
npm run doctor
```

It shows what's missing. If you'd rather install the system dependencies by hand:

| Distro | Command |
|--------|---------|
| Fedora | `sudo dnf install python3-gobject gtk4 mpv yt-dlp` |
| Ubuntu / Debian | `sudo apt install python3-gi gir1.2-gtk-4.0 mpv yt-dlp` |
| Arch | `sudo pacman -S python-gobject gtk4 mpv yt-dlp` |

## License

MIT
