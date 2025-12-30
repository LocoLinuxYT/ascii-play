# ascii-play

Play any video as animated ASCII in your terminal. Prefers **mpv + libcaca** for audio+ASCII and falls back to **ffmpeg + chafa** or **ffmpeg + jp2a** for ASCII-only playback.

---

## Requirements

- Best experience: `mpv`, `caca-utils`
- Fallbacks (no audio): `ffmpeg`, `chafa`, `jp2a`

Install on Debian/Ubuntu:

```bash
sudo apt update
sudo apt install -y mpv caca-utils ffmpeg chafa jp2a
```

Arch/Manjaro (pacman):

```bash
sudo pacman -Syu mpv libcaca ffmpeg chafa jp2a
```

Fedora/RHEL/CentOS (dnf):

```bash
sudo dnf install -y mpv libcaca ffmpeg chafa jp2a
```

macOS (Homebrew):

```bash
brew install mpv libcaca ffmpeg chafa jp2a
```

Windows (choose one):
- **WSL (recommended)** — install Ubuntu/Debian from the Store, then use the Debian/Ubuntu commands (`sudo apt install ...`). Run the script inside the WSL shell.
- **MSYS2 (native Windows terminal)** — open the MSYS2 `MINGW64` shell and install:
  ```bash
  pacman -Syu mpv ffmpeg chafa jp2a libcaca
  ```
  Then run `./ascii_play.sh ...` from that same MSYS2 shell. (Git Bash/PowerShell alone won’t work because the script expects a full bash + Unix toolchain.)

Other Linux/BSD: install the same tool names via your package manager; if a package is missing, build it from source or switch to a supported combo.

Run commands are the same on all OSes once dependencies are installed:

```bash
chmod +x ascii_play.sh
./ascii_play.sh [options] "video file"
```

---

## Usage

Make executable once:

```bash
chmod +x ascii_play.sh
```

Run (quote paths with spaces):

```bash
./ascii_play.sh [options] "video file"
```

Options:
- `--mute` / `--no-audio` / `AUDIO=0` — silence mpv audio
- `--audio 0|1` — explicit audio toggle for mpv
- `--width|-w <cols>` — target width (default 160 or env `WIDTH`; auto-clamped to terminal cols)
- `--height|-h <rows>` — target height (env `HEIGHT`; auto-fits to terminal rows when unset)
- `--fps <n>` — frame rate for playback (mpv/ffmpeg; default 15)
- `--mono`/`--no-color` or `COLOR=0` — monochrome in chafa/jp2a
- `--color` or `COLOR=1` — force color in chafa/jp2a
- `-h|--help` — show usage

Examples:

```bash
./ascii_play.sh "demo clip.mp4"           # auto-fit to terminal
WIDTH=240 ./ascii_play.sh "demo.mp4"      # force wider output
./ascii_play.sh --mute "demo.mp4"         # mpv without audio
FPS=20 ./ascii_play.sh --mono "demo.mp4"  # faster, monochrome fallback
```

---

## Behavior

- Auto-selects: mpv+libcaca → ffmpeg+chafa → ffmpeg+jp2a.
- Auto-fits width/height to the current terminal when larger dimensions are requested.
- Restores terminal echo/cursor after playback and cleans temp frames.
- Quit: `q` in mpv; `Ctrl+C` in fallback loops.

---

## Troubleshooting

- “Couldn't find a usable setup.” — install one supported combo (mpv+caca recommended; otherwise ffmpeg+chafa or ffmpeg+jp2a).
- Wrapped/overflowing text — reduce `--width` or shrink font/fullscreen terminal; height auto-fits when not set.
- Filename parsing issues — wrap the path in quotes: `./ascii_play.sh "My Clip | test.mp4"`.
