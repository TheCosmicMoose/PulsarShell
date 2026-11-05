import Quickshell
import QtQuick
import "../../Theme"

Column {
    id:     root

        width:          Theme.barThickness
        height:         LauncherButton.height + Workspaces.height + Theme.barSpacing
        spacing:        Theme.barSpacing
        topPadding:     Theme.vertPadding
        leftPadding:    Theme.horizontalPadding

        Clock {}
        Weather {}
}
