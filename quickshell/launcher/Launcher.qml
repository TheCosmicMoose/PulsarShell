import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// App launcher entry point. Add `Launcher {}` to shell.qml, then bind a key to:
//     qs ipc call launcher toggle
//
// The window only exists while the launcher is open (LazyLoader), so every
// open starts with an empty search box and the first tab selected.
Scope {
    id: root

    property bool open: false
    property var targetScreen: null

    // Open on whichever monitor has focus right now. The screen is picked once,
    // at open time, so the launcher doesn't jump around if focus changes.
    function show() {
        const name = Hyprland.focusedMonitor?.name
        targetScreen = Quickshell.screens.find(s => s.name === name) || Quickshell.screens[0]
        open = true
    }

    function hide() {
        open = false
    }

    // IPC functions need explicit types or Quickshell won't register them.
    IpcHandler {
        target: "launcher"

        function toggle(): void {
            if (root.open) root.hide()
            else root.show()
        }
        function show(): void { root.show() }
        function hide(): void { root.hide() }
    }

    LazyLoader {
        active: root.open

        LauncherWindow {
            screen: root.targetScreen
            onDismissed: root.hide()
        }
    }
}
