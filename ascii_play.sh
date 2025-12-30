#!/usr/bin/env bash
set -euo pipefail

INPUT=""
WIDTH="${WIDTH:-160}"
HEIGHT="${HEIGHT:-}"
FPS="${FPS:-15}"
COLOR="${COLOR:-1}"
AUDIO="${AUDIO:-1}"

usage() {
  cat <<'EOF'
Usage: ascii_play.sh [options] <video file>
Options:
  --mute, --no-audio     Disable audio when using mpv (or set AUDIO=0)
  --audio <0|1>          Explicitly enable/disable audio for mpv
  --width, -w <cols>     Target character width (default: 160 or env WIDTH)
  --height, -h <rows>    Target character height (env HEIGHT; auto-fit if empty)
  --fps <n>              FPS for playback (mpv/ffmpeg; default: 15 or env FPS)
  --mono, --no-color     Force monochrome output (or set COLOR=0)
  --color                Force color output (or set COLOR=1)
  -h, --help             Show this help
EOF
}

need() { command -v "$1" >/dev/null 2>&1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mute|--no-audio) AUDIO=0; shift ;;
    --audio)
      AUDIO="${2:-}"; shift 2 ;;
    --width|-w)
      WIDTH="${2:-}"; shift 2 ;;
    --height|-h)
      HEIGHT="${2:-}"; shift 2 ;;
    --fps)
      FPS="${2:-}"; shift 2 ;;
    --mono|--no-color)
      COLOR=0; shift ;;
    --color)
      COLOR=1; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      if [[ -z "$INPUT" ]]; then
        INPUT="$1"
      else
        echo "Unexpected argument: $1"
        usage
        exit 1
      fi
      shift ;;
  esac
done

if [[ -z "$INPUT" ]]; then
  usage
  exit 1
fi

if [[ ! -f "$INPUT" ]]; then
  echo "Error: input file not found: $INPUT"
  exit 1
fi

term_width="$(tput cols 2>/dev/null || true)"
term_height="$(tput lines 2>/dev/null || true)"
target_width="$WIDTH"

if [[ -n "$term_width" && "$target_width" -gt "$term_width" ]]; then
  target_width="$term_width"
fi

if [[ -n "$HEIGHT" ]]; then
  target_height="$HEIGHT"
elif [[ -n "$term_height" ]]; then
  target_height="$term_height"
else
  target_height=""
fi

if [[ -n "$target_height" ]]; then
  scale_filter="scale=${target_width}:${target_height}:flags=lanczos"
  mpv_scale="${target_width}:${target_height}"
else
  scale_filter="scale=${target_width}:-2:flags=lanczos"
  mpv_scale="${target_width}:-2"
fi
mpv_vf="scale=${mpv_scale}"
if [[ -n "$FPS" ]]; then
  mpv_vf="fps=${FPS},${mpv_vf}"
fi

mpv_audio_flag=()
if [[ "$AUDIO" == "0" ]]; then
  mpv_audio_flag+=(--no-audio)
fi

# 1) mpv + libcaca (audio included)
# Try to force richer color; if option not supported, fall back to plain caca.
if need mpv; then
  if mpv --vo=caca --ao=null --frames=1 "$INPUT" >/dev/null 2>&1; then
    mpv_audio_status="enabled"
    if [[ "$AUDIO" == "0" ]]; then
      mpv_audio_status="muted"
    fi
    echo "Using: mpv + libcaca (audio ${mpv_audio_status})"
    if mpv --no-config --quiet --vo=caca --vo-caca-color=full --vf="${mpv_vf}" "${mpv_audio_flag[@]}" "$INPUT" >/dev/null 2>&1; then
      exec mpv --no-config --quiet --vo=caca --vo-caca-color=full --vf="${mpv_vf}" "${mpv_audio_flag[@]}" "$INPUT"
    else
      # Some mpv builds don't expose vo-caca-* options
      exec mpv --no-config --quiet --vo=caca --vf="${mpv_vf}" "${mpv_audio_flag[@]}" "$INPUT"
    fi
  else
    echo "Skipping mpv + libcaca: mpv present but caca output test failed" >&2
  fi
else
  echo "Skipping mpv + libcaca: mpv not found" >&2
fi

# 2) ffmpeg + chafa (no audio) — more colours + better shading
if need ffmpeg && need chafa; then
  echo "Using: ffmpeg + chafa (no audio)"
  TMPDIR="$(mktemp -d)"
  cleanup() { stty echo 2>/dev/null || true; tput cnorm 2>/dev/null || true; rm -rf "$TMPDIR"; }
  trap cleanup EXIT INT TERM

  ffmpeg -hide_banner -loglevel error -i "$INPUT" \
    -vf "fps=${FPS},${scale_filter}" \
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
else
  if ! need ffmpeg; then
    echo "Skipping ffmpeg + chafa: ffmpeg not found" >&2
  fi
  if ! need chafa; then
    echo "Skipping ffmpeg + chafa: chafa not found" >&2
  fi
fi

# 3) ffmpeg + jp2a (no audio) — limited vs chafa but keep
if need ffmpeg && need jp2a; then
  echo "Using: ffmpeg + jp2a (no audio)"
  TMPDIR="$(mktemp -d)"
  cleanup() { stty echo 2>/dev/null || true; tput cnorm 2>/dev/null || true; rm -rf "$TMPDIR"; }
  trap cleanup EXIT INT TERM

  ffmpeg -hide_banner -loglevel error -i "$INPUT" \
    -vf "fps=${FPS},${scale_filter}" \
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
else
  if ! need ffmpeg; then
    echo "Skipping ffmpeg + jp2a: ffmpeg not found" >&2
  fi
  if ! need jp2a; then
    echo "Skipping ffmpeg + jp2a: jp2a not found" >&2
  fi
fi

echo "Couldn't find a usable setup."
echo "Install one of these combos:"
echo "  - mpv + libcaca"
echo "  - ffmpeg + chafa"
echo "  - ffmpeg + jp2a"
exit 1
