#!/bin/bash
# Rebuild preview.png and the Discord screenshots (publish/shots/) from the live desktop.
# Needs Deep Space applied and an empty workspace showing on MONITOR (1920x1080).
# Switches windows to Glassy for the shots, then restores your setting and focus.
# Usage: tools/screenshots.sh [monitor]   (default HDMI-A-1)
set -euo pipefail
MONITOR=${1:-HDMI-A-1}
cd "$(dirname "$0")/.."
OUT=publish/shots
APP=deep-space-shot
mkdir -p "$OUT"
back=$(hyprctl activewindow -j | jq -r .address)
mode=$(omarchy hyprland window transparency)
pids=()

dispatch() { hyprctl dispatch "$1" >/dev/null; }
shot() { sleep "${2:-1}"; grim -o "$MONITOR" -t png -l 6 "$OUT/$1.png"; }
# Start a terminal, wait for its window, then float it at x y with size w h.
term() {
  local x=$1 y=$2 w=$3 h=$4 before
  shift 4
  before=$(hyprctl clients -j | jq "[.[] | select(.class == \"$APP\")] | length")
  foot --app-id="$APP" "$@" &>/dev/null &
  pids+=($!)
  for _ in $(seq 50); do
    (( $(hyprctl clients -j | jq "[.[] | select(.class == \"$APP\")] | length") > before )) && break
    sleep 0.1
  done
  # A new window takes focus, so the active window is the one just opened.
  local win="address:$(hyprctl activewindow -j | jq -r .address)"
  dispatch "hl.dsp.window.float({ window = \"$win\", action = \"enable\" })"
  dispatch "hl.dsp.window.resize({ window = \"$win\", x = $w, y = $h })"
  dispatch "hl.dsp.window.move({ window = \"$win\", x = $x, y = $y })"
}
cleanup() {
  omarchy menu close &>/dev/null || true
  kill "${pids[@]}" 2>/dev/null || true
  [[ $(omarchy hyprland window transparency) == "$mode" ]] || omarchy hyprland window transparency "$mode" &>/dev/null
  dispatch "hl.dsp.focus({ window = \"address:$back\" })" || true
}
trap cleanup EXIT

[[ $(cat ~/.local/state/omarchy/current/theme.name) == deep-space ]] || { echo "Apply Deep Space first: omarchy theme set deep-space" >&2; exit 1; }
bgs=(~/.local/state/omarchy/current/theme/backgrounds/*)
omarchy theme bg set "${bgs[0]}"
dispatch "hl.dsp.focus({ monitor = \"$MONITOR\" })"
shot desktop 2

omarchy hyprland window transparency glassy &>/dev/null
# Right half only: the walker, the ring's curl and its bright arc stay in view on the left.
term 1000 56 890 470 bash -c 'fastfetch -c tools/fastfetch.jsonc; exec bash'
term 1000 556 890 494 -e nvim +45 -c 'set scrolloff=0' -c 'normal! zt' tools/palettes.py
shot hero 2
# 1:1 pixel close-up of the Neovim window.
magick "$OUT/hero.png" -crop 890x494+1000+556 +repage "$OUT/code.png"

# Discord GIF: the same layout through all ten wallpapers, ending on the first so it loops.
gpu-screen-recorder -w "$MONITOR" -f 30 -cursor no -o "$OUT/cycle.mp4" &>/dev/null &
rec=$!
sleep 2
for bg in "${bgs[@]:1}" "${bgs[0]}"; do
  omarchy theme bg set "$bg"
  sleep "${HOLD:-2}"
done
kill -INT $rec && wait $rec || true
ffmpeg -v error -y -i "$OUT/cycle.mp4" -vf "fps=12,scale=960:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=128:stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=3:diff_mode=rectangle" publish/deep-space.gif

omarchy menu summon
shot menu 1.5

# 256 colours keep preview.png under 1 MB. libimagequant (the pngquant engine) leaves no
# tints in the blurred areas, where ImageMagick's own quantizer does.
uv run -q --with imagequant --with pillow python -I -c '
import imagequant, sys
from PIL import Image
im = Image.open(sys.argv[1]).convert("RGBA").resize((1800, 1012), Image.LANCZOS)
imagequant.quantize_pil_image(im, dithering_level=1.0, max_colors=256).save("preview.png", optimize=True)
' "$OUT/hero.png"
