````markdown
# ascii-play

Play any video as animated ASCII art in your terminal.

This project uses **mpv + libcaca** for the best experience (ASCII video + audio), and can fall back to **ffmpeg + chafa** or **ffmpeg + jp2a** (no audio) if needed.

---

## Prerequisites

### Recommended (best: ASCII + audio)
Install `mpv` and `libcaca` tools:

```bash
sudo apt update
sudo apt install -y mpv caca-utils
````

### Optional fallbacks (no audio)

If you want the fallback modes too:

```bash
sudo apt install -y ffmpeg chafa jp2a
```

Check what you have installed:

```bash
command -v mpv ffmpeg chafa jp2a
```

---

## Setup

Make the script executable:

```bash
chmod +x ascii_play.sh
```

---

## Run

### Run with a video file

(Use quotes if the filename has spaces or special characters.)

```bash
./ascii_play.sh 'your video file.mp4'
```

Example:

```bash
./ascii_play.sh 'Character Demo - "Wriothesley: Art of Improvisation" | Genshin Impact.mp4'
```

### Increase detail (more characters per frame)

Higher `WIDTH` = more detail (but heavier).

```bash
WIDTH=240 ./ascii_play.sh 'your video file.mp4'
```

Common values: `160`, `200`, `240`, `300`.

### Adjust speed / smoothness (fallback modes)

`FPS` affects the **ffmpeg + chafa/jp2a** fallback path.

```bash
FPS=20 ./ascii_play.sh 'your video file.mp4'
```

### Color on/off (fallback modes)

`COLOR` affects the **chafa/jp2a** fallback path.

```bash
COLOR=1 ./ascii_play.sh 'your video file.mp4'   # color
COLOR=0 ./ascii_play.sh 'your video file.mp4'   # mono
```

---

## Tips

### Terminal size matters

ASCII clarity depends heavily on how many columns/rows your terminal has.

Check your terminal size:

```bash
tput cols; tput lines
```

For better clarity:

* Fullscreen the terminal
* Reduce font size (more columns/rows visible)
* Increase `WIDTH` (but keep it <= terminal columns to avoid wrapping)

### Stop playback

* mpv mode: press `q`
* fallback loops: `Ctrl + C`

---

## Troubleshooting

### “Couldn't find a usable setup.”

Install at least one supported combo:

* **mpv + libcaca** (recommended):

  ```bash
  sudo apt install -y mpv caca-utils
  ```

* **ffmpeg + chafa**:

  ```bash
  sudo apt install -y ffmpeg chafa
  ```

* **ffmpeg + jp2a**:

  ```bash
  sudo apt install -y ffmpeg jp2a
  ```

### Filename issues (spaces / quotes / | )

Wrap the filename in single quotes:

```bash
./ascii_play.sh 'my file | name "test".mp4'
```

Or rename the file:

```bash
mv 'Long File Name.mp4' video.mp4
./ascii_play.sh video.mp4
```

---

