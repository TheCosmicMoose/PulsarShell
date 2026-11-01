pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Widgets
import "../theme"

// The Search tab. How it works, in three steps:
//   1. The first character of the query picks a MODE (@ # / $ or plain apps).
//   2. The mode turns the query into a list of RESULTS (plain JS objects).
//   3. The list shows them, and activate() runs the selected one.
Item {
    id: root

    // Text from the search box.
    property string query: ""

    // Web searches open this URL with the query appended. A browser-specific
    // approach (like Firefox's --search flag) can replace this later.
    property string searchUrl: "https://duckduckgo.com/?q="

    property int maxResults: 8

    signal launched()

    // Step 1: mode ---------------------------------------------------------
    readonly property string mode: {
        switch (query.charAt(0)) {
        case "@": return "website"
        case "#": return "web"
        case "/": return "files"
        case "$": return "command"
        default:  return "apps"
        }
    }

    // The query without its leading predicate character.
    readonly property string payload: mode === "apps" ? query.trim() : query.slice(1).trim()

    // Step 2: results ------------------------------------------------------
    // Each result is { kind, title, subtitle, glyph, icon, target, entry }.
    readonly property var results: {
        const p = payload

        switch (mode) {
        case "apps":
            return p === "" ? [] : searchApps(p)

        case "website": {
            if (p === "") return [hint("Type a site, like amazon or wikipedia.org", "\uf0ac")]
            const url = formatWebsite(p)
            return [{ kind: "website", title: "Open " + url, subtitle: "In your default browser",
                      glyph: "\uf0ac", target: url }]
        }

        case "web": {
            if (p === "") return [hint("Type something to search the web for", "\uf002")]
            return [{ kind: "web", title: "Search the web for \"" + p + "\"", subtitle: "In your default browser",
                      glyph: "\uf002", target: searchUrl + encodeURIComponent(p) }]
        }

        case "command": {
            if (p === "") return [hint("Type a command to run in kitty", "\uf120")]
            return [{ kind: "command", title: "Run: " + p, subtitle: "Opens in kitty",
                      glyph: "\uf120", target: p }]
        }

        case "files":
            return [hint("File search is coming soon", "\uf07b")]
        }
        return []
    }

    // A non-clickable row that explains what to type.
    function hint(text, glyph) {
        return { kind: "hint", title: text, subtitle: "", glyph: glyph }
    }

    // Turn what the user typed after "@" into a full URL.
    function formatWebsite(input) {
        const q = input.trim()
        if (/^[a-z][a-z0-9+.-]*:\/\//i.test(q)) return q            // already has https:// etc.

        // Only look at the host part (before any "/") when deciding on ".com".
        const slash = q.indexOf("/")
        const host = slash === -1 ? q : q.slice(0, slash)
        const rest = slash === -1 ? "" : q.slice(slash)

        const hasTld = /\.[a-z]{2,}$/i.test(host)            // ends in .org, .io, .co.uk ...
                       || /^[\d.]+(:\d+)?$/.test(host)       // an IP address
                       || host.includes(":")                 // has a port
                       || host === "localhost"
        return "https://" + (hasTld ? host : host + ".com") + rest
    }

    // Find apps matching the query, best matches first.
    function searchApps(q) {
        const needle = q.toLowerCase()
        const scored = []

        for (const a of DesktopEntries.applications.values) {
            if (a.noDisplay) continue

            const name = a.name.toLowerCase()
            let score = -1
            if (name.startsWith(needle))                score = 0   // "aud" -> Audacity
            else if (name.includes(" " + needle))       score = 1   // start of a later word
            else if (name.includes(needle))             score = 2   // anywhere in the name
            else if ((a.genericName || "").toLowerCase().includes(needle)
                     || Array.from(a.keywords || []).some(k => k.toLowerCase().includes(needle)))
                                                        score = 3   // generic name or keywords

            if (score >= 0) scored.push({ score: score, app: a })
        }

        scored.sort((x, y) => (x.score - y.score) || x.app.name.localeCompare(y.app.name))

        return scored.slice(0, maxResults).map(s => ({
            kind: "app",
            title: s.app.name,
            subtitle: s.app.genericName || s.app.comment || "",
            icon: s.app.icon,
            entry: s.app
        }))
    }

    // Step 3: running a result --------------------------------------------
    function move(delta) {
        if (results.length === 0) return
        list.currentIndex = Math.max(0, Math.min(results.length - 1, list.currentIndex + delta))
    }

    function activateCurrent() {
        activate(results[list.currentIndex])
    }

    function activate(r) {
        if (!r) return

        switch (r.kind) {
        case "app":
            launchApp(r.entry)
            break
        case "website":
        case "web":
            Quickshell.execDetached(["xdg-open", r.target])
            break
        case "command":
            // The command is one argument to sh -c, so there's no quoting to get wrong.
            Quickshell.execDetached(["kitty", "--hold", "sh", "-c", r.target])
            break
        default:
            return          // hints do nothing
        }
        launched()
    }

    function launchApp(entry) {
        if (entry.runInTerminal) {
            Quickshell.execDetached({
                command: ["kitty"].concat(Array.from(entry.command)),
                workingDirectory: entry.workingDirectory
            })
        } else {
            entry.execute()
        }
    }

    function iconSource(icon) {
        if (!icon) return Quickshell.iconPath("application-x-executable")
        if (icon.startsWith("/")) return "file://" + icon
        return Quickshell.iconPath(icon, "application-x-executable")
    }

    // New results: select the first row.
    onResultsChanged: list.currentIndex = 0

    // The list --------------------------------------------------------------
    ListView {
        id: list
        anchors.fill: parent
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: 0
        model: root.results

        delegate: Item {
            id: row

            required property var modelData
            required property int index
            readonly property bool selected: ListView.isCurrentItem
            readonly property bool clickable: modelData.kind !== "hint"

            width: list.width
            height: 48

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: row.selected && row.clickable ? Theme.selectionBg : "transparent"

                // Apps get their real icon; everything else gets a glyph.
                IconImage {
                    id: appIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: 28
                    visible: row.modelData.kind === "app"
                    source: visible ? root.iconSource(row.modelData.icon) : ""
                }

                Text {
                    id: glyph
                    anchors.centerIn: appIcon
                    visible: row.modelData.kind !== "app"
                    text: row.modelData.glyph || ""
                    color: row.selected && row.clickable ? Theme.selectionFg : Theme.highlightOrange
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.fontSizeLarge
                }

                Column {
                    anchors.left: appIcon.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: row.modelData.title
                        color: !row.clickable ? Theme.textBg
                               : row.selected ? Theme.selectionFg : Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.fontSizePrimary
                    }

                    Text {
                        width: parent.width
                        visible: text !== ""
                        elide: Text.ElideRight
                        text: row.modelData.subtitle || ""
                        color: row.selected ? Theme.selectionFg : Theme.textBg
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.fontSizeSmall
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: row.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
                onPositionChanged: list.currentIndex = row.index
                onClicked: {
                    list.currentIndex = row.index
                    root.activate(row.modelData)
                }
            }
        }
    }

    // Shown while the search box is empty.
    Column {
        anchors.centerIn: parent
        visible: root.query.trim() === ""
        spacing: 6

        Repeater {
            model: [
                "Type to search apps",
                "@ site     open a website",
                "# text     search the web",
                "/ name     find a file",
                "$ cmd      run in kitty"
            ]

            delegate: Text {
                required property var modelData
                text: modelData
                color: Theme.textBg
                font.family: Theme.fontFamily
                font.pointSize: Theme.fontSizePrimary
            }
        }
    }
}
