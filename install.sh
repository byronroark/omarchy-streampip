#!/usr/bin/env bash
# Install the launcher and add idempotent Omarchy user-config integration.
set -euo pipefail

plugin_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
hypr_dir="$config_home/hypr"
bin_dir="$HOME/.local/bin"
applications_dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
icons_dir="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/scalable/apps"
rule_file="$hypr_dir/stream-pip.lua"
bindings_file="$hypr_dir/bindings.lua"
hyprland_file="$hypr_dir/hyprland.lua"

mkdir -p "$bin_dir" "$hypr_dir" "$applications_dir" "$icons_dir"
rm -f "$bin_dir/live-stream-pip" "$hypr_dir/live-stream-pip.lua"
install -m 0755 "$plugin_dir/stream-pip" "$bin_dir/stream-pip"
install -m 0644 "$plugin_dir/stream-pip.lua" "$rule_file"
install -m 0644 "$plugin_dir/omarchy-streampip.desktop" "$applications_dir/omarchy-streampip.desktop"
install -m 0644 "$plugin_dir/omarchy-streampip.svg" "$icons_dir/omarchy-streampip.svg"
touch "$bindings_file" "$hyprland_file"

if ! rg -Fq '"Stream PiP", "stream-pip"' "$bindings_file"; then
  cat >> "$bindings_file" <<'EOF'

-- Stream PiP: prompts for an RTSP/RTSPS URL and opens a pinned overlay.
o.bind("SUPER + SHIFT + ALT + L", "Stream PiP", "stream-pip")
EOF
fi

if ! rg -Fq 'Close Stream PiP' "$bindings_file"; then
  cat >> "$bindings_file" <<'EOF'

-- Close StreamPiP even when its window has not received keyboard focus.
local function close_stream_pip()
  for _, window in pairs(hl.get_windows()) do
    if window.class == "omarchy-stream-pip" or window.class == "omarchy-live-stream-pip" then
      hl.dispatch(hl.dsp.window.close({ window = window }))
    end
  end
end
o.bind("SUPER + SHIFT + ALT + W", "Close Stream PiP", close_stream_pip)
EOF
fi

if ! rg -Fq 'stream-pip.lua' "$hyprland_file"; then
  cat >> "$hyprland_file" <<'EOF'

-- Stream PiP window rules.
dofile(os.getenv("HOME") .. "/.config/hypr/stream-pip.lua")
EOF
fi

hyprctl reload
hyprctl configerrors

printf '%s\n' 'Stream PiP installed.'
printf '%s\n' 'Launch StreamPiP from Omarchy Apps, the bar icon, or SUPER + SHIFT + ALT + L.'
printf '%s\n' 'Press SUPER + SHIFT + ALT + L to enter or reuse an RTSP URL.'
printf '%s\n' 'Resize the PiP with SUPER + Right Mouse drag.'
