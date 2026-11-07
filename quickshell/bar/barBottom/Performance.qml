import QtQuick
import Quickshell
import "../../theme"

Column {
    id: root

    spacing: Theme.barSpacing

    CpuMeter { anchors.horizontalCenter: parent.horizontalCenter }
    MemMeter { anchors.horizontalCenter: parent.horizontalCenter }
}
