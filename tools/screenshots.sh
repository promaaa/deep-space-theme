#!/bin/bash
# Rebuild preview.png and the Discord screenshots (publish/shots/) from the live desktop.
# Needs Deep Space applied and an empty workspace showing on MONITOR.
# Focus moves to MONITOR for about 15 seconds, then returns.
# Usage: tools/screenshots.sh [monitor]   (default HDMI-A-1)
set -euo pipefail
MONITOR=${1:-HDMI-A-1}
cd "$(dirname "$0")/.."
OUT=publish/shots
APP=deep-space-shot
mkdir -p "$OUT"
back=$(hyprctl activewindow -j | jq -r .address)
pids=()

dispatch() { hyprctl dispatch "$1" >/dev/null; }
shot() { sleep "${2:-1}"; grim -o "$MONITOR" -t png -l 6 "$OUT/$1.png"; }
# Start a terminal and wait until its window is on screen, so the tiling order stays fixed.
term() {
  local before
  before=$(hyprctl clients -j | jq "[.[] | select(.class == \"$APP\")] | length")
  foot --app-id="$APP" "$@" &>/dev/null &
  pids+=($!)
  for _ in $(seq 50); do
    (( $(hyprctl clients -j | jq "[.[] | select(.class == \"$APP\")] | length") > before )) && return
    sleep 0.1
  done
}
cleanup() {
  omarchy menu close &>/dev/null || true
  kill "${pids[@]}" 2>/dev/null || true
  rm -f "${btop_conf:-}"
  dispatch "hl.dsp.focus({ window = \"address:$back\" })"
}
trap cleanup EXIT

[[ $(cat ~/.local/state/omarchy/current/theme.name) == deep-space ]] || { echo "Apply Deep Space first: omarchy theme set deep-space" >&2; exit 1; }
dispatch "hl.dsp.focus({ monitor = \"$MONITOR\" })"
shot desktop

term -e nvim tools/palettes.py
# btop without the net box: its header shows the machine's IP address.
btop_conf=$(mktemp --suffix=.conf)
sed 's/^shown_boxes = .*/shown_boxes = "cpu mem"/' ~/.config/btop/btop.conf >"$btop_conf"
term -e btop -c "$btop_conf"
term bash -c 'omarchy dev theme preview deep-space --no-osc; exec bash'
shot terminals 3
# 1:1 pixel close-up of the Neovim pane (top left).
magick "$OUT/terminals.png" -crop 940x530+12+38 +repage "$OUT/code.png"

notify-send -a Omarchy "Deep Space" "Theme set. Text 13:1, comments 5.5:1."
omarchy menu summon
shot menu 1.5

magick "$OUT/terminals.png" -resize '1800x1012!' preview.png
