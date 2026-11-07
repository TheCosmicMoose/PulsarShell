pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Shell preferences changed from the UI, saved to
// ~/.local/state/pulsar_shell/settings.json so they survive restarts.
//
//   ShellSettings.barBackground   -> fill the bar with the theme background
//
// Change a setting by assigning to it; it's saved automatically.
Singleton {
    id: root

    readonly property string dir: {
        const xdg = Quickshell.env("XDG_STATE_HOME")
        return (xdg ? xdg : Quickshell.env("HOME") + "/.local/state") + "/pulsar_shell"
    }

    property alias barBackground: adapter.barBackground

    FileView {
        id: file
        path: root.dir + "/settings.json"
        blockLoading: true          // settings are ready before the bars draw
        watchChanges: true
        onFileChanged: reload()
        // A missing file just means nothing has been changed yet.
        printErrors: false

        // Save on every change (creating the folder first if needed).
        onAdapterUpdated: saveProc.running = true

        JsonAdapter {
            id: adapter
            property bool barBackground: false
        }
    }

    Process {
        id: saveProc
        command: ["mkdir", "-p", root.dir]
        onExited: file.writeAdapter()
    }
}
