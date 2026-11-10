pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

// The launcher's Clipboard tab: clipboard history from clipvault.
//
//   Up / Down, mouse   choose        Enter, click   copy it and close
//
// The history is read with `clipvault list` (one "<id>\t<preview>" line per
// entry, newest first) each time the tab opens, and an entry is copied with
// `clipvault get <id> | wl-copy`. Typing in the search box filters entries.
Item {
    id: root

    property string query: ""
    signal launched()

    property var entries: []        // [{ id, preview, isBinary }]
    property bool loading: false
    property string error: ""

    readonly property var filtered: {
        const q = query.trim().toLowerCase()
        if (q === "") return entries
        return entries.filter(e => e.preview.toLowerCase().includes(q))
    }

    onFilteredChanged: {
        list.currentIndex = 0
        list.positionViewAtBeginning()
    }

    // Reload whenever the tab is shown.
    onVisibleChanged: if (visible) refresh()

    function refresh() {
        loading = true
        error = ""
        listProc.running = true
    }

    function move(delta) {
        if (filtered.length === 0) return
        list.currentIndex = Math.max(0, Math.min(filtered.length - 1, list.currentIndex + delta))
        list.positionViewAtIndex(list.currentIndex, ListView.Contain)
    }

    function activateCurrent() {
        copy(filtered[list.currentIndex])
    }

    function copy(entry) {
        if (!entry) return
        Quickshell.execDetached(["sh", "-c", 'clipvault get "$1" | wl-copy', "sh", entry.id])
        launched()
    }

    // "[[ binary data 12.3 KiB image/png 800x600 ]]" -> "Image · png · 12.3 KiB · 800x600"
    function describeBinary(preview) {
        const inner = preview.replace(/^\[\[\s*binary data\s*/, "").replace(/\s*\]\]$/, "")
        const parts = inner.split(/\s+/)
        // size is "<number> <unit>"
        const size = parts.slice(0, 2).join(" ")
        const mime = parts[2] ?? ""
        const extra = parts.slice(3).join(" ")
        const kind = mime.startsWith("image/") ? "Image" : "Binary data"
        return [kind, mime.split("/")[1] ?? "", size, extra].filter(x => x).join("  ·  ")
    }

    Process {
        id: listProc
        command: ["sh", "-c", "command -v clipvault >/dev/null || exit 127; clipvault list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t")
                    if (tab <= 0) continue
                    const preview = line.slice(tab + 1)
                    out.push({
                        id: line.slice(0, tab),
                        preview: preview,
                        isBinary: preview.startsWith("[[ binary data")
                    })
                }
                root.entries = out
                root.loading = false
            }
        }
        onExited: code => {
            root.loading = false
            if (code === 127) root.error = "Clipboard history needs clipvault (it's in the AUR dependencies)."
            else if (code !== 0) root.error = "Couldn't read the clipboard history (clipvault exited with " + code + ")."
        }
    }

    ListView {
        id: list
        anchors.fill: parent
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

            width: list.width
            height: Theme.barThickness

            Rectangle {
                anchors.fill: parent
                radius: Theme.barRadius
                color: row.selected ? Theme.selectionBg : "transparent"

                Text {
                    id: glyph
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    horizontalAlignment: Text.AlignHCenter
                    // image / text
                    text: row.modelData.isBinary ? "󰋩" : "󰈙"
                    color: row.selected ? Theme.selectionFg : Theme.highlightOrange
                    font.family: Theme.fontFamilyAlt
                    font.pointSize: Theme.fontSizeLarge
                }

                Column {
                    anchors.left: glyph.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        text: row.modelData.isBinary ? root.describeBinary(row.modelData.preview)
                                                     : row.modelData.preview.trim() || "(blank)"
                        color: row.selected ? Theme.selectionFg : Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.fontSizePrimary
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: list.currentIndex = row.index
                onClicked: {
                    list.currentIndex = row.index
                    root.copy(row.modelData)
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        width: parent.width - 40
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        visible: root.filtered.length === 0
        text: root.error !== "" ? root.error
            : root.loading ? "Loading clipboard history..."
            : root.entries.length === 0 ? "Clipboard history is empty. Copy something and it will show up here."
            : "No matching entries"
        color: root.error !== "" ? Theme.highlightRed : Theme.textBg
        font.family: Theme.fontFamily
        font.pointSize: Theme.fontSizePrimary
    }
}
