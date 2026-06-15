-- ~/.config/hypr/hyprland.lua
-- Main Hyprland Configuration using Lua (v0.55+) for ChrisplaysXD's imperative-dots config

--------------------------------------------------------------------------------------
-- ◈ INITIAL CONFIG & SYSTEM REQUIRE
--------------------------------------------------------------------------------------

------------------
---- MONITORS ----
------------------
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "1.0",
})

-------------------------
---- ENVS & VARIABLES ---
-------------------------
local mainMod  = "SUPER"
local terminal = "kitty"
local script_dir = "/home/chrisplaysxd/.config/hypr/scripts"

-- Environment Variables
hl.env("NIXOS_OZONE_WL", "1")
hl.env("XDG_PICTURES_DIR", "/home/chrisplaysxd/Pictures")
hl.env("XDG_VIDEOS_DIR", "/home/chrisplaysxd/Videos")
hl.env("WALLPAPER_DIR", "/home/chrisplaysxd/Pictures/Wallpapers")
hl.env("SCRIPT_DIR", script_dir)
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- Hardware Injections
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("__NV_PRIME_RENDER_OFFLOAD", "1")
hl.env("__NV_PRIME_RENDER_OFFLOAD_PROVIDER", "NVIDIA-G0")
hl.env("__GL_GSYNC_ALLOWED", "0")
hl.env("__GL_VRR_ALLOWED", "0")
hl.env("__GL_SHADER_DISK_CACHE", "1")
hl.env("__GL_SHADER_DISK_CACHE_PATH", "/home/chrisplaysxd/.cache/nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("LIBVA_DRIVER_NAME", "nvidia")

-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function ()
    -- System environment updates for DBus and Systemd
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DISPLAY")
    
    -- Unlock GNOME Keyring automatically
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets,pkcs11,ssh")
    
    -- Services & Daemons
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("hypridle")
    
    -- Launch Quickshell shell component
    hl.exec_cmd("quickshell -p ~/.config/hypr/scripts/quickshell/Shell.qml")
    
    -- Helper processes & utilities
    hl.exec_cmd("~/.config/hypr/scripts/quickshell/focustime/launch_daemon.sh")
    hl.exec_cmd(script_dir .. "/init.sh")
    hl.exec_cmd(script_dir .. "/settings_watcher.sh &")
    hl.exec_cmd("playerctld")
    hl.exec_cmd("swayosd-server --top-margin 0.9 --style \"$HOME/.config/swayosd/style.css\"")
    
    -- Clipboard services
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    
    -- Listeners
    hl.exec_cmd(script_dir .. "/volume_listener.sh")
    hl.exec_cmd(script_dir .. "/update_notifier.sh")
    
    -- Launch start guide
    hl.exec_cmd("bash -c 'sleep 1 && " .. script_dir .. "/qs_manager.sh toggle guide'")
end)

------------------------
---- LOOK AND FEEL -----
------------------------
local function load_colors()
    local active = "rgba(b3c5ffee)"
    local inactive = "rgba(324478aa)"
    local file = io.open(os.getenv("HOME") .. "/.config/hypr/colors.conf", "r")
    if file then
        for line in file:lines() do
            local act_val = line:match("%$active_border%s*=%s*(rgba%((%x+)%))")
            if act_val then
                active = act_val
            end
            local inact_val = line:match("%$inactive_border%s*=%s*(rgba%((%x+)%))")
            if inact_val then
                inactive = inact_val
            end
        end
        file:close()
    end
    return active, inactive
end

local active_color, inactive_color = load_colors()

hl.config({
    general = {
        border_size = 2,
        gaps_in  = 4,
        gaps_out = 4,
        float_gaps = 6,
        resize_on_border = true,
        extend_border_grab_area = 30,
        col = {
            active_border   = active_color,
            inactive_border = inactive_color,
        },
        layout = "dwindle",
    },

    decoration = {
        rounding       = 4,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        
        blur = {
            enabled   = true,
            size      = 8,
            passes    = 2,
            new_optimizations = true,
        },
        
        shadow = {
            enabled = false,
        },
    },

    input = {
        kb_layout = "us",
        kb_options = "",
        touchpad = {
            natural_scroll = true,
        },
    },

    cursor = {
        no_warps = true,
    },

    misc = {
        font_family = "JetBrains Mono",
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
    },

    ecosystem = {
        no_update_news = true,
        no_donation_nag = true,
    },

    dwindle = {
        preserve_split = true,
    },
})

--------------------
---- ANIMATIONS ----
--------------------
hl.curve("myBezier", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })

hl.animation({ leaf = "windows",     enabled = true, speed = 5, bezier = "myBezier", style = "popin 80%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 5, bezier = "myBezier", style = "popin 80%" })
hl.animation({ leaf = "layers",      enabled = true, speed = 5, bezier = "myBezier", style = "fade" })
hl.animation({ leaf = "layersIn",    enabled = true, speed = 5, bezier = "myBezier", style = "fade" })
hl.animation({ leaf = "layersOut",   enabled = true, speed = 5, bezier = "myBezier", style = "fade" })
hl.animation({ leaf = "fade",        enabled = true, speed = 5, bezier = "myBezier" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 5, bezier = "myBezier", style = "slide" })
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 5, bezier = "myBezier", style = "fade" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 5, bezier = "myBezier", style = "fade" })

----------------------
---- LAYER RULES -----
----------------------
hl.layer_rule({ name = "lr1", match = { namespace = "^(volume_osd)$" }, no_anim = true })
hl.layer_rule({ name = "lr2", match = { namespace = "^(brightness_osd)$" }, no_anim = true })
hl.layer_rule({ name = "lr3", match = { namespace = "hyprpicker" }, no_anim = true })
hl.layer_rule({ name = "lr4", match = { namespace = "qsdock" }, no_anim = true })
hl.layer_rule({ name = "lr5", match = { namespace = "ext-session-lock" }, blur = true, ignore_alpha = 0.2 })

-----------------------
---- WINDOW RULES -----
-----------------------
hl.window_rule({
    name  = "app_launcher",
    match = { title = "^(app-launcher)$" },
    float = true,
    center = true,
    size = "1200 600",
    animation = "slide",
})

hl.window_rule({
    name  = "master_rule",
    match = { title = "^(qs-master)$" },
    float = true,
    no_shadow = true,
    no_initial_focus = true,
})

-----------------------
---- KEYBINDINGS ------
-----------------------

-- Mouse Gestures & Window drag/resize
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

-- Window Management
hl.bind("ALT + F4", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))

-- Resize keys
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }),  { repeating = true })
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.resize({ x = 0, y = 50, relative = true }),  { repeating = true })

-- Move keys
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.move({ direction = "d" }))

-- Focus keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Applications & Shell Binds
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("nautilus"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("bash " .. script_dir .. "/reload.sh"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("bash " .. script_dir .. "/qs_manager.sh toggle clipboard"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("bash " .. script_dir .. "/qs_manager.sh toggle movies"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("bash " .. script_dir .. "/qs_manager.sh toggle applauncher"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("bash " .. script_dir .. "/qs_manager.sh toggle settings"))
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("bash " .. script_dir .. "/qs_manager.sh toggle music"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("bash " .. script_dir .. "/qs_manager.sh toggle battery"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("bash " .. script_dir .. "/qs_manager.sh toggle wallpaper"))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("bash " .. script_dir .. "/qs_manager.sh toggle calendar"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("bash " .. script_dir .. "/qs_manager.sh toggle network"))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("bash " .. script_dir .. "/qs_manager.sh toggle focustime"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("bash " .. script_dir .. "/qs_manager.sh toggle volume"))
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd("bash " .. script_dir .. "/qs_manager.sh toggle guide"))

-- System & Hardware controls
hl.bind("Caps_Lock", hl.dsp.exec_cmd("sleep 0.1 && swayosd-client --caps-lock"), { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"), { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("swayosd-client --brightness raise"), { locked = true })
hl.bind("Print",                 hl.dsp.exec_cmd(script_dir .. "/screenshot.sh"), { locked = true })
hl.bind("SHIFT + Print",         hl.dsp.exec_cmd(script_dir .. "/screenshot.sh --edit"), { locked = true })
hl.bind(mainMod .. " + Print",         hl.dsp.exec_cmd(script_dir .. "/screenshot.sh --full"), { locked = true })
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd(script_dir .. "/screenshot.sh --full --edit"), { locked = true })
hl.bind("XF86PowerOff",          hl.dsp.exec_cmd("bash " .. script_dir .. "/lock.sh"), { locked = true })
hl.bind(mainMod .. " + L",       hl.dsp.exec_cmd("bash " .. script_dir .. "/lock.sh"), { locked = true })

-- Media & Audio Controls
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause",      hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",       hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("xf86AudioMicMute",    hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"), { locked = true })
hl.bind("xf86audiomute",       hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true })
hl.bind("xf86audiolowervolume",hl.dsp.exec_cmd("swayosd-client --output-volume lower"), { locked = true, repeating = true })
hl.bind("xf86audioraisevolume",hl.dsp.exec_cmd("swayosd-client --output-volume raise"), { locked = true, repeating = true })

-- Workspaces
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd(script_dir .. "/focus_next_monitor.sh"))
