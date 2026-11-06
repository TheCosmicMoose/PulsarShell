pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink ]
    }

    readonly property string errorIcon: "󱆶"
    readonly property var volumeIcons: ["", "", "", "", ""]
    readonly property var sink: Pipewire.defaultAudioSink
    // What kind of output a node is: "headphone", "speaker", "display",
    // "bluetooth", "other", or "" for no node. Looks at the node name plus its
    // description, so "Headphones" in either one counts.
    function typeOf(node) {
        if (!node) return ""
        const raw = ((node.name ?? "") + " " + (node.description ?? "")).toLowerCase()
        if (raw.includes("headphone") || raw.includes("headset")) return "headphone"
        if (raw.includes("speaker")) return "speaker"
        if (raw.includes("hdmi") || raw.includes("displayport")) return "display"
        if (raw.includes("bluez") || raw.includes("bluetooth")) return "bluetooth"
        return "other"
    }

    // Glyph for an output node (used by the bar icon and the audio flyout).
    function iconFor(node) {
        switch (typeOf(node)) {
        case "":          return errorIcon
        case "headphone": return ""
        case "speaker":   return "󰓃"
        case "display":   return "󰽟"
        case "bluetooth": return "󰂰"
        default:          return "󰤽"
        }
    }

    // Display name for an output node.
    function labelFor(node) {
        if (!node) return "No output"
        return node.description || node.nickname || node.name
    }

    readonly property string sinkType: typeOf(sink)
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real volume: sink?.audio?.volume ?? 0

    readonly property string audioIcon: {
        if (sinkType === "") return errorIcon
        if (muted) return volumeIcons[1]
        else return volumeIcons[Math.min(4, Math.floor(volume * 5))]
    }
    readonly property string deviceIcon: iconFor(sink)
}
