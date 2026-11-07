import Quickshell
import QtQuick
import "../../theme"

Column {
    id:     root

    width:          Theme.barThickness
    spacing:        Theme.barSpacing
    // Every item is centered on the bar (see below), whatever its width.

    Clock { anchors.horizontalCenter: parent.horizontalCenter }
    Weather { anchors.horizontalCenter: parent.horizontalCenter }
}
