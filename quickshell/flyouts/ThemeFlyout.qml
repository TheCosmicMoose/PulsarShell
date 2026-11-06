pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"
import "common"

// Theme flyout: every theme file in ~/.config/pulsar_shell_theme, each with
// its name and a row of color dots (background, text, then the accents).
// Clicking one applies it with pulsar-theme; Quickshell and the other apps
// pick the new colors up from the files it writes.
Column {
    id: root

    readonly property int panelWidth: 320

    readonly property string themeDir: {
        const xdg = Quickshell.env("XDG_CONFIG_HOME")
        return (xdg ? xdg : Quickshell.env("HOME") + "/.config") + "/pulsar_shell_theme"
    }
    readonly property string themeBin: Quickshell.env("HOME") + "/.local/bin/pulsar-theme"

    // Colors shown as dots, in order.
    readonly property var dotKeys: ["bgPrimary", "textPrimary", "accentRed", "accentOrange",
        "accentYellow", "accentGreen", "accentAqua", "accentBlue", "accentPurple"]

    property var themes: []             // [{ file, name, colors }]
    property bool loaded: false
    property string applying: ""        // file being applied
    property string error: ""

    function apply(file) {
        if (applying !== "") return
        applying = file
        error = ""
        applyProc.command = [themeBin, file]
        applyProc.running = true
    }

    // List the themes: one compact JSON line per file (current_theme.json is
    // the active copy, not a theme of its own).
    Process {
        running: true
        command: ["sh", "-c",
            'for f in "$1"/*.json; do ' +
            '  [ -e "$f" ] || continue; ' +
            '  [ "${f##*/}" = current_theme.json ] && continue; ' +
            '  jq -c --arg file "$f" \'{file: $file, name: .name, colors: .colors}\' "$f" 2>/dev/null; ' +
            'done', "sh", root.themeDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = []
                for (const line of text.split("\n")) {
                    if (line.trim() === "") continue
                    try {
                        const t = JSON.parse(line)
                        if (t.name && t.colors) list.push(t)
                    } catch (e) {}
                }
                list.sort((a, b) => a.name.localeCompare(b.name))
                root.themes = list
                root.loaded = true
            }
        }
    }

    Process {
        id: applyProc
        stderr: StdioCollector { id: applyErr }
        onExited: code => {
            if (code !== 0) {
                // Show the program's first error line (warnings like the Zen one are fine).
                const lines = applyErr.text.split("\n").filter(l => l.startsWith("error"))
                root.error = lines.length > 0 ? lines[0] : "pulsar-theme failed (exit " + code + ")"
            }
            root.applying = ""
        }
    }

    spacing: Theme.barSpacing

    FlyoutHeader {
        width: root.panelWidth
        title: "Theme"
        showToggle: false
    }

    Repeater {
        model: ScriptModel { values: root.themes }

        delegate: Rectangle {
            id: row

            required property var modelData
            readonly property bool current: modelData.name === Theme.themeName
            readonly property bool busy: root.applying === modelData.file

            width: root.panelWidth
            height: column.implicitHeight + 16
            radius: Theme.barButtonRadius
            color: hover.hovered ? Theme.bgModule : "transparent"
            border.width: current ? 1 : 0
            border.color: Theme.accentBlue

            HoverHandler { id: hover }

            Column {
                id: column
                x: 10
                y: 8
                width: parent.width - 20
                spacing: 6

                Item {
                    width: parent.width
                    height: nameText.implicitHeight

                    Text {
                        id: nameText
                        anchors.left: parent.left
                        anchors.right: status.left
                        anchors.rightMargin: 8
                        elide: Text.ElideRight
                        text: row.modelData.name
                        color: row.current ? Theme.accentBlue : Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.fontSizePrimary
                        font.bold: row.current
                    }

                    Text {
                        id: status
                        anchors.right: parent.right
                        text: row.busy ? "Applying..." : row.current ? "Active" : ""
                        color: Theme.textBg
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.fontSizeSmall
                    }
                }

                // Color dots
                Row {
                    spacing: 6

                    Repeater {
                        model: root.dotKeys

                        delegate: Rectangle {
                            required property string modelData

                            width: 14
                            height: 14
                            radius: 7
                            color: row.modelData.colors[modelData] ?? "transparent"
                            // An outline so dark/light dots show on any background.
                            border.width: 1
                            border.color: Qt.alpha(Theme.textBg, 0.6)
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: row.current ? Qt.ArrowCursor : Qt.PointingHandCursor
                onClicked: if (!row.current) root.apply(row.modelData.file)
            }
        }
    }

    Text {
        width: root.panelWidth
        visible: root.loaded && root.themes.length === 0
        wrapMode: Text.Wrap
        text: "No themes found in " + root.themeDir
        color: Theme.textBg
        font.family: Theme.fontFamily
        font.pointSize: Theme.fontSizeSmall
    }

    Text {
        width: root.panelWidth
        visible: root.error !== ""
        wrapMode: Text.Wrap
        text: root.error
        color: Theme.highlightRed
        font.family: Theme.fontFamily
        font.pointSize: Theme.fontSizeSmall
    }

    Text {
        width: root.panelWidth
        wrapMode: Text.Wrap
        text: "Right-click the theme button to pick a wallpaper."
        color: Theme.textBg
        font.family: Theme.fontFamily
        font.pointSize: Theme.fontSizeSmall
    }
}
