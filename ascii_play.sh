#!/usr/bin/env bash
set -euo pipefail

INPUT="${1:-}"
WIDTH="${WIDTH:-160}"
FPS="${FPS:-15}"
COLOR="${COLOR:-1}"

need() { command -v "$1" >/dev/null 2>&1; }

if [[ -z "$INPUT" ]]; then
  echo "Usage: $0 <video file>"
  exit 1
fi

if [[ ! -f "$INPUT" ]]; then
  echo "Error: input file not found: $INPUT"
  exit 1
fi

# 1) mpv + libcaca (audio included)
# Try to force richer color; if option not supported, fall back to plain caca.
if need mpv; then
  if mpv --vo=caca --ao=null --frames=1 "$INPUT" >/dev/null 2>&1; then
    echo "Using: mpv + libcaca (audio enabled)"
    if mpv --no-config --quiet --vo=caca --vo-caca-color=full --vf="scale=${WIDTH}:-2" "$INPUT" >/dev/null 2>&1; then
      exec mpv --no-config --quiet --vo=caca --vo-caca-color=full --vf="scale=${WIDTH}:-2" "$INPUT"
    else
      # Some mpv builds don't expose vo-caca-* options
      exec mpv --no-config --quiet --vo=caca --vf="scale=${WIDTH}:-2" "$INPUT"
    fi
  fi
fi

# 2) ffmpeg + chafa (no audio) — more colours + better shading
if need ffmpeg && need chafa; then
  echo "Using: ffmpeg + chafa (no audio)"
  TMPDIR="$(mktemp -d)"
  cleanup() { stty echo 2>/dev/null || true; tput cnorm 2>/dev/null || true; rm -rf "$TMPDIR"; }
  trap cleanup EXIT INT TERM

  ffmpeg -hide_banner -loglevel error -i "$INPUT" \
    -vf "fps=${FPS},scale=${WIDTH}:-2:flags=lanczos" \
    "$TMPDIR/frame_%06d.png"

  frame_delay="$(awk "BEGIN{print 1.0/${FPS}}")"
  stty -echo 2>/dev/null || true
  tput civis 2>/dev/null || true
  clear

  shopt -s nullglob
  for f in "$TMPDIR"/frame_*.png; do
    tput cup 0 0

    if [[ "$COLOR" == "1" ]]; then
      # "truecolor" gives far more colours than 256-color terminals.
      # Use a dense set of symbols for smoother gradients (still text).
      chafa --colors truecolor --dither ordered --symbols block+border+space "$f"
    else
      chafa --colors none --dither ordered --symbols block+border+space "$f"
    fi

    sleep "$frame_delay"
  done
  exit 0
fi

# 3) ffmpeg + jp2a (no audio) — limited vs chafa but keep
if need ffmpeg && need jp2a; then
  echo "Using: ffmpeg + jp2a (no audio)"
  TMPDIR="$(mktemp -d)"
  cleanup() { stty echo 2>/dev/null || true; tput cnorm 2>/dev/null || true; rm -rf "$TMPDIR"; }
  trap cleanup EXIT INT TERM

  ffmpeg -hide_banner -loglevel error -i "$INPUT" \
    -vf "fps=${FPS},scale=${WIDTH}:-2:flags=lanczos" \
    "$TMPDIR/frame_%06d.jpg"

  frame_delay="$(awk "BEGIN{print 1.0/${FPS}}")"
  stty -echo 2>/dev/null || true
  tput civis 2>/dev/null || true
  clear

  shopt -s nullglob
  for f in "$TMPDIR"/frame_*.jpg; do
    tput cup 0 0
    if [[ "$COLOR" == "1" ]]; then
      jp2a --width="$WIDTH" --colors "$f"
    else
      jp2a --width="$WIDTH" "$f"
    fi
    sleep "$frame_delay"
  done
  exit 0
fi

echo "Couldn't find a usable setup."
echo "Install one of these combos:"
echo "  - mpv + libcaca"
echo "  - ffmpeg + chafa"
echo "  - ffmpeg + jp2a"
exit 1
