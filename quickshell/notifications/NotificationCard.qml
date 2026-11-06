pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "../theme"
import "../services"

// One notification, used both as a popup and as a row in the center.
//   Left click   -> open it in its app
//   Right click  -> dismiss it
//   Action button -> run that action
// As a popup (popup: true) it also fades out after NotificationService.popupTimeout,
// pausing while hovered. A timed-out popup stays in the notification center.
Rectangle {
    id: card

    required property Notification notification
    property bool popup: false

    readonly property bool critical: notification.urgency === NotificationUrgency.Critical
    readonly property var actionButtons: Array.from(notification.actions)
        .filter(a => a.identifier !== "default")

    readonly property int pad: 12
    readonly property int iconSize: 40

    implicitWidth: 360
    implicitHeight: content.implicitHeight + pad * 2
    radius: Theme.barRadius
    color: Qt.alpha(Theme.bgPrimary, Theme.alphaBG)
    border.width: 1
    border.color: critical ? Theme.accentRed : (hover.hovered ? Theme.accentBlue : Theme.accentGray)

    // Fade out, then run `action`. Every way of leaving goes through here.
    property var pending: null
    function leave(action) {
        if (pending) return
        pending = action
        fadeOut.start()
    }

    NumberAnimation {
        id: fadeOut
        target: card
        property: "opacity"
        to: 0
        duration: Theme.animLong
        onFinished: {
            const action = card.pending
            if (action) action()
            // A resident notification survives being activated; in the center
            // the card is still there, so bring it back.
            if (!card.popup) {
                card.pending = null
                card.opacity = 1
            }
        }
    }

    NumberAnimation {
        id: fadeIn
        target: card
        property: "opacity"
        from: 0
        to: 1
        duration: Theme.animLong
    }
    Component.onCompleted: if (popup) fadeIn.start()

    // Popup timeout ---------------------------------------------------------
    Timer {
        id: timeout
        interval: NotificationService.popupTimeout
        running: card.popup
                 && !hover.hovered
                 && card.pending === null
                 && !(card.critical && NotificationService.criticalSticky)
        onTriggered: {
            const n = card.notification
            card.leave(() => NotificationService.hidePopup(n))
        }
    }

    // An app updating its notification in place (progress, now playing, ...)
    // starts the timeout over.
    Connections {
        target: card.notification
        function onSummaryChanged() { if (timeout.running) timeout.restart() }
        function onBodyChanged()    { if (timeout.running) timeout.restart() }
    }

    HoverHandler { id: hover }

    // Click anywhere on the card (action buttons sit above this and take
    // their own left clicks).
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            const n = card.notification
            if (mouse.button === Qt.RightButton)
                card.leave(() => NotificationService.dismiss(n))
            else
                card.leave(() => NotificationService.activate(n))
        }
    }

    // Content ----------------------------------------------------------------
    Item {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: card.pad
        implicitHeight: Math.max(card.iconSize, textColumn.implicitHeight)

        // Image (e.g. a contact's picture), else the app icon, else a bell.
        Item {
            id: iconBox
            width: card.iconSize
            height: card.iconSize

            readonly property string image: card.notification.image
            readonly property string appIcon: card.notification.appIcon

            Image {
                anchors.fill: parent
                visible: iconBox.image !== ""
                source: iconBox.image
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: card.iconSize * 2
                sourceSize.height: card.iconSize * 2
                asynchronous: true
            }

            IconImage {
                anchors.fill: parent
                visible: iconBox.image === "" && iconBox.appIcon !== ""
                source: {
                    const icon = iconBox.appIcon
                    if (icon === "") return ""
                    if (icon.startsWith("/")) return "file://" + icon
                    if (icon.includes("://")) return icon
                    return Quickshell.iconPath(icon, "dialog-information")
                }
            }

            Text {
                anchors.centerIn: parent
                visible: iconBox.image === "" && iconBox.appIcon === ""
                text: "󰂚"
                color: card.critical ? Theme.highlightRed : Theme.highlightBlue
                font.family: Theme.fontFamily
                font.pointSize: Theme.fontSizeHeader
            }
        }

        Column {
            id: textColumn

            anchors.left: iconBox.right
            anchors.leftMargin: card.pad
            anchors.right: parent.right
            spacing: 2

            // App name and arrival time
            Item {
                width: parent.width
                height: appName.implicitHeight

                Text {
                    id: appName
                    anchors.left: parent.left
                    anchors.right: time.left
                    anchors.rightMargin: 8
                    elide: Text.ElideRight
                    text: card.notification.appName
                    color: Theme.textBg
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.fontSizeSmall
                }

                Text {
                    id: time
                    anchors.right: parent.right
                    text: NotificationService.timeOf(card.notification)
                    color: Theme.textBg
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.fontSizeSmall
                }
            }

            Text {
                width: parent.width
                text: card.notification.summary
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                color: card.critical ? Theme.highlightRed : Theme.textPrimary
                font.family: Theme.fontFamily
                font.pointSize: Theme.fontSizePrimary
                font.bold: true
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: card.notification.body
                // StyledText handles the spec's <b>/<i>/<u> markup without
                // fetching remote images or running anything.
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: card.popup ? 4 : 8
                elide: Text.ElideRight
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pointSize: Theme.fontSizeSmall
            }

            // Action buttons (Reply, Mark as read, ...). "default" is the
            // card click itself, so it isn't shown here.
            Flow {
                width: parent.width
                topPadding: 6
                spacing: 6
                visible: card.actionButtons.length > 0

                Repeater {
                    model: card.actionButtons

                    delegate: Rectangle {
                        id: actionButton

                        required property var modelData

                        width: label.implicitWidth + 20
                        height: label.implicitHeight + 8
                        radius: Theme.barButtonRadius
                        color: actionMouse.containsMouse ? Theme.selectionBg : Theme.bgModule

                        Text {
                            id: label
                            anchors.centerIn: parent
                            text: actionButton.modelData.text
                            color: actionMouse.containsMouse ? Theme.selectionFg : Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.fontSizeSmall
                        }

                        MouseArea {
                            id: actionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            // Left only: a right click falls through to the card and dismisses.
                            acceptedButtons: Qt.LeftButton
                            onClicked: {
                                const n = card.notification
                                const action = actionButton.modelData
                                card.leave(() => NotificationService.invokeAction(n, action))
                            }
                        }
                    }
                }
            }
        }
    }
}
