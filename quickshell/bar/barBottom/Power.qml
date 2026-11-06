import QtQuick
import Quickshell
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
    font.family: Theme.fontFamily
    font.pointSize: Theme.fontSizePrimary

    text: hovered && PowerService.hasBattery ? PowerService.percent : PowerService.glyph
    color: hovered ? Theme.highlightBlue
         : PowerService.hasBattery ? PowerService.levelColor
         : Theme.textPrimary

    Component {
        id: flyoutComponent
        PowerFlyout {}
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: QsWindow.window.toggleFlyout(root, flyoutComponent)
    }
}
