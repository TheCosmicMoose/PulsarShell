pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../theme"
import "../../launcher"

Text {
    id: root

    text:               "󰀘"
    font.family:        Theme.fontFamily
    font.pointSize:     Theme.fontSizePrimary
    color:              Theme.textPrimary

    MouseArea {
        id: mouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Launcher.show()
    }
}
