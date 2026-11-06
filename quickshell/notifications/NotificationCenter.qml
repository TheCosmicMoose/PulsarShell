pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../theme"
import "../services"

// Contents of the notification center flyout: every notification not yet
// interacted with, newest first. Shown in the bar's shared flyout by
// NotificationButton.
Column {
    id: root

    property int panelWidth: 380
    // Past this the list scrolls.
    property int maxListHeight: 640

    spacing: Theme.barSpacing

    // Header -----------------------------------------------------------------
    Item {
        width: root.panelWidth
        height: title.implicitHeight

        Text {
            id: title
            anchors.left: parent.left
            text: "Notifications" + (NotificationService.count > 0 ? "  " + NotificationService.count : "")
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pointSize: Theme.fontSizeLarge
            font.bold: true
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: title.verticalCenter
            visible: NotificationService.count > 0
            text: "Clear all"
            color: clearMouse.containsMouse ? Theme.highlightRed : Theme.textBg
            font.family: Theme.fontFamily
            font.pointSize: Theme.fontSizeSmall

            MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: NotificationService.clearAll()
            }
        }
    }

    // List -------------------------------------------------------------------
    ListView {
        id: list

        width: root.panelWidth
        height: Math.min(contentHeight, root.maxListHeight)
        visible: NotificationService.count > 0
        clip: true
        spacing: Theme.barSpacing
        boundsBehavior: Flickable.StopAtBounds

        // ScriptModel keeps existing cards (and their state) when the list changes.
        model: ScriptModel {
            values: NotificationService.list
        }

        delegate: NotificationCard {
            required property var modelData
            notification: modelData
            width: list.width
        }
    }

    Text {
        width: root.panelWidth
        visible: NotificationService.count === 0
        topPadding: 12
        bottomPadding: 12
        horizontalAlignment: Text.AlignHCenter
        text: "No new notifications"
        color: Theme.textBg
        font.family: Theme.fontFamily
        font.pointSize: Theme.fontSizePrimary
    }
}
