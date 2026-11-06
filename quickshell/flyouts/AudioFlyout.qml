pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../theme"
import "../services"
import "common"

// Audio flyout:
//   "Audio" header, switch = sound on (unmuted) / off (muted)
//   the current output with a volume slider
//   other outputs; click one to make it the default
Column {
    id: root

    readonly property int panelWidth: 320

    readonly property var sink: Pipewire.defaultAudioSink
    // Hardware outputs only (not app streams).
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    readonly property var otherSinks: sinks.filter(n => n !== sink)

    // Bind every output so names and volumes are live while the flyout is open.
    PwObjectTracker { objects: root.sinks }

    spacing: Theme.barSpacing

    FlyoutHeader {
        width: root.panelWidth
        title: "Audio"
        enabled: root.sink?.audio != null
        checked: !AudioService.muted
        onToggled: root.sink.audio.muted = !root.sink.audio.muted
    }

    // Current output ---------------------------------------------------------------
    Column {
        width: root.panelWidth
        spacing: 6
        visible: root.sink !== null

        Item {
            width: parent.width
            height: Math.max(sinkIcon.implicitHeight, sinkName.implicitHeight)

            Text {
                id: sinkIcon
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 24
                horizontalAlignment: Text.AlignHCenter
                text: AudioService.deviceIcon
                color: Theme.accentBlue
                font.family: Theme.fontFamily
                font.pointSize: Theme.fontSizeLarge
            }

            Text {
                id: sinkName
                anchors.left: sinkIcon.right
                anchors.leftMargin: 10
                anchors.right: percent.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                text: AudioService.labelFor(root.sink)
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pointSize: Theme.fontSizePrimary
                font.bold: true
            }

            Text {
                id: percent
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: AudioService.muted ? "Muted" : Math.round(AudioService.volume * 100) + "%"
                color: Theme.textBg
                font.family: Theme.fontFamily
                font.pointSize: Theme.fontSizeSmall
            }
        }

        ValueSlider {
            width: parent.width
            value: AudioService.volume
            fillColor: AudioService.muted ? Theme.accentGray : Theme.accentBlue
            onMoved: v => {
                if (!root.sink?.audio) return
                root.sink.audio.volume = v
                if (root.sink.audio.muted && v > 0) root.sink.audio.muted = false
            }
        }
    }

    Text {
        width: root.panelWidth
        visible: root.sink === null
        text: "No audio output found"
        color: Theme.textBg
        font.family: Theme.fontFamily
        font.pointSize: Theme.fontSizePrimary
    }

    // Other outputs ------------------------------------------------------------------
    SectionLabel {
        width: root.panelWidth
        visible: root.otherSinks.length > 0
        text: "Other outputs"
    }

    Repeater {
        model: ScriptModel { values: root.otherSinks }

        delegate: ListRow {
            required property var modelData

            width: root.panelWidth
            icon: AudioService.iconFor(modelData)
            title: AudioService.labelFor(modelData)
            onClicked: Pipewire.preferredDefaultAudioSink = modelData
        }
    }
}
