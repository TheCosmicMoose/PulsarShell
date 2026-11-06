pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Wallpaper picker entry point. Open it by right-clicking the theme button,
// or bind a key to:
//     qs ipc call wallpaper toggle
//
// Wallpapers come from ~/Pictures/Wallpapers. Choosing one:
//   1. writes ~/.config/hypr/hyprpaper.conf so it's used at the next login,
//   2. switches the running hyprpaper with `hyprctl hyprpaper wallpaper`
//      (hyprpaper 0.8+), or starts hyprpaper if it isn't running.
Singleton {
    id: root

    readonly property string folder: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    readonly property string configPath: {
        const xdg = Quickshell.env("XDG_CONFIG_HOME")
        return (xdg ? xdg : Quickshell.env("HOME") + "/.config") + "/hypr/hyprpaper.conf"
    }

    property bool open: false
    property var targetScreen: null

    // The wallpaper in hyprpaper.conf ("" if none yet).
    readonly property string current: {
        const m = configFile.text().match(/^\s*path\s*=\s*(.+?)\s*$/m)
        return m ? m[1].replace(/##/g, "#") : ""
    }

    property string error: ""

    function show() {
        const name = Hyprland.focusedMonitor?.name
        targetScreen = Quickshell.screens.find(s => s.name === name) || Quickshell.screens[0]
        error = ""
        open = true
    }

    function hide() {
        open = false
    }

    function toggle() {
        if (open) hide()
        else show()
    }

    function apply(path) {
        if (!path) return
        error = ""
        applyProc.command = ["sh", "-c", root.applyScript, "sh", path, configPath]
        applyProc.running = true
        hide()
    }

    // $1 = image, $2 = hyprpaper.conf. In hyprlang a "#" starts a comment, so
    // it's written as "##". "*" means every monitor in the config file; on
    // the hyprctl command line an empty monitor means the same.
    readonly property string applyScript:
        'img="$1"; conf="$2"; mkdir -p "$(dirname "$conf")" || exit 1; ' +
        'esc=$(printf "%s" "$img" | sed "s/#/##/g"); ' +
        '{ echo "# Written by the Pulsar Shell wallpaper picker."; ' +
        '  echo "splash = 0"; echo "ipc = 1"; echo; ' +
        '  echo "wallpaper {"; echo "    monitor = *"; ' +
        '  echo "    path = $esc"; echo "    fit_mode = cover"; echo "}"; ' +
        '} > "$conf.tmp" && mv "$conf.tmp" "$conf" || exit 1; ' +
        'if pgrep -x hyprpaper >/dev/null; then ' +
        '  hyprctl hyprpaper wallpaper ",$img,cover" 2>&1; ' +
        'else ' +
        '  setsid -f hyprpaper >/dev/null 2>&1; ' +
        'fi'

    Process {
        id: applyProc
        stdout: StdioCollector { id: applyOut }
        onExited: code => {
            // hyprctl prints nothing on success, "error: ..." and exit 1 otherwise.
            const out = applyOut.text.trim()
            if (code !== 0) {
                root.error = out !== "" ? out : "Couldn't set the wallpaper (exit " + code + ")"
                console.warn("wallpaper:", root.error)
            }
        }
    }

    FileView {
        id: configFile
        path: root.configPath
        watchChanges: true
        onFileChanged: reload()
    }

    IpcHandler {
        target: "wallpaper"

        function toggle(): void { root.toggle() }
        function show(): void { root.show() }
        function hide(): void { root.hide() }
    }

    LazyLoader {
        active: root.open

        WallpaperWindow {
            screen: root.targetScreen
            onDismissed: root.hide()
            onChosen: path => root.apply(path)
        }
    }
}
