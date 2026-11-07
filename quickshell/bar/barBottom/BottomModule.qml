import Quickshell
import QtQuick
import "../../theme"

Column {
    id:     root

    width:          Theme.barThickness
    spacing:        Theme.barSpacing
    bottomPadding:  Theme.vertPadding
    // Every item is centered on the bar (see below), whatever its width.

    Performance { anchors.horizontalCenter: parent.horizontalCenter }
    Audio { anchors.horizontalCenter: parent.horizontalCenter }
    BluetoothIndicator { anchors.horizontalCenter: parent.horizontalCenter }
    NetworkIndicator { anchors.horizontalCenter: parent.horizontalCenter }
    ThemeButton { anchors.horizontalCenter: parent.horizontalCenter }
    NotificationButton { anchors.horizontalCenter: parent.horizontalCenter }
    Power { anchors.horizontalCenter: parent.horizontalCenter }                // always last
}
