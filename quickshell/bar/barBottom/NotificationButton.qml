pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../theme"
import "../../services"
import "../../notifications"

// Notification center button. Click to open the center in the bar's flyout.
// It also hosts the popup stack: new notifications appear beside this button
// on the focused monitor's bar, growing upward from it.
Text {
    id: root

    readonly property int count: NotificationService.count
    readonly property bool hovered: mouse.containsMouse

    // The bar this button is in (QsWindow.window is the containing window).
    readonly property var bar: QsWindow.window
    readonly property bool onFocusedScreen: !!root.bar?.screen
        && Hyprland.focusedMonitor?.name === root.bar.screen.name

    width: Theme.barButtonWidth
    horizontalAlignment: Text.AlignHCenter
    font.family: Theme.fontFamilyAlt
    font.pointSize: Theme.fontSizePrimary
    color: hovered ? Theme.highlightBlue
         : count > 0 ? Theme.textPrimary
         : Theme.textBg
    text: count > 0 ? "󰂞" : "󰂜"

    // Unread count badge
    Rectangle {
        visible: root.count > 0
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.rightMargin: 4
        width: Math.max(height, badgeText.implicitWidth + 6)
        height: badgeText.implicitHeight + 2
        radius: height / 2
        color: Theme.accentRed

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: root.count > 99 ? "99+" : root.count
            color: Theme.textPrimary
            font.family: Theme.fontFamilyAlt
            font.pointSize: Math.max(6, Theme.fontSizeSmall - 3)
            font.bold: true
        }
    }

    Component {
        id: centerComponent
        NotificationCenter {}
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            // Everything is in the center now, so drop the popups.
            NotificationService.clearPopups()
            root.bar.toggleFlyout(root, centerComponent)
        }
    }

    // Popup stack --------------------------------------------------------------
    PopupWindow {
        id: popups

        visible: NotificationService.popups.length > 0
                 && root.onFocusedScreen
                 && !(root.bar?.flyoutOpen ?? false)
        color: "transparent"
        implicitWidth: 360
        implicitHeight: Math.max(1, stack.implicitHeight)

        // Attach just past the bar's right edge, level with the bottom of this
        // button, and grow up and to the right from there.
        anchor.window: root.bar
        anchor.edges: Edges.Left
        anchor.gravity: Edges.Right | Edges.Top
        anchor.adjustment: PopupAdjustment.Slide

        // Re-anchor when popups are added or removed so the stack's bottom
        // stays level with the button.
        onImplicitHeightChanged: if (visible) anchor.updateAnchor()

        Column {
            id: stack
            width: parent.width
            spacing: Theme.barSpacing

            Repeater {
                // Oldest at the top, newest at the bottom next to the button.
                model: ScriptModel {
                    values: NotificationService.popups
                }

                delegate: NotificationCard {
                    required property var modelData
                    notification: modelData
                    popup: true
                    width: stack.width
                }
            }
        }
    }

    Connections {
        target: popups.anchor

        function onAnchoring() {
            if (!root.bar) return
            const p = root.mapToItem(root.bar.contentItem, 0, root.height)
            popups.anchor.rect.x = root.bar.width + Theme.edgeMargin
            popups.anchor.rect.y = p.y
        }
    }
}
