-- User-owned Hyprland rule for the Stream PiP launcher.
-- It remains pinned across workspaces and uses Omarchy's native floating
-- resize gesture: SUPER + right-mouse drag.
o.window({ class = "^omarchy-stream-pip$", title = "^Stream PiP$" }, {
  tag = "-default-opacity",
  float = true,
  pin = true,
  no_dim = true,
  -- Pointer-driven geometry must not chase animated intermediate positions.
  no_anim = true,
  keep_aspect_ratio = true,
  size = { 600, 338 },
  move = { "(monitor_w-window_w-40)", "(monitor_h-window_h-40)" },
  border_size = 0,
  opacity = "1 1",
})

local function pip_at_cursor()
  local cursor = hl.get_cursor_pos()
  for _, window in pairs(hl.get_windows()) do
    if window.class == "omarchy-stream-pip" and cursor.x >= window.at.x and cursor.x < window.at.x + window.size.x
      and cursor.y >= window.at.y and cursor.y < window.at.y + window.size.y then
      return window
    end
  end
end

local group_drag_timer = nil
local group_drag_address = nil
local group_drag_snap_on_release = false
local group_resize_timer = nil
local group_resize_address = nil
local group_settle_timer = nil
local shift_drag_active = false
local drag_update = nil
local resize_update = nil

-- Mouse binds without modifiers may also be considered while Shift is held.
-- Use the real XKB keysyms (not the invalid generic "SHIFT" keysym) so the
-- ordinary group-drag path is a no-op for a Shift-drag gesture.
local function shift_is_down()
  return hl.is_key_down("Shift_L") or hl.is_key_down("Shift_R")
end

-- A new gesture owns all geometry updates and cancels pending snap timers.
local function cancel_gesture()
  if group_settle_timer then group_settle_timer:set_enabled(false); group_settle_timer = nil end
  if group_drag_timer then group_drag_timer:set_enabled(false); group_drag_timer = nil end
  if group_resize_timer then group_resize_timer:set_enabled(false); group_resize_timer = nil end
  drag_update, resize_update = nil, nil
  group_drag_address, group_resize_address = nil, nil
  group_drag_snap_on_release = false
  shift_drag_active = false
end

local function detached_addresses()
  local detached = {}
  local file = io.open((os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/omarchy/live-stream-pip/detached-pips", "r")
  if not file then return detached end
  for address in file:lines() do detached[address] = true end
  file:close()
  return detached
end

local function start_individual_stream_pip_drag(selected, snap_on_release)
  cancel_gesture()
  local start = hl.get_cursor_pos()
  local origin_x, origin_y = selected.at.x, selected.at.y
  if group_drag_timer then group_drag_timer:set_enabled(false) end
  group_drag_address = selected.address
  group_drag_snap_on_release = snap_on_release
  drag_update = function()
    local cursor = hl.get_cursor_pos()
    hl.dispatch(hl.dsp.window.move({
      x = origin_x + cursor.x - start.x,
      y = origin_y + cursor.y - start.y,
      window = selected,
    }))
  end
  group_drag_timer = hl.timer(drag_update, { timeout = 16, type = "repeat" })
end

local function start_stream_pip_group_drag()
  if shift_drag_active or shift_is_down() then return end
  local selected = pip_at_cursor()
  if not selected then return end
  cancel_gesture()
  local start = hl.get_cursor_pos()
  local detached = detached_addresses()
  -- A peeled PiP is independent. Its ordinary drag must move itself, rather
  -- than moving whichever attached PiPs happen to remain in a group.
  if detached[selected.address] then
    start_individual_stream_pip_drag(selected, true)
    return
  end
  local positions = {}
  for _, window in pairs(hl.get_windows()) do
    if window.class == "omarchy-stream-pip" and not detached[window.address] then
      positions[#positions + 1] = { window = window, x = window.at.x, y = window.at.y }
    end
  end
  if group_drag_timer then group_drag_timer:set_enabled(false) end
  group_drag_address = selected.address
  drag_update = function()
    local cursor = hl.get_cursor_pos()
    local dx, dy = cursor.x - start.x, cursor.y - start.y
    for _, position in ipairs(positions) do
      hl.dispatch(hl.dsp.window.move({ x = position.x + dx, y = position.y + dy, window = position.window }))
    end
  end
  group_drag_timer = hl.timer(drag_update, { timeout = 16, type = "repeat" })
end

local function stop_stream_pip_group_drag()
  if drag_update then drag_update(); drag_update = nil end
  if group_drag_timer then group_drag_timer:set_enabled(false); group_drag_timer = nil end
  -- Every attached member receives the same delta, so group geometry remains
  -- intact without a post-drag layout pass that could move it unexpectedly.
  local address, should_snap = group_drag_address, group_drag_snap_on_release
  group_drag_address = nil
  group_drag_snap_on_release = false
  if address and should_snap then
    if group_settle_timer then group_settle_timer:set_enabled(false) end
    group_settle_timer = hl.timer(function()
      hl.exec_cmd("stream-pip-layout --snap " .. o.shell_quote(address))
      group_settle_timer = nil
    end, { timeout = 100, type = "oneshot" })
  end
end

local function start_stream_pip_group_resize()
  if not shift_is_down() then return end
  local selected = pip_at_cursor()
  if not selected then return end
  cancel_gesture()

  local start = hl.get_cursor_pos()
  local base_width = selected.size.x
  local base_height = selected.size.y
  local base_x = selected.at.x
  local base_y = selected.at.y
  local anchor_left = start.x < base_x + base_width / 2
  local anchor_top = start.y < base_y + base_height / 2
  local resize_sensitivity = 0.75

  if group_resize_timer then group_resize_timer:set_enabled(false) end
  group_resize_address = selected.address
  resize_update = function()
    local cursor = hl.get_cursor_pos()
    local horizontal_delta = (anchor_left and start.x - cursor.x or cursor.x - start.x) * resize_sensitivity
    local vertical_delta = (anchor_top and start.y - cursor.y or cursor.y - start.y) * 16 / 9 * resize_sensitivity
    -- Project onto the aspect-ratio diagonal continuously. Choosing the
    -- dominant axis each frame jumps when the pointer crosses that boundary.
    local raw_delta = (horizontal_delta + vertical_delta * (9 / 16)^2) / (1 + (9 / 16)^2)
    local delta = raw_delta >= 0 and math.floor(raw_delta) or math.ceil(raw_delta)
    -- Permit large inspection views while retaining a sane lower bound.
    local width = math.max(160, math.min(1600, base_width + delta))
    local height = math.floor(width * 9 / 16)
    local x = anchor_left and base_x + base_width - width or base_x
    local y = anchor_top and base_y + base_height - height or base_y
    hl.dispatch(hl.dsp.window.resize({ x = width, y = height, window = selected }))
    hl.dispatch(hl.dsp.window.move({ x = x, y = y, window = selected }))
  end
  group_resize_timer = hl.timer(resize_update, { timeout = 16, type = "repeat" })
end

local function stop_stream_pip_group_resize()
  if resize_update then resize_update(); resize_update = nil end
  if group_resize_timer then group_resize_timer:set_enabled(false); group_resize_timer = nil end
  group_resize_address = nil
end

local function drag_stream_pip_group(detach)
  local window = pip_at_cursor()
  if not window then return end
  local address = o.shell_quote(window.address)
  if not detach then start_stream_pip_group_drag(); return end
  -- Hyprland may evaluate the unmodified mouse binding for this same press.
  -- Cancel it explicitly before starting the independent Shift-drag.
  shift_drag_active = true
  if group_drag_timer then group_drag_timer:set_enabled(false); group_drag_timer = nil end
  group_drag_address = nil
  group_drag_snap_on_release = false
  if group_settle_timer then group_settle_timer:set_enabled(false); group_settle_timer = nil end
  hl.exec_cmd("stream-pip-layout --detach " .. address)
  start_individual_stream_pip_drag(window, true)
end

local function finish_shift_stream_pip_drag()
  stop_stream_pip_group_drag()
  shift_drag_active = false
end

-- Keep Omarchy's familiar SUPER+T behavior everywhere except StreamPiP:
-- camera thumbnails remain floating and are simply re-snapped as a group.
hl.unbind("SUPER + T")
o.bind("SUPER + T", "Toggle window floating/tiling", function()
  local window = hl.get_active_window()
  if window and window.class == "omarchy-stream-pip" then
    hl.exec_cmd("stream-pip-layout --snap-all")
  else
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
  end
end)

-- Mouse events remain non-consuming everywhere else. On a StreamPiP thumbnail,
-- LMB moves its snap group; Shift+LMB detaches it. Only Shift-drag releases
-- attempt to snap that thumbnail back near its group.
o.bind("mouse:272", "Move StreamPiP group", function() drag_stream_pip_group(false) end, { mouse = true, non_consuming = true })
o.bind("mouse:272", "Finish StreamPiP group move", stop_stream_pip_group_drag, { mouse = true, release = true, non_consuming = true })
o.bind("SHIFT + mouse:272", "Detach StreamPiP", function() drag_stream_pip_group(true) end, { mouse = true, non_consuming = true })
o.bind("SHIFT + mouse:272", "Finish StreamPiP detach", finish_shift_stream_pip_drag, { mouse = true, release = true, non_consuming = true })
o.bind("SHIFT + mouse:273", "Resize StreamPiP group", start_stream_pip_group_resize, { mouse = true, non_consuming = true })
o.bind("SHIFT + mouse:273", "Finish StreamPiP group resize", stop_stream_pip_group_resize, { mouse = true, release = true, non_consuming = true })
