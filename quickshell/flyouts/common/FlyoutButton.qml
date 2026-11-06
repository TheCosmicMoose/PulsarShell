import QtQuick
import "../../theme"

// Small text button used inside flyout rows (Connect, Disconnect, ...).
Rectangle {
    id: root

    property string text: ""
    property color accent: Theme.accentBlue
    signal clicked()

    implicitWidth: label.implicitWidth + 24
    implicitHeight: label.implicitHeight + 10
    radius: Theme.barButtonRadius
    color: mouse.containsMouse ? accent : Theme.bgModule
    border.width: 1
    border.color: accent
    opacity: enabled ? 1 : 0.4

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: mouse.containsMouse ? Theme.bgPrimary : Theme.textPrimary
        font.family: Theme.fontFamily
        font.pointSize: Theme.fontSizeSmall
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
