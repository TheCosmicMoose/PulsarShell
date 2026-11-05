
------------------
---- Programs ----
------------------

--Variables--

local terminal = "kitty"
local fileManager = "nautilus"
local launcher = "qs ipc call launcher toggle" --quickshell launcher--
local browser = "zen-browser"
local ide = "zeditor"
local textEditor = "nvim"
local lockScreen = "hyprlock"
local shutDown = "wlogout -b 6"
local audioOSD = "qs ipc call audioosd show"

local mainMod = "SUPER"

--Window Management Keybindings--

hl.bind(mainMod .. " + Q", hl.dsp.window.close()) --Super + Q closes active window
hl.bind(mainMod .. " + W", hl.dsp.window.float({ action = "toggle" })) -- Super + W toggles whether the active window is floating
hl.bind(mainMod .. " + F11", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle"}))
hl.bind(mainMod .. " + M", hl.dsp.layout("cyclenext"))

-- Move focus with mainMod + j,k,l,; --

hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left"}))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right"}))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up"}))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down"}))

-- Swap window positons with mainMod + ALT + j,k,l,; --

hl.bind(mainMod .. " + ALT + H", hl.dsp.window.swap({ direction = "left"}))
hl.bind(mainMod .. " + ALT + L", hl.dsp.window.swap({ direction = "right"}))
hl.bind(mainMod .. " + ALT + K", hl.dsp.window.swap({ direction = "up"}))
hl.bind(mainMod .. " + ALT + J", hl.dsp.window.swap({ direction = "down"}))

-- Switch Workspaces with mainMod + [0-9] --
-- Move active window to a workspace with mainMod + Shift + [0-9] --
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT +" .. key, hl.dsp.window.move({ workspace = i }))
end
-- Switch to Workspaces on SECONDARY monitor with mainMod + TAB + [0-9]
-- Move active window to a workspace on SECONDARY monitor with mainMod + SHIFT + TAB + [0-9]
for i=1, 10 do
    local key = i % 10 -- 10 remaps to key 0
    hl.bind(mainMod .. "+ TAB +" .. key, hl.dsp.focus({workspace = (i+10)}))
    hl.bind(mainMod .. "+ SHIFT + TAB +" .. key, hl.dsp.window.move({workspace = (i+10)}))
end
-- Scroll through workspaces with mainMod + scroll wheel --

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1"}))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({workspace = "e-1"}))

-- Move and Resize windows with mainMod + LMB/RMB and dragging --

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), {mouse = true})
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), {mouse = true})

------------------------------------
--Application Shortcut Keybindings--
------------------------------------

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(launcher))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(ide))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd(textEditor))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("hyprpicker -n --output-format=hex -a"))
hl.bind("CTRL + ALT + DELETE", hl.dsp.exec_cmd(shutDown))
hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m output"))
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m region"))

-----------------------------------
------- Multimedia Controls -------
-----------------------------------

-- Laptop multimedia keys for volume and LCD brightness, calls the quickshell IPC for displaying the audio OSD popup
hl.bind("XF86AudioRaiseVolume", function()
    hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+")
    hl.dsp.exec_cmd(audioOSD)
    {locked = true, repeating = true}
end)
hl.bind("XF86AudioLowerVolume", function()
    hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%-")
    hl.dsp.exec_cmd(audioOSD)
    {locked = true, repeating = true}
end)
hl.bind("XF86AudioMute", function()
    hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ toggle")
    hl.dsp.exec_cmd(audioOSD)
    {locked = true, repeating = true}
end)
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

---------------
---- Input ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})

-- Enable Natural Scrolling --
hl.config({
	input = {
		sensitivity = -0.9,
		touchpad = {
			natural_scroll = true,
			scroll_factor = 0.2,
			clickfinger_behavior = true
		}
	}
})

-- Magnify on Cursor --
local MAX_ZOOM = 3
local MIN_ZOOM = 1
local ZOOM_TOGGLE_FACTOR = 1.5

---@param offset number
---@return nil
local function zoom(offset)
    local current = hl.get_config("cursor.zoom_factor")
    if offset ~= nil then
        current = current + offset
    elseif current ~= MIN_ZOOM then
        current = MIN_ZOOM
    else
        current = ZOOM_TOGGLE_FACTOR
    end
    current = math.max(MIN_ZOOM, math.min(MAX_ZOOM, current))
    hl.config({ cursor = { zoom_factor = current } })
end

hl.bind("SUPER + Z", zoom)
hl.bind("SUPER + KP_ADD", function()
    zoom(0.5)
end)
hl.bind("SUPER + minus", function()
    zoom(-0.5)
end)
