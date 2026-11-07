import QtQuick
import "../../theme"

// On/off switch. It doesn't flip itself: clicking emits toggled() and the
// owner changes whatever `checked` is bound to, so the switch always shows
// the real state.
Rectangle {
    id: root

    property bool checked: false
    signal toggled()

    implicitWidth: 40
    implicitHeight: 22
    radius: 0
    color: checked ? Theme.accentBlue : Theme.bgModule
    border.width: 1
    border.color: checked ? Theme.accentBlue : Theme.accentGray
    opacity: enabled ? 1 : 0.4

    Behavior on color { ColorAnimation { duration: Theme.animDuration } }

    Rectangle {
        width: parent.height - 6
        height: width
        radius: 0
        y: 3
        x: root.checked ? parent.width - width - 3 : 3
        color: root.checked ? Theme.textPrimary : Theme.textBg

        Behavior on x { NumberAnimation { duration: Theme.animDuration } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
