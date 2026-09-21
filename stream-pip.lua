-- User-owned Hyprland rule for the Stream PiP launcher.
-- It remains pinned across workspaces and uses Omarchy's native floating
-- resize gesture: SUPER + right-mouse drag.
o.window({ class = "^omarchy-stream-pip$", title = "^Stream PiP$" }, {
  tag = "-default-opacity",
  float = true,
  pin = true,
  no_dim = true,
  keep_aspect_ratio = true,
  size = { 600, 338 },
  move = { "(monitor_w-window_w-40)", "(monitor_h-window_h-40)" },
  border_size = 0,
  opacity = "1 1",
})
