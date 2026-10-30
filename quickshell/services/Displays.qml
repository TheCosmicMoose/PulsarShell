pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Reads the main and secondary display names out of rules.lua, so Hyprland's
// config stays the single source of truth for them.
//
// Usage anywhere in the shell:
//   Displays.main        -> "HDMI-A-1"
//   Displays.secondary   -> "DP-3"
//   Displays.roleOf(screen.name)  -> "main", "secondary", or "other"
Singleton {
    id: root

    // Adjust to wherever your rules.lua lives.
    readonly property string rulesPath: Quickshell.env("HOME") + "/.config/hypr/rules.lua"

    // Pull a quoted value out of a line like:  local mainDisplay = "HDMI-A-1"
    function extract(text, variable) {
        const re = new RegExp("local\\s+" + variable + "\\s*=\\s*\"([^\"]+)\"")
        const m = text.match(re)
        return m ? m[1] : ""
    }

    // text() behaves like a property: this binding re-runs when the file reloads.
    readonly property string main:      extract(file.text(), "mainDisplay")
    readonly property string secondary: extract(file.text(), "secondaryDisplay")

    function roleOf(screenName) {
        if (screenName === main)      return "main"
        if (screenName === secondary) return "secondary"
        return "other"
    }

    FileView {
        id: file
        path: root.rulesPath
        blockLoading: true      // have the names ready before the bars are created
        watchChanges: true
        onFileChanged: reload()
    }
}
