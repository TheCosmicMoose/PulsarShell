import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../../theme"
import "../../flyouts"
import "../../services"

Text {
    id: root
    width: Theme.barButtonWidth
    horizontalAlignment: Text.AlignHCenter

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
        onClicked: QsWindow.window.toggleFlyout(root, flyoutComponent)
    }

    // Click to open the audio flyout beside this icon.
    Component {
        id: flyoutComponent
        AudioFlyout {}
    }
}
