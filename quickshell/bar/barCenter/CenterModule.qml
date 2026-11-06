import Quickshell
import QtQuick
import "../../theme"

Column {
    id:     root

    width:          Theme.barThickness
    spacing:        Theme.barSpacing
    // Center barButtonWidth-wide items in the bar.
    leftPadding:    (Theme.barThickness - Theme.barButtonWidth) / 2

    Clock {}
    Weather {}
}
