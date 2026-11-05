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
    readonly property string sinkRaw: sink.name.toLowerCase()
    readonly property string sinkType: {
        if (!sink) return undefined
        if(sinkRaw.includes("headphone") || sinkRaw.includes("headset")) return "headphone"
        if(sinkRaw.includes("speaker")) return "speaker"
        if(sinkRaw.includes("hdmi") || sinkRaw.includes("displayport")) return "display"
        if(sinkRaw.includes("bluez") || sinkRaw.includes("bluetooth")) return "bluetooth"
        else return "other"
    }
    readonly property bool muted: Pipewire.defaultAudioSink?.audio.muted ?? false
    readonly property real volume: sink?.audio.volume ?? 0

    readonly property string audioIcon: {
        if (sinkType === undefined) return errorIcon
        if (muted) return volumeIcons[1]
        else return volumeIcons[Math.min(4, Math.floor(volume * 5))]
    }
    readonly property string deviceIcon: {
        if (sinkType === undefined) return errorIcon
        if (sinkType === "headphone") return ""
        if (sinkType === "speaker") return "󰓃"
        if (sinkType === "display") return "󰽟"
        if (sinkType === "bluetooth") return "󰂰"
        else return "󰤽"
    }
}
