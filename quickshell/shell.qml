import QtQuick
import Quickshell
import "bar"
import "osd"
import "launcher"
import "services"
import "auth"
import "lock"

// Composition root: lists what runs, nothing more. Per-screen pieces go inside
// the Variants; global pieces sit beside it.
ShellRoot {
    id: root

    // One bar per monitor; Variants adds and removes bars as monitors change.
    Variants {
        model: Quickshell.screens

        Bar {}
    }

    // Global windows. Each one picks the focused monitor itself when shown.
    AudioOSD {}
    AuthAgent {}        // polkit password prompts

    // Launcher is a singleton, and Quickshell only creates a singleton the
    // first time something uses it. Referencing it here creates it at startup,
    // so `qs ipc call launcher toggle` works before the button is ever clicked.
    readonly property var launcher: Launcher
    // Same for the notification daemon: it has to claim the notification
    // D-Bus name at startup, before any app sends one.
    readonly property var notifications: NotificationService
    // And the lockscreen, so `qs ipc call lock lock` works from the first keypress.
    readonly property var lock: Lock
}
