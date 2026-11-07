pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../theme"
import "../../launcher"

Text {
    id: root

    width:              Theme.barButtonWidth
    horizontalAlignment: Text.AlignHCenter
    text:               "󰀘"
    font.family:        Theme.fontFamilyAlt
    font.pointSize:     Theme.fontSizePrimary
    color:              Theme.textPrimary

    MouseArea {
        id: mouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Launcher.show()
    }
}
