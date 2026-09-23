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

-- The named special workspace is used only when StreamPiP is arranged into
-- native tiles. It does not change global special-workspace scale settings.
hl.workspace_rule({
  workspace = "special:streampip",
  persistent = true,
  layout = "dwindle",
  gaps_in = 12,
  gaps_out = 20,
})

-- Keep StreamPiP's overlay visible while changing normal workspaces. This is
-- restored to Omarchy's default when this plugin rule file is removed.
hl.config({
  binds = {
    hide_special_on_workspace_change = false,
  },
})
