#!/usr/bin/env bash
# Remove only the files and clearly delimited lines installed by install.sh.
set -euo pipefail

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
hypr_dir="$config_home/hypr"
rm -f "$HOME/.local/bin/live-stream-pip" "$hypr_dir/live-stream-pip.lua"

sed -i '/^-- Live Stream PiP: prompts for an RTSP\/RTSPS URL and opens a pinned overlay\.$/d; /^o.bind("SUPER + SHIFT + ALT + L", "Live Stream PiP", "live-stream-pip")$/d' "$hypr_dir/bindings.lua"
sed -i '/^-- Live Stream PiP window rules\.$/d; /^dofile(os.getenv("HOME") .. "\/.config\/hypr\/live-stream-pip.lua")$/d' "$hypr_dir/hyprland.lua"

hyprctl reload
hyprctl configerrors
printf '%s\n' 'Live Stream PiP removed. The saved RTSP URL remains in ~/.config/omarchy/live-stream-pip/stream-url.'
