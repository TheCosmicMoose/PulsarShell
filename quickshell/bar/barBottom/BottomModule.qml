import Quickshell
import QtQuick
import "../../theme"

Column {
    id:     root

    width:          Theme.barThickness
    spacing:        Theme.barSpacing
    bottomPadding:  Theme.vertPadding
    // Center barButtonWidth-wide items in the bar.
    leftPadding:    (Theme.barThickness - Theme.barButtonWidth) / 2

    Performance {}
    Audio {}
    Bluetooth {}
    Networking {}
    NotificationButton {}
}
