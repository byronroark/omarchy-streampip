#!/usr/bin/env bash
# Install the launcher and add idempotent Omarchy user-config integration.
set -euo pipefail

plugin_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
hypr_dir="$config_home/hypr"
bin_dir="$HOME/.local/bin"
rule_file="$hypr_dir/live-stream-pip.lua"
bindings_file="$hypr_dir/bindings.lua"
hyprland_file="$hypr_dir/hyprland.lua"

mkdir -p "$bin_dir" "$hypr_dir"
install -m 0755 "$plugin_dir/live-stream-pip" "$bin_dir/live-stream-pip"
install -m 0644 "$plugin_dir/live-stream-pip.lua" "$rule_file"
touch "$bindings_file" "$hyprland_file"

if ! rg -Fq 'live-stream-pip' "$bindings_file"; then
  cat >> "$bindings_file" <<'EOF'

-- Live Stream PiP: prompts for an RTSP/RTSPS URL and opens a pinned overlay.
o.bind("SUPER + SHIFT + ALT + L", "Live Stream PiP", "live-stream-pip")
EOF
fi

if ! rg -Fq 'live-stream-pip.lua' "$hyprland_file"; then
  cat >> "$hyprland_file" <<'EOF'

-- Live Stream PiP window rules.
dofile(os.getenv("HOME") .. "/.config/hypr/live-stream-pip.lua")
EOF
fi

hyprctl reload
hyprctl configerrors

printf '%s\n' 'Live Stream PiP installed.'
printf '%s\n' 'Press SUPER + SHIFT + ALT + L to enter or reuse an RTSP URL.'
printf '%s\n' 'Resize the PiP with SUPER + Right Mouse drag.'
