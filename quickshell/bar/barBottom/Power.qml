import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../theme"
import "../../services"
import "../../flyouts"

// Power indicator: battery level and charging state on machines with a
// battery (the percentage while hovered), a power button glyph otherwise.
// Click to open the power flyout.
Text {
    id: root

    readonly property bool hovered: mouse.containsMouse

    width: Theme.barButtonWidth
    horizontalAlignment: Text.AlignHCenter
    font.family: Theme.fontFamilyAlt
    font.pointSize: Theme.fontSizePrimary

    text: hovered && PowerService.hasBattery ? PowerService.percent : PowerService.glyph
    color: hovered ? Theme.highlightBlue
         : PowerService.hasBattery ? PowerService.levelColor
         : Theme.textPrimary

    Component {
        id: flyoutComponent
        PowerFlyout {}
    }

    // `qs ipc call power toggle` (Ctrl+Alt+Delete): only the bar on the focused
    // monitor responds.
    Connections {
        target: PowerService
        function onFlyoutRequested() {
            if (Hyprland.focusedMonitor?.name === QsWindow.window?.screen?.name)
                QsWindow.window.toggleFlyout(root, flyoutComponent)
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: QsWindow.window.toggleFlyout(root, flyoutComponent)
    }
}
