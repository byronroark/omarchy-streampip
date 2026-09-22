#!/usr/bin/env bash
# Remove only the files and clearly delimited lines installed by install.sh.
set -euo pipefail

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
hypr_dir="$config_home/hypr"
rm -f "$HOME/.local/bin/stream-pip" "$hypr_dir/stream-pip.lua" \
  "$data_home/applications/omarchy-streampip.desktop" \
  "$data_home/icons/hicolor/scalable/apps/omarchy-streampip.svg"

sed -i '/^-- Live Stream PiP: prompts for an RTSP\/RTSPS URL and opens a pinned overlay\.$/d; /^o.bind("SUPER + SHIFT + ALT + L", "Live Stream PiP", "live-stream-pip")$/d' "$hypr_dir/bindings.lua"
sed -i '/^-- Stream PiP: prompts for an RTSP\/RTSPS URL and opens a pinned overlay\.$/d; /^o.bind("SUPER + SHIFT + ALT + L", "Stream PiP", "stream-pip")$/d' "$hypr_dir/bindings.lua"
sed -i '/^o.bind("SUPER + SHIFT + ALT + L", "Stream PiP", "omarchy-shell byronroark.streampip toggle")$/d; /^o.bind("SUPER + SHIFT + ALT + L", "Stream PiP", "omarchy-shell shell toggle byronroark.streampip")$/d' "$hypr_dir/bindings.lua"
sed -i '/^-- Close StreamPiP even when its window has not received keyboard focus\.$/,/^o.bind("SUPER + SHIFT + ALT + W", "Close Stream PiP", close_stream_pip)$/d' "$hypr_dir/bindings.lua"
sed -i '/^-- Live Stream PiP window rules\.$/d; /^dofile(os.getenv("HOME") .. "\/.config\/hypr\/live-stream-pip.lua")$/d' "$hypr_dir/hyprland.lua"

hyprctl reload
hyprctl configerrors
printf '%s\n' 'Stream PiP removed. Saved streams remain in ~/.config/omarchy/live-stream-pip/streams.tsv.'
