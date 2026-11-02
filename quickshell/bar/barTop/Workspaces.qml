pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../theme"
import "../../services"

// Workspace indicator for one monitor. The bar creates one of these per
// screen and passes the screen in:  Workspaces { screen: modelData }
Column {
    id: root

    required property var screen

    // How many workspaces each monitor shows
    property int mainMonWs: 6
    property int secMonWs:  4
    property int otherMonWs: 5

    // Icons by position. Index 0 is the first workspace on that monitor.
    readonly property var mainIcons: ["󰚀", "󰙯", "", "", "", ""]
    readonly property var secIcons:  ["󰚀", "󰙯", "", ""]
    readonly property string fallbackIcon: ""

    // This monitor's role, and the workspace range it owns (main: 1-N, secondary: 11-N+10)
    readonly property string role: Displays.roleOf(screen.name)
    readonly property int wsOffset: role === "secondary" ? 10 : 0
    readonly property int wsCount: {
        if (role === "main") return mainMonWs
        if (role === "secondary") return secMonWs
        return otherMonWs
    }

    // Hyprland's view of this monitor. Looked up by name so it updates as monitors come and go.
    readonly property var monitor: Hyprland.monitors.values.find(m => m.name === screen.name)

    property bool scratchpadActive: false
    property bool scrollBusy: false

    spacing: Theme.barSpacing

    // Workspace dispatcher -----------------------------------------------
    function dispatchWorkspace(target, special) {
        if (Hyprland.usingLua) {
            if (special) {
                Hyprland.dispatch(`hl.dsp.workspace.toggle_special("${target}")`)
            } else {
                Hyprland.dispatch(`hl.dsp.focus({ workspace = "${target}" })`)
            }
        } else {
            if (special) {
                Hyprland.dispatch(`togglespecialworkspace ${target}`)
            } else {
                Hyprland.dispatch(`workspace ${target}`)
            }
        }
    }

    // Scroll handling ------------------------------------------------------
    Timer {
        id: scrollCooldown
        interval: 400
        repeat: false
        onTriggered: root.scrollBusy = false
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function(event) {
            if (root.scrollBusy) return

            // Only cycle through occupied workspaces that belong to this monitor
            const lo = root.wsOffset + 1
            const hi = root.wsOffset + root.wsCount
            const occupied = Hyprland.workspaces.values
                .map(w => w.id)
                .filter(id => id >= lo && id <= hi)
                .sort((a, b) => a - b)
            if (occupied.length === 0) return

            root.scrollBusy = true
            scrollCooldown.restart()

            let idx = occupied.indexOf(root.monitor?.activeWorkspace?.id)
            if (idx === -1) idx = 0

            if (event.angleDelta.y < 0) {
                idx = (idx + 1) % occupied.length
            } else {
                idx = (idx - 1 + occupied.length) % occupied.length
            }
            root.dispatchWorkspace(occupied[idx], false)
        }
    }

    // Scratchpad state -----------------------------------------------------
    // "activespecial" data looks like "WORKSPACENAME,MONITORNAME"; the name is
    // empty when the special workspace closes.
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "activespecial") {
                const parts = event.data.split(",")
                if (parts[1] === root.screen.name) {
                    root.scratchpadActive = (parts[0] !== "")
                }
            } else if (event.name === "destroyworkspace" && event.data.startsWith("special:")) {
                root.scratchpadActive = false
            }
        }
    }

    // Workspace icons ------------------------------------------------------
    Repeater {
        model: root.wsCount

        delegate: Text {
            id: wsIcon

            required property int index

            readonly property int wsId: index + 1 + root.wsOffset
            readonly property var ws: Hyprland.workspaces.values.find(w => w.id === wsId)
            readonly property bool isActive: root.monitor?.activeWorkspace?.id === wsId
            readonly property bool isOccupied: ws !== undefined
            readonly property bool isUrgent: ws !== undefined && ws.urgent
            readonly property bool hovered: mouse.containsMouse

            font.family: Theme.fontFamily
            font.pointSize: Theme.fontSizePrimary
            horizontalAlignment: Text.AlignHCenter

            color: {
                if (hovered) {
                    if (isActive) return Theme.highlightBlue
                    if (isUrgent) return Theme.highlightRed
                    if (isOccupied) return Theme.textPrimary
                    return Theme.highlightGray
                }
                if (isActive) return Theme.accentBlue
                if (isUrgent) return Theme.accentRed
                if (isOccupied) return Theme.textSecondary
                return Theme.textBg
            }

            text: {
                const icons = root.role === "secondary" ? root.secIcons : root.mainIcons
                return index < icons.length ? icons[index] : root.fallbackIcon
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: root.dispatchWorkspace(wsIcon.wsId, false)
            }
        }
    }

    // Scratchpad indicator -------------------------------------------------
    Text {
        visible: root.scratchpadActive

        font.family: Theme.fontFamily
        font.pointSize: Theme.fontSizePrimary
        color: Theme.accentAqua
        text: "󰬚"
    }
}
