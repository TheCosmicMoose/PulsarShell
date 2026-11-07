pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../theme"
import "barTop"
import "barCenter"
import "barBottom"

// One bar per monitor, docked to the left edge. shell.qml creates these with
// Variants over Quickshell.screens, which fills in modelData.
//
// The bar also hosts a single shared flyout. Any item inside the bar can open
// it next to itself without being handed a reference to the bar:
//
//   Text {
//       id: icon
//       Component { id: myFlyout; MyFlyoutContent {} }
//       MouseArea {
//           anchors.fill: parent
//           onClicked: QsWindow.window.toggleFlyout(icon, myFlyout)
//       }
//   }
//
// Clicking the same icon again closes it, clicking another icon moves it, and
// clicking anywhere outside the bar or flyout closes it.
PanelWindow {
    id: bar

    required property ShellScreen modelData
    screen: modelData

    anchors {
        left: true
        top: true
        bottom: true
    }
    implicitWidth: Theme.barThickness
    color: "transparent"

    WlrLayershell.namespace: "pulsar-bar"
    // While a flyout is open, let it take the keyboard when clicked (for
    // password and PIN boxes). The rest of the time the bar never takes it.
    WlrLayershell.keyboardFocus: flyout.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Bar sections -----------------------------------------------------------
    TopModule {
        anchors.top: parent.top
        anchors.left: parent.left
        screen: bar.modelData
    }

    CenterModule {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
    }

    BottomModule {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
    }

    // Shared flyout ----------------------------------------------------------
    // The icon the flyout is attached to, and what it shows.
    property Item flyoutAnchor: null
    property Component flyoutContent: null
    readonly property bool flyoutOpen: flyout.visible

    function openFlyout(item, content) {
        flyoutAnchor = item
        flyoutContent = content
        if (flyout.visible) flyout.anchor.updateAnchor()   // move it to the new icon
        else flyout.visible = true
    }

    function closeFlyout() {
        flyout.visible = false
        flyoutAnchor = null
        flyoutContent = null
    }

    function toggleFlyout(item, content) {
        if (flyout.visible && flyoutAnchor === item) closeFlyout()
        else openFlyout(item, content)
    }

    PopupWindow {
        id: flyout

        visible: false
        color: "transparent"
        implicitWidth: Math.max(1, frame.implicitWidth)
        implicitHeight: Math.max(1, frame.implicitHeight)

        // Anchor to the bar window and work out the point ourselves (see the
        // Connections below), so the flyout sits just past the bar's right edge
        // rather than against the icon's own edge.
        anchor.window: bar
        anchor.edges: Edges.Left        // attach at the anchor point...
        anchor.gravity: Edges.Right     // ...and grow rightward, centered on it vertically
        anchor.adjustment: PopupAdjustment.Slide   // slide up/down to stay on screen

        // Content grows and shrinks (lists filling in, rows expanding); keep it
        // centered on the icon.
        onImplicitHeightChanged: if (visible) anchor.updateAnchor()

        // However it was hidden (outside click, a button inside it hiding its
        // window), unload the content so e.g. Bluetooth scanning stops.
        onVisibleChanged: if (!visible) {
            bar.flyoutAnchor = null
            bar.flyoutContent = null
        }

        Rectangle {
            id: frame

            anchors.fill: parent
            implicitWidth: loader.implicitWidth + Theme.horizontalPadding * 2
            implicitHeight: loader.implicitHeight + Theme.vertPadding * 2
            radius: Theme.barRadius
            color: Qt.alpha(Theme.bgPrimary, Theme.alphaBG)
            border.width: 1
            border.color: Theme.accentGray

            Loader {
                id: loader
                anchors.centerIn: parent
                sourceComponent: bar.flyoutContent
            }
        }
    }

    // Runs each time the flyout is shown or updateAnchor() is called.
    Connections {
        target: flyout.anchor

        function onAnchoring() {
            if (!bar.flyoutAnchor) return
            const p = bar.flyoutAnchor.mapToItem(bar.contentItem, 0, bar.flyoutAnchor.height / 2)
            flyout.anchor.rect.x = bar.width + Theme.edgeMargin
            flyout.anchor.rect.y = p.y
        }
    }

    // Close the flyout on clicks outside it. The bar is part of the grab so its
    // own icons still get clicks (letting them toggle or move the flyout).
    HyprlandFocusGrab {
        active: flyout.visible
        windows: [flyout, bar]
        onCleared: bar.closeFlyout()
    }
}
