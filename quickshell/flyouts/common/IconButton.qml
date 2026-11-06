import QtQuick
import "../../theme"

// Button with a glyph and a label side by side ("<leaf> Power Saver").
// `active` marks the current choice (e.g. the selected power profile).
Rectangle {
    id: root

    property string icon: ""
    property string text: ""
    property bool active: false
    property color accent: Theme.accentBlue
    signal clicked()

    implicitWidth: content.implicitWidth + 20
    implicitHeight: content.implicitHeight + 14
    radius: Theme.barButtonRadius
    color: active ? accent : (mouse.containsMouse ? Theme.bgModule : "transparent")
    border.width: 1
    border.color: active || mouse.containsMouse ? accent : Theme.accentGray
    opacity: enabled ? 1 : 0.4

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: root.active ? Theme.bgPrimary : root.accent
            font.family: Theme.fontFamily
            font.pointSize: Theme.fontSizePrimary
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.active ? Theme.bgPrimary : Theme.textPrimary
            font.family: Theme.fontFamily
            font.pointSize: Theme.fontSizeSmall
            font.bold: root.active
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
