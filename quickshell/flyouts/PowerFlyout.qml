pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../theme"
import "../services"
import "common"

// Power flyout:
//   "Power" header
//   battery (only on machines with one): level, charge state, time estimate, bar
//   power profile buttons (if power-profiles-daemon is installed)
//   Shutdown / Suspend / Reboot / Log off
// Session buttons need a second click within 3 seconds, so a stray click
// can't shut the machine down.
Column {
    id: root

    readonly property int panelWidth: 400

    spacing: Theme.barSpacing + 2

    FlyoutHeader {
        width: root.panelWidth
        title: "Power"
        showToggle: false
    }

    // Battery -------------------------------------------------------------------------
    Column {
        width: root.panelWidth
        spacing: 6
        visible: PowerService.hasBattery

        Item {
            width: parent.width
            height: batteryLabel.implicitHeight

            Text {
                id: batteryLabel
                anchors.left: parent.left
                text: "Battery"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pointSize: Theme.fontSizePrimary
                font.bold: true
            }

            Text {
                anchors.right: parent.right
                text: PowerService.percent + "%"
                color: PowerService.levelColor
                font.family: Theme.fontFamily
                font.pointSize: Theme.fontSizePrimary
                font.bold: true
            }
        }

        Item {
            width: parent.width
            height: stateLabel.implicitHeight

            Text {
                id: stateLabel
                anchors.left: parent.left
                text: PowerService.stateText
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pointSize: Theme.fontSizeSmall
            }

            Text {
                anchors.right: parent.right
                text: PowerService.timeText
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pointSize: Theme.fontSizeSmall
            }
        }

        // Charge level bar
        Rectangle {
            width: parent.width
            height: 8
            radius: height / 2
            color: Theme.bgModule

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, PowerService.level))
                height: parent.height
                radius: parent.radius
                color: PowerService.levelColor === Theme.textPrimary ? Theme.accentBlue : PowerService.levelColor

                Behavior on width { NumberAnimation { duration: Theme.animLong } }
            }
        }
    }

    Divider { visible: PowerService.hasBattery && PowerService.profilesAvailable }

    // Power profiles -------------------------------------------------------------------
    Column {
        width: root.panelWidth
        spacing: 6
        visible: PowerService.profilesAvailable

        SectionLabel {
            width: parent.width
            text: "Power profile"
        }

        Row {
            id: profileRow

            readonly property var profiles: PowerProfiles.hasPerformanceProfile
                ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
                : [PowerProfile.PowerSaver, PowerProfile.Balanced]

            width: parent.width
            spacing: 8

            Repeater {
                model: profileRow.profiles

                delegate: IconButton {
                    required property int modelData

                    width: (profileRow.width - profileRow.spacing * (profileRow.profiles.length - 1)) / profileRow.profiles.length
                    active: PowerProfiles.profile === modelData
                    accent: modelData === PowerProfile.PowerSaver ? Theme.accentGreen
                          : modelData === PowerProfile.Performance ? Theme.accentOrange
                          : Theme.accentBlue
                    icon: modelData === PowerProfile.PowerSaver ? "󰌪"       // leaf
                        : modelData === PowerProfile.Performance ? "󰓅"      // speedometer
                        : "󰗑"                                               // scale
                    text: modelData === PowerProfile.PowerSaver ? "Power Saver"
                        : modelData === PowerProfile.Performance ? "Performance"
                        : "Balanced"
                    onClicked: PowerProfiles.profile = modelData
                }
            }
        }
    }

    Divider { visible: PowerService.hasBattery || PowerService.profilesAvailable }

    // Session actions ------------------------------------------------------------------
    Row {
        id: sessionRow

        // The action waiting for its confirming second click.
        property string armed: ""

        width: root.panelWidth
        spacing: 8

        Timer {
            id: disarm
            interval: 3000
            onTriggered: sessionRow.armed = ""
        }

        Repeater {
            model: [
                { id: "shutdown", icon: "󰐥", text: "Shutdown" },
                { id: "suspend",  icon: "󰒲", text: "Suspend" },
                { id: "reboot",   icon: "󰜉", text: "Reboot" },
                { id: "logout",   icon: "󰍃", text: "Log off" }
            ]

            delegate: IconButton {
                required property var modelData
                readonly property bool isArmed: sessionRow.armed === modelData.id

                width: (sessionRow.width - sessionRow.spacing * 3) / 4
                icon: modelData.icon
                text: isArmed ? "Confirm?" : modelData.text
                accent: modelData.id === "shutdown" || modelData.id === "reboot" ? Theme.accentRed : Theme.accentBlue
                active: isArmed

                onClicked: {
                    if (!isArmed) {
                        sessionRow.armed = modelData.id
                        disarm.restart()
                        return
                    }
                    sessionRow.armed = ""
                    QsWindow.window.visible = false     // close the flyout
                    switch (modelData.id) {
                    case "shutdown": PowerService.shutdown(); break
                    case "suspend":  PowerService.suspend();  break
                    case "reboot":   PowerService.reboot();   break
                    case "logout":   PowerService.logout();   break
                    }
                }
            }
        }
    }

    component Divider: Rectangle {
        width: root.panelWidth
        height: 1
        color: Theme.accentGray
        opacity: 0.6
    }
}
