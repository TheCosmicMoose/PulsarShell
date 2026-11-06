pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

// Lockscreen. Lock with:
//     qs ipc call lock lock
//
// Flow: screenshot every monitor with grim -> lock the session -> each
// monitor shows its screenshot blurred, a clock and date, and a password box
// -> the password is checked with PAM (the "login" config, like hyprlock) ->
// unlock and delete the screenshots.
//
// The screenshots are taken before locking because, once locked, the
// compositor no longer shows the desktop to anyone, including us.
//
// If Quickshell crashes while locked, the compositor keeps the session locked
// (a solid color); restart quickshell and lock again to get back in.
Singleton {
    id: root

    // Password typed so far, shared by the boxes on every monitor.
    property string buffer: ""
    property bool busy: false           // PAM is checking a password
    property string error: ""           // last failure, shown in the box

    readonly property bool locked: sessionLock.locked
    property bool capturing: false

    // Screenshots live in the runtime dir (a per-user tmpfs) and are removed on unlock.
    readonly property string shotDir: {
        const runtime = Quickshell.env("XDG_RUNTIME_DIR")
        return (runtime ? runtime : "/tmp") + "/pulsar_shell"
    }
    function shotPath(screenName) {
        return shotDir + "/lock-" + screenName + ".png"
    }

    // Locking -----------------------------------------------------------------
    function lock() {
        if (sessionLock.locked || capturing) return
        capturing = true
        buffer = ""
        error = ""
        shot.command = ["sh", "-c",
            'd="$1"; shift; mkdir -p "$d" && chmod 700 "$d" || exit 1; ' +
            'for o in "$@"; do grim -l 0 -o "$o" "$d/lock-$o.png" & done; wait',
            "sh", shotDir].concat(Quickshell.screens.map(s => s.name))
        shot.running = true
        captureTimeout.restart()
    }

    function finishLock() {
        if (!capturing) return
        capturing = false
        captureTimeout.stop()
        sessionLock.locked = true
    }

    Process {
        id: shot
        // Lock whether or not the screenshots worked; without them the
        // lockscreen just has a plain background.
        onExited: (code, status) => {
            if (code !== 0) console.warn("lock: screenshot failed (is grim installed?)")
            root.finishLock()
        }
    }

    // Never let a stuck screenshot delay the lock by more than this.
    Timer {
        id: captureTimeout
        interval: 2000
        onTriggered: {
            console.warn("lock: screenshot timed out, locking without it")
            root.finishLock()
        }
    }

    Process {
        id: cleanup
        command: ["sh", "-c", 'rm -f "$1"/lock-*.png', "sh", root.shotDir]
    }

    // Unlocking ---------------------------------------------------------------
    // Called by the surfaces when Enter is pressed.
    function submit() {
        if (busy || buffer === "") return
        pending = buffer
        buffer = ""
        error = ""
        busy = true
        if (!pam.active && !pam.start()) {
            busy = false
            pending = ""
            error = "Couldn't start authentication"
        }
    }

    // The password waiting for PAM to ask for it.
    property string pending: ""

    PamContext {
        id: pam

        onPamMessage: {
            if (responseRequired) {
                respond(root.pending)
                root.pending = ""
            } else if (messageIsError && message !== "") {
                root.error = message
            }
        }

        onCompleted: result => {
            root.busy = false
            root.pending = ""
            if (result === PamResult.Success) {
                root.error = ""
                sessionLock.locked = false
                cleanup.running = true
            } else if (result === PamResult.MaxTries) {
                root.error = "Too many attempts, try again later"
            } else if (result === PamResult.Failed) {
                root.error = "Incorrect password"
            } else if (root.error === "") {
                root.error = "Authentication error"
            }
        }
    }

    WlSessionLock {
        id: sessionLock

        LockSurface {}
    }

    IpcHandler {
        target: "lock"

        function lock(): void { root.lock() }
        function isLocked(): bool { return root.locked }
    }
}
