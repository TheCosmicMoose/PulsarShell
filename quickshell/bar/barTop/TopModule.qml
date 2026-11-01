import Quickshell
import QtQuick
import "../../theme"

Column {
    id:     root

    width:          Theme.barThickness
    height:         LauncherButton.height + Workspaces.height + Theme.barSpacing
    spacing:        Theme.barSpacing
    topPadding:     Theme.vertPadding
    leftPadding:    Theme.horizontalPadding

    LauncherButton {}
    Workspaces { screen: modelData }
}
