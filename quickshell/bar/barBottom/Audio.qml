import QtQuick
import Quickshell.Services.Pipewire
import "../../theme"
import "../../services"

Text {
    id: root
    width: Theme.barButtonWidth
    horizontalAlignment: text.AlignHCenter

    color: Theme.textPrimary
    font.family: Theme.fontFamily
    font.pointSize: Theme.fontSizePrimary

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }
    readonly property bool hovered: mouse.containsMouse
    text: hovered ? AudioService.deviceIcon : AudioService.audioIcon

    MouseArea {
        id: mouse
        hoverEnabled: true
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
    }
}
