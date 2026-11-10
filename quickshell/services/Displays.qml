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
//
// Changing them (used by the launcher's System tab):
//   Displays.refreshMonitors()   -> fills Displays.monitors from `hyprctl -j monitors`
//   Displays.apply(main, secondary) -> rewrites rules.lua with pulsar-display
//                                      (secondary may be ""), then notifies
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

    // Connected monitors ------------------------------------------------------
    // [{ name, description, width, height, refresh, scale, focused }]
    property var monitors: []
    property bool monitorsReady: false
    signal monitorsLoaded()

    function refreshMonitors() {
        monitorsReady = false
        monitorsProc.running = true
    }

    Process {
        id: monitorsProc
        command: ["hyprctl", "-j", "monitors"]
        stdout: StdioCollector {
            onStreamFinished: {
                let list = []
                try {
                    list = JSON.parse(text)
                        .filter(m => !m.disabled)
                        .map(m => ({
                            name: m.name,
                            description: (m.description ?? "").trim(),
                            width: m.width,
                            height: m.height,
                            refresh: Math.round(m.refreshRate ?? 0),
                            scale: m.scale ?? 1,
                            focused: m.focused ?? false
                        }))
                } catch (e) {
                    console.warn("Displays: couldn't read hyprctl monitors:", e)
                }
                root.monitors = list
                root.monitorsReady = true
                root.monitorsLoaded()
            }
        }
    }

    // Setting roles ----------------------------------------------------------------
    readonly property string displayBin: Quickshell.env("HOME") + "/.local/bin/pulsar-display"

    function apply(mainName, secondaryName) {
        applyProc.mainName = mainName
        applyProc.secondaryName = secondaryName || ""
        applyProc.command = [displayBin, "-newMain", mainName, "-newSec", secondaryName || ""]
        applyProc.running = true
    }

    Process {
        id: applyProc
        property string mainName: ""
        property string secondaryName: ""
        stderr: StdioCollector { id: applyErr }
        onExited: code => {
            if (code === 0) {
                let body = applyProc.mainName + " has been set as your primary display"
                if (applyProc.secondaryName !== "")
                    body += ", and " + applyProc.secondaryName + " as your secondary display"
                Quickshell.execDetached(["notify-send", "-a", "Displays", "-i", "video-display",
                                         "Displays", body])
            } else {
                Quickshell.execDetached(["notify-send", "-a", "Displays", "-u", "critical",
                    "Couldn't change displays", applyErr.text.trim() || ("pulsar-display exited with " + code)])
            }
        }
    }

    FileView {
        id: file
        path: root.rulesPath
        blockLoading: true      // have the names ready before the bars are created
        watchChanges: true
        onFileChanged: reload()
    }
}
