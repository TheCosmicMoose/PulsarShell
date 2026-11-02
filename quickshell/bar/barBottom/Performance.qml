import QtQuick
import Quickshell
import "../../theme"

Column {
    id: root

    spacing: Theme.barSpacing

    CpuMeter {}
    MemMeter {}
}
