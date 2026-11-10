pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
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

        case "files": {
            if (p === "") return [hint("Type part of a file or folder name", "\uf07b")]
            if (fileResults.length > 0) return fileResults
            if (fileError !== "") return [hint(fileError, "\uf071")]
            if (fileIndexing) return [hint("Indexing your files...", "\uf07b")]
            return [hint("No matching files or folders", "\uf07b")]
        }
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
        list.positionViewAtIndex(list.currentIndex, ListView.Contain)
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
        case "file":
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


    // New results: select the first row.
    onResultsChanged: list.currentIndex = 0

    // File search ("/") -------------------------------------------------------
    // The first time "/" is used in a launcher session, fd lists every file
    // and folder under $HOME into an index file; fzf then fuzzy-matches each
    // query against that index (a few ms even for large homes). Searches run
    // against the previous session's index straight away while the new one
    // is built, and re-run when it's ready.
    readonly property string home: Quickshell.env("HOME")
    readonly property string fileIndex: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/pulsar_shell/launcher-files.txt"

    // Folders (relative to $HOME) that are big and rarely what you're after.
    property var excludedDirs: [".git", "node_modules", ".cache", ".local/share/Trash",
        ".local/share/Steam", ".steam", ".var", ".npm", ".cargo", ".rustup", "go/pkg",
        ".mozilla", ".zen", "__pycache__"]

    property var fileResults: []
    property bool fileIndexing: false
    property bool fileIndexStarted: false
    property string fileError: ""
    property bool fileSearchQueued: false

    onModeChanged: if (mode === "files") startFileSearch()
    onPayloadChanged: if (mode === "files") searchFiles()

    function startFileSearch() {
        if (!fileIndexStarted) {
            fileIndexStarted = true
            fileIndexing = true
            let excludes = []
            for (const d of excludedDirs) excludes = excludes.concat(["--exclude", d])
            indexProc.command = ["sh", "-c",
                'out="$1"; shift; ' +
                'fd=$(command -v fd || command -v fdfind) || exit 127; ' +
                'command -v fzf >/dev/null || exit 126; ' +
                'mkdir -p "$(dirname "$out")" && chmod 700 "$(dirname "$out")" || exit 1; ' +
                '"$fd" --type f --type d --hidden --base-directory "$HOME" "$@" . > "$out.tmp" && mv "$out.tmp" "$out"',
                "sh", fileIndex].concat(excludes)
            indexProc.running = true
        }
        searchFiles()
    }

    function searchFiles() {
        if (payload === "") {
            fileResults = []
            return
        }
        // One search at a time; if the query changes mid-search, run again
        // with the latest text when it finishes.
        if (findProc.running) fileSearchQueued = true
        else findProc.running = true
    }

    // fd path (relative to $HOME, folders end in "/") -> result row
    function fileResult(rel) {
        const isDir = rel.endsWith("/")
        const clean = isDir ? rel.slice(0, -1) : rel
        const slash = clean.lastIndexOf("/")
        return {
            kind: "file",
            title: clean.slice(slash + 1) + (isDir ? "/" : ""),
            subtitle: slash < 0 ? "~" : "~/" + clean.slice(0, slash),
            glyph: isDir ? "\uf07b" : "\uf15b",
            target: home + "/" + clean
        }
    }

    Process {
        id: indexProc
        onExited: code => {
            root.fileIndexing = false
            if (code === 127) root.fileError = "File search needs fd (pacman -S fd)"
            else if (code === 126) root.fileError = "File search needs fzf (pacman -S fzf)"
            else if (code !== 0) root.fileError = "Couldn't index your files"
            else if (root.mode === "files") root.searchFiles()     // re-run against the fresh index
        }
    }

    Process {
        id: findProc
        // --scheme=path ranks matches in file names above matches in folders.
        command: ["sh", "-c", '{ fzf --filter "$1" --scheme=path < "$2"; } 2>/dev/null | head -n "$3"',
                  "sh", root.payload, root.fileIndex, String(root.maxResults)]
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.mode !== "files") return
                root.fileResults = text.split("\n").filter(l => l !== "").map(l => root.fileResult(l))
            }
        }
        onExited: {
            if (root.fileSearchQueued) {
                root.fileSearchQueued = false
                running = true
            }
        }
    }

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
                AppIcon {
                    id: appIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    size: 28
                    visible: row.modelData.kind === "app"
                    icon: visible ? (row.modelData.icon ?? "") : ""
                    name: row.modelData.title ?? ""
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
                "/ name     find a file or folder",
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
