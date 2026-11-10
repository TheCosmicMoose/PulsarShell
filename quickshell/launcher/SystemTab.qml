pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../theme"
import "../services"
import "../flyouts"

// The launcher's System tab: settings panels and power actions.
//
// List view (filtered by the search box):
//   Up / Down, mouse   choose        Enter, click   run
// Panels (audio, network, bluetooth, display picker) open inside the tab;
// Escape goes back to the list.
//
// Shutdown, Suspend, Reboot and Log off need a second Enter/click within 3s.
Item {
    id: root

    property string query: ""
    signal launched()

    // The open panel (a Component), or null for the list.
    property Component panel: null
    readonly property bool inPanel: panel !== null

    // Action awaiting its confirming second press.
    property string armed: ""

    readonly property var profileItems: !PowerService.profilesAvailable ? [] : [
        { id: "profile-saver", glyph: "󰌪", title: "Power profile: Power Saver", profile: PowerProfile.PowerSaver },
        { id: "profile-balanced", glyph: "󰗑", title: "Power profile: Balanced", profile: PowerProfile.Balanced }
    ].concat(PowerProfiles.hasPerformanceProfile
        ? [{ id: "profile-performance", glyph: "󰓅", title: "Power profile: Performance", profile: PowerProfile.Performance }]
        : [])

    readonly property var items: [
        { id: "audio",     glyph: "󰕾", title: "Audio settings",       subtitle: "Volume and output device" },
        { id: "network",   glyph: "󰖩", title: "Network settings",     subtitle: "Wi-Fi and connection details" },
        { id: "bluetooth", glyph: "󰂯", title: "Bluetooth settings",   subtitle: "Pair and connect devices" },
        { id: "displays",  glyph: "󰍹", title: "Display settings",     subtitle: "Opens nwg-displays" },
        { id: "primary",   glyph: "󱎅", title: "Set primary display",  subtitle: "Choose primary and secondary monitors" }
    ].concat(profileItems).concat([
        { id: "shutdown", glyph: "󰐥", title: "Shutdown", subtitle: "", confirm: true },
        { id: "suspend",  glyph: "󰒲", title: "Suspend",  subtitle: "Locks the screen first", confirm: true },
        { id: "reboot",   glyph: "󰜉", title: "Reboot",   subtitle: "", confirm: true },
        { id: "logout",   glyph: "󰍃", title: "Log off",  subtitle: "", confirm: true }
    ])

    readonly property var filtered: {
        const q = query.trim().toLowerCase()
        if (q === "") return items
        return items.filter(i => i.title.toLowerCase().includes(q)
                              || (i.subtitle ?? "").toLowerCase().includes(q))
    }

    onFilteredChanged: list.currentIndex = 0

    // Leaving the tab or closing a panel resets it.
    onVisibleChanged: if (!visible) { panel = null; armed = "" }

    // Called by the launcher -----------------------------------------------------
    function move(delta) {
        if (inPanel) return
        if (filtered.length === 0) return
        list.currentIndex = Math.max(0, Math.min(filtered.length - 1, list.currentIndex + delta))
        list.positionViewAtIndex(list.currentIndex, ListView.Contain)
    }

    function activateCurrent() {
        if (!inPanel) activate(filtered[list.currentIndex])
    }

    // Escape: close the panel. Returns true if it did something.
    function back() {
        if (!inPanel) return false
        panel = null
        return true
    }

    // Keys while a panel is open (the display picker uses arrows and Enter).
    function handlePanelKey(event) {
        if (!inPanel || !panelLoader.item || !panelLoader.item.handleKey) return false
        return panelLoader.item.handleKey(event)
    }

    // Actions -----------------------------------------------------------------------
    function activate(item) {
        if (!item) return

        if (item.confirm && armed !== item.id) {
            armed = item.id
            disarm.restart()
            return
        }
        armed = ""

        switch (item.id) {
        case "audio":     panel = audioPanel; return
        case "network":   panel = networkPanel; return
        case "bluetooth": panel = bluetoothPanel; return
        case "displays":
            Quickshell.execDetached(["nwg-displays"])
            launched()
            return
        case "primary":
            waitingForMonitors = true
            Displays.refreshMonitors()
            return
        case "shutdown": launched(); PowerService.shutdown(); return
        case "suspend":  launched(); PowerService.suspend(); return
        case "reboot":   launched(); PowerService.reboot(); return
        case "logout":   launched(); PowerService.logout(); return
        }
        if (item.profile !== undefined) PowerProfiles.profile = item.profile
    }

    Timer {
        id: disarm
        interval: 3000
        onTriggered: root.armed = ""
    }

    // "Set primary display": one monitor -> set it straight away; more -> picker.
    property bool waitingForMonitors: false
    Connections {
        target: Displays
        function onMonitorsLoaded() {
            if (!root.waitingForMonitors) return
            root.waitingForMonitors = false
            const mons = Displays.monitors
            if (mons.length === 0) {
                Quickshell.execDetached(["notify-send", "-a", "Displays", "Displays",
                                         "Couldn't list your monitors (is Hyprland running?)"])
            } else if (mons.length === 1) {
                Displays.apply(mons[0].name, "")
                root.launched()
            } else {
                root.panel = displayPanel
            }
        }
    }

    Component { id: audioPanel; AudioFlyout {} }
    Component { id: networkPanel; NetworkFlyout {} }
    Component { id: bluetoothPanel; BluetoothFlyout {} }
    Component {
        id: displayPanel
        DisplayPicker {
            monitors: Displays.monitors
            onApplied: root.launched()
        }
    }

    // List ----------------------------------------------------------------------------
    ListView {
        id: list
        anchors.fill: parent
        visible: !root.inPanel
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: 0
        model: ScriptModel { values: root.filtered }

        delegate: Item {
            id: row

            required property var modelData
            required property int index
            readonly property bool selected: ListView.isCurrentItem
            readonly property bool isArmed: root.armed === modelData.id
            readonly property bool isActiveProfile: modelData.profile !== undefined
                                                    && PowerProfiles.profile === modelData.profile

            width: list.width
            height: Theme.barThickness

            Rectangle {
                anchors.fill: parent
                radius: Theme.barRadius
                color: row.isArmed ? Theme.accentRed
                     : row.selected ? Theme.selectionBg : "transparent"

                Text {
                    id: glyph
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    horizontalAlignment: Text.AlignHCenter
                    text: row.modelData.glyph
                    color: row.selected || row.isArmed ? Theme.selectionFg : Theme.highlightOrange
                    font.family: Theme.fontFamilyAlt
                    font.pointSize: Theme.fontSizeLarge
                }

                Column {
                    anchors.left: glyph.right
                    anchors.leftMargin: 12
                    anchors.right: badge.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: row.modelData.title
                        color: row.selected || row.isArmed ? Theme.selectionFg : Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.fontSizePrimary
                    }

                    Text {
                        width: parent.width
                        visible: text !== ""
                        elide: Text.ElideRight
                        text: row.isArmed ? "Press again to confirm" : (row.modelData.subtitle ?? "")
                        color: row.selected || row.isArmed ? Theme.selectionFg : Theme.textBg
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.fontSizeSmall
                    }
                }

                Text {
                    id: badge
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.isActiveProfile ? "Active" : ""
                    color: row.selected ? Theme.selectionFg : Theme.textBg
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.fontSizeSmall
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: list.currentIndex = row.index
                onClicked: {
                    list.currentIndex = row.index
                    root.activate(row.modelData)
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: !root.inPanel && root.filtered.length === 0
        text: "No matching settings"
        color: Theme.textBg
        font.family: Theme.fontFamily
        font.pointSize: Theme.fontSizePrimary
    }

    Text {
        anchors.centerIn: parent
        visible: root.waitingForMonitors
        text: "Looking for monitors..."
        color: Theme.textBg
        font.family: Theme.fontFamily
        font.pointSize: Theme.fontSizePrimary
    }

    // Panel -------------------------------------------------------------------------------
    // Centered; scrolls if taller than the tab.
    Flickable {
        id: panelArea
        anchors.fill: parent
        visible: root.inPanel
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: Math.max(height, panelColumn.implicitHeight)

        Column {
            id: panelColumn
            width: panelArea.width
            y: Math.max(0, (panelArea.height - implicitHeight) / 2)
            spacing: 10

            Loader {
                id: panelLoader
                anchors.horizontalCenter: parent.horizontalCenter
                sourceComponent: root.panel
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Esc to go back"
                color: Theme.textBg
                font.family: Theme.fontFamily
                font.pointSize: Theme.fontSizeSmall
            }
        }
    }
}
