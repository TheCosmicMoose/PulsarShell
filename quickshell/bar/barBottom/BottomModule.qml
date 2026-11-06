import Quickshell
import QtQuick
import "../../theme"

Column {
    id:     root

    width:          Theme.barThickness
    spacing:        Theme.barSpacing
    topPadding:     Theme.vertPadding
    leftPadding:    Theme.horizontalPadding

    Performance {}
    Audio {}
    Bluetooth {}
    Networking {}
}
