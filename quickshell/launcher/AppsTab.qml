pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Widgets
import "../theme"

// Alphabetical list of installed apps. Focus stays in the search box; the
// window forwards Up/Down/Enter to move() and activateCurrent().
Item {
    id: root

    // Text from the search box. Empty shows every app.
    property string query: ""

    signal launched()

    // Every visible app, sorted by name.
    readonly property var apps: {
        const list = DesktopEntries.applications.values.filter(a => !a.noDisplay)
        list.sort((a, b) => a.name.localeCompare(b.name))
        return list
    }

    // Apps matching the query by name, generic name, or keywords.
    readonly property var filtered: {
        const q = query.trim().toLowerCase()
        if (q === "") return apps
        return apps.filter(a =>
            a.name.toLowerCase().includes(q)
            || (a.genericName || "").toLowerCase().includes(q)
            || Array.from(a.keywords || []).some(k => k.toLowerCase().includes(q)))
    }

    // New results: go back to the top and select the first match.
    onFilteredChanged: {
        list.currentIndex = 0
        list.positionViewAtBeginning()
    }

    function move(delta) {
        if (filtered.length === 0) return
        list.currentIndex = Math.max(0, Math.min(filtered.length - 1, list.currentIndex + delta))
        list.positionViewAtIndex(list.currentIndex, ListView.Contain)
    }

    function activateCurrent() {
        const entry = filtered[list.currentIndex]
        if (entry) launch(entry)
    }

    function launch(entry) {
        if (entry.runInTerminal) {
            // execute() ignores runInTerminal, so wrap terminal apps in kitty ourselves.
            Quickshell.execDetached({
                command: ["kitty"].concat(Array.from(entry.command)),
                workingDirectory: entry.workingDirectory
            })
        } else {
            entry.execute()
        }
        launched()
    }

    function iconSource(icon) {
        if (!icon) return Quickshell.iconPath("application-x-executable")
        if (icon.startsWith("/")) return "file://" + icon      // some entries use a full path
        return Quickshell.iconPath(icon, "application-x-executable")
    }

    ListView {
        id: list
        anchors.fill: parent
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: 0

        // ScriptModel keeps rows stable while the filtered list changes.
        model: ScriptModel {
            values: root.filtered
        }

        delegate: Item {
            id: row

            required property var modelData
            required property int index
            readonly property bool selected: ListView.isCurrentItem

            width: list.width
            height: Theme.barThickness

            Rectangle {
                anchors.fill: parent
                radius: Theme.barRadius
                color: row.selected ? Theme.selectionBg : "transparent"

                IconImage {
                    id: icon
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: 28
                    source: root.iconSource(row.modelData.icon)
                }

                Text {
                    anchors.left: icon.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    text: row.modelData.name
                    color: row.selected ? Theme.accentBlue : Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.fontSizePrimary
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                // Follow real mouse movement only, so a scrolling list under a
                // still cursor doesn't steal the keyboard selection.
                onPositionChanged: list.currentIndex = row.index
                onClicked: {
                    list.currentIndex = row.index
                    root.launch(row.modelData)
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: root.filtered.length === 0
        text: "No matching apps"
        color: Theme.textBg
        font.family: Theme.fontFamily
        font.pointSize: Theme.fontSizePrimary
    }
}
