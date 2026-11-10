pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

// "Set primary display" panel for the launcher's System tab (shown when more
// than one monitor is connected).
//
//   Up / Down      choose a monitor
//   Left / Right   change its role (Primary / Secondary / Other)
//   Enter          apply          Escape  back (handled by the System tab)
//
// There is always exactly one primary and at most one secondary; giving a
// role to a monitor swaps roles with the monitor that had it. While the panel
// is open, every monitor shows a label (name, resolution, role) where the
// audio OSD appears, so you can tell which is which.
Item {
    id: root

    // From Displays.monitors.
    required property var monitors
    signal applied()

    readonly property var roleNames: ["main", "secondary", "other"]
    readonly property var roleLabels: ({ main: "Primary", secondary: "Secondary", other: "Other" })

    // Role per monitor index, e.g. ["main", "other", "secondary"].
    property var roles: []
    property int selected: 0

    implicitWidth: 560
    implicitHeight: column.implicitHeight

    Component.onCompleted: {
        // Start from the current rules.lua; make sure there's a primary.
        let r = monitors.map(m => Displays.roleOf(m.name))
        if (!r.includes("main")) {
            const focused = monitors.findIndex(m => m.focused)
            r[focused >= 0 ? focused : 0] = "main"
        }
        // Only one secondary.
        let seenSecondary = false
        r = r.map(x => {
            if (x !== "secondary") return x
            if (seenSecondary) return "other"
            seenSecondary = true
            return x
        })
        roles = r
        selected = Math.max(0, r.indexOf("main"))
    }

    function setRole(i, role) {
        const r = roles.slice()
        const old = r[i]
        if (old === role) return
        // Swap with the monitor that had this role (primary/secondary are unique).
        if (role !== "other") {
            const holder = r.indexOf(role)
            if (holder >= 0) r[holder] = old
        }
        r[i] = role
        // Never leave the setup without a primary.
        if (!r.includes("main")) {
            const other = r.findIndex((x, j) => j !== i && x === "other")
            r[other >= 0 ? other : (i === 0 ? 1 : 0)] = "main"
        }
        roles = r
    }

    function cycleRole(i, step) {
        const cur = roleNames.indexOf(roles[i])
        setRole(i, roleNames[(cur + step + roleNames.length) % roleNames.length])
    }

    function apply() {
        const mainIdx = roles.indexOf("main")
        const secIdx = roles.indexOf("secondary")
        Displays.apply(monitors[mainIdx].name, secIdx >= 0 ? monitors[secIdx].name : "")
        applied()
    }

    // Keys forwarded by the launcher. Returns true when handled.
    function handleKey(event) {
        switch (event.key) {
        case Qt.Key_Up:    selected = Math.max(0, selected - 1); return true
        case Qt.Key_Down:  selected = Math.min(monitors.length - 1, selected + 1); return true
        case Qt.Key_Left:  cycleRole(selected, -1); return true
        case Qt.Key_Right: cycleRole(selected, 1); return true
        case Qt.Key_Return:
        case Qt.Key_Enter: apply(); return true
        }
        return false
    }

    function resolutionOf(m) {
        return m.width + "x" + m.height + (m.refresh ? " @ " + m.refresh + "Hz" : "")
    }

    Column {
        id: column
        width: parent.width
        spacing: 10

        Text {
            text: "Set primary display"
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pointSize: Theme.fontSizeLarge
            font.bold: true
        }

        Text {
            width: parent.width
            wrapMode: Text.Wrap
            text: "↑↓ choose a monitor   ←→ change its role   Enter apply   Esc back"
            color: Theme.textBg
            font.family: Theme.fontFamily
            font.pointSize: Theme.fontSizeSmall
        }

        Repeater {
            model: root.monitors

            delegate: Rectangle {
                id: monitorRow

                required property var modelData
                required property int index
                readonly property bool isSelected: root.selected === index

                width: column.width
                height: rowContent.implicitHeight + 20
                radius: Theme.barButtonRadius
                color: isSelected ? Theme.bgModule : "transparent"
                border.width: isSelected ? 2 : 1
                border.color: isSelected ? Theme.accentBlue : Theme.accentGray

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.selected = monitorRow.index
                }

                Item {
                    id: rowContent
                    x: 12
                    width: parent.width - 24
                    anchors.verticalCenter: parent.verticalCenter
                    implicitHeight: Math.max(info.implicitHeight, chips.implicitHeight)

                    Column {
                        id: info
                        anchors.left: parent.left
                        anchors.right: chips.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: monitorRow.modelData.name + "   " + root.resolutionOf(monitorRow.modelData)
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.fontSizePrimary
                            font.bold: true
                        }

                        Text {
                            width: parent.width
                            visible: text !== ""
                            elide: Text.ElideRight
                            text: monitorRow.modelData.description
                            color: Theme.textBg
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.fontSizeSmall
                        }
                    }

                    Row {
                        id: chips
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Repeater {
                            model: root.roleNames

                            delegate: Rectangle {
                                id: chip
                                required property string modelData
                                readonly property bool active: root.roles[monitorRow.index] === modelData

                                width: chipLabel.implicitWidth + 18
                                height: chipLabel.implicitHeight + 10
                                radius: Theme.barButtonRadius
                                color: active ? Theme.accentBlue : (chipMouse.containsMouse ? Theme.bgModule : "transparent")
                                border.width: 1
                                border.color: active ? Theme.accentBlue : Theme.accentGray

                                Text {
                                    id: chipLabel
                                    anchors.centerIn: parent
                                    text: root.roleLabels[chip.modelData]
                                    color: chip.active ? Theme.bgPrimary : Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pointSize: Theme.fontSizeSmall
                                    font.bold: chip.active
                                }

                                MouseArea {
                                    id: chipMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.selected = monitorRow.index
                                        root.setRole(monitorRow.index, chip.modelData)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Apply
        Rectangle {
            anchors.right: parent.right
            width: applyLabel.implicitWidth + 32
            height: applyLabel.implicitHeight + 14
            radius: Theme.barButtonRadius
            color: applyMouse.containsMouse ? Theme.highlightBlue : Theme.accentBlue

            Text {
                id: applyLabel
                anchors.centerIn: parent
                text: "Apply"
                color: Theme.bgPrimary
                font.family: Theme.fontFamily
                font.pointSize: Theme.fontSizePrimary
                font.bold: true
            }

            MouseArea {
                id: applyMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.apply()
            }
        }
    }

    // A label on each monitor while the panel is open -----------------------------
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: label

            required property ShellScreen modelData
            readonly property int monitorIndex: root.monitors.findIndex(m => m.name === modelData.name)
            readonly property var monitor: monitorIndex >= 0 ? root.monitors[monitorIndex] : null
            readonly property bool isSelected: monitorIndex === root.selected

            screen: modelData
            visible: monitor !== null
            anchors.bottom: true
            margins.bottom: modelData.height / 20
            exclusionMode: ExclusionMode.Ignore
            implicitWidth: Math.max(Theme.barButtonWidth * 8, labelColumn.implicitWidth + 40)
            implicitHeight: labelColumn.implicitHeight + 24
            color: "transparent"
            mask: Region {}                     // clicks pass through

            WlrLayershell.namespace: "pulsar-display-label"
            WlrLayershell.layer: WlrLayer.Overlay

            Rectangle {
                anchors.fill: parent
                radius: Theme.barRadius
                color: Theme.bgModule
                border.width: label.isSelected ? 3 : 2
                border.color: label.isSelected ? Theme.highlightOrange : Theme.accentBlue

                Column {
                    id: labelColumn
                    anchors.centerIn: parent
                    spacing: 2

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: label.monitor ? label.monitor.name : ""
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.fontSizeLarge
                        font.bold: true
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: label.monitor
                            ? root.resolutionOf(label.monitor) + "  ·  "
                              + root.roleLabels[root.roles[label.monitorIndex] ?? "other"]
                            : ""
                        color: label.isSelected ? Theme.highlightOrange : Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.fontSizePrimary
                    }
                }
            }
        }
    }
}
