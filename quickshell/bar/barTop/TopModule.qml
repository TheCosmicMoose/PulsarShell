import Quickshell
import QtQuick
import "../../theme"

// Top section of the left-edge bar. The bar window is created once per
// monitor (Variants over Quickshell.screens), so it must hand this module the
// screen it lives on:
//
//   Variants {
//       model: Quickshell.screens
//       PanelWindow {
//           required property var modelData
//           screen: modelData
//           TopModule { screen: modelData }
//       }
//   }
Column {
    id:     root

    // The monitor this bar is on; forwarded to Workspaces.
    required property ShellScreen screen

    // Column sizes its height from its children, padding and spacing.
    width:          Theme.barThickness
    spacing:        Theme.barSpacing
    topPadding:     Theme.vertPadding
    // Center barButtonWidth-wide items in the bar.
    leftPadding:    (Theme.barThickness - Theme.barButtonWidth) / 2

    LauncherButton {}
    Workspaces { screen: root.screen }
}
