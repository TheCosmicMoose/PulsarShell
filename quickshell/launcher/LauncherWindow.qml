pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"

// The launcher window itself. With no anchors set, a layer-shell window is
// centered on its screen.
PanelWindow {
    id: win

    signal dismissed()

    property int currentTab: 0
    readonly property var tabNames: ["Search", "Apps", "Clipboard", "System"]

    // The tab that should receive Up/Down/Enter. Tabs not built yet give null.
    readonly property var activeTab: currentTab === 0 ? search
                                   : currentTab === 1 ? apps
                                   : null

    implicitWidth: 640
    implicitHeight: 460
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "cosmic-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    // Exclusive: the launcher gets the keyboard until it closes.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    function cycleTab(step) {
        currentTab = (currentTab + step + tabNames.length) % tabNames.length
    }

    // All keys are handled here, while focus stays in the search box.
    function handleKey(event) {
        switch (event.key) {
        case Qt.Key_Escape:
            dismissed()
            event.accepted = true
            return
        case Qt.Key_Tab:
            cycleTab(1)
            event.accepted = true
            return
        case Qt.Key_Backtab:            // Shift+Tab
            cycleTab(-1)
            event.accepted = true
            return
        case Qt.Key_Down:
            if (activeTab) activeTab.move(1)
            event.accepted = true
            return
        case Qt.Key_Up:
            if (activeTab) activeTab.move(-1)
            event.accepted = true
            return
        case Qt.Key_Return:
        case Qt.Key_Enter:
            if (activeTab) activeTab.activateCurrent()
            event.accepted = true
            return
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.barRadius
        color: Qt.alpha(Theme.bgPrimary, Theme.alphaBG)
        border.width: 1
        border.color: Theme.accentGray

        Column {
            anchors.fill: parent
            anchors.margins: Theme.horizontalPadding
            spacing: Theme.barSpacing

            // Search bar -------------------------------------------------
            Rectangle {
                id: searchBar
                width: parent.width
                height: 44
                radius: height / 2
                color: Theme.bgModule

                Text {
                    id: searchGlyph
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf002"
                    color: Theme.highlightGray
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.fontSizeLarge
                }

                TextInput {
                    id: input
                    anchors.left: searchGlyph.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true
                    focus: true
                    color: Theme.textPrimary
                    selectionColor: Theme.selectionBg
                    selectedTextColor: Theme.selectionFg
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.fontSizeLarge

                    Component.onCompleted: forceActiveFocus()
                    Keys.onPressed: event => win.handleKey(event)

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: input.text === ""
                        text: win.currentTab === 1 ? "Filter apps..." : "Search..."
                        color: Theme.textBg
                        font: input.font
                    }
                }
            }

            // Tab row ----------------------------------------------------
            Row {
                id: tabRow
                width: parent.width
                spacing: Theme.barSpacing

                Repeater {
                    model: win.tabNames

                    delegate: Item {
                        id: tabItem

                        required property var modelData
                        required property int index
                        readonly property bool active: win.currentTab === index

                        width: (tabRow.width - tabRow.spacing * (win.tabNames.length - 1)) / win.tabNames.length
                        height: 32

                        Text {
                            anchors.centerIn: parent
                            text: tabItem.modelData
                            color: tabItem.active ? Theme.highlightOrange : Theme.highlightGray
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.fontSizePrimary
                            font.bold: tabItem.active
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 2
                            visible: tabItem.active
                            color: Theme.highlightOrange
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                win.currentTab = tabItem.index
                                input.forceActiveFocus()
                            }
                        }
                    }
                }
            }

            // Tab content ------------------------------------------------
            Item {
                width: parent.width
                height: parent.height - searchBar.height - tabRow.height - parent.spacing * 2

                SearchTab {
                    id: search
                    anchors.fill: parent
                    visible: win.currentTab === 0
                    query: input.text
                    onLaunched: win.dismissed()
                }

                AppsTab {
                    id: apps
                    anchors.fill: parent
                    visible: win.currentTab === 1
                    query: input.text
                    onLaunched: win.dismissed()
                }

                // Placeholder for the tabs that aren't built yet.
                Text {
                    anchors.centerIn: parent
                    visible: win.currentTab >= 2
                    text: win.tabNames[win.currentTab] + " tab: coming soon"
                    color: Theme.textBg
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.fontSizePrimary
                }
            }
        }
    }
}
