pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Runs pulsar-btagent (services/cmd/btagent), the BlueZ pairing agent, and
// holds whatever it is currently asking. The Bluetooth flyout shows the
// request and answers it with respond().
//
// request is null, or one of:
//   { type: "confirm",  name, passkey }  -> respond("yes" / "no")
//   { type: "authorize", name }          -> respond("yes" / "no")
//   { type: "pin",      name }           -> respond(pin), or respond("") to refuse
//   { type: "passkey",  name }           -> respond(number), or respond("") to refuse
//   { type: "display-pin", name, pin }   -> dismiss()  (type it on the device)
//   { type: "display-passkey", name, passkey } -> dismiss()
Singleton {
    id: root

    readonly property string bin: Quickshell.env("HOME") + "/.local/bin/pulsar-btagent"

    property var request: null
    property bool ready: false          // registered with bluetoothd

    // Number of open Bluetooth flyouts. With none open, a pairing request also
    // sends a notification so it isn't missed.
    property int viewers: 0

    function needsAnswer(type) {
        return type === "confirm" || type === "authorize" || type === "pin" || type === "passkey"
    }

    function respond(answer) {
        if (!request) return
        if (needsAnswer(request.type)) proc.write(request.id + " " + answer + "\n")
        request = null
    }

    function dismiss() {
        if (request && needsAnswer(request.type)) respond("")
        else request = null
    }

    function handle(line) {
        let m
        try { m = JSON.parse(line) } catch (e) { return }

        if (m.type === "ready") {
            ready = true
            failures = 0
        } else if (m.type === "cancel") {
            if (m.id === 0 || request?.id === m.id) request = null
        } else {
            request = m
            if (viewers === 0 && needsAnswer(m.type)) {
                Quickshell.execDetached(["notify-send", "-a", "Bluetooth", "-i", "bluetooth",
                    "Pairing request", m.name + " wants to pair. Open the Bluetooth menu to respond."])
            }
        }
    }

    // Restart the agent if it exits, backing off, and give up after a few
    // quick failures (e.g. the binary isn't installed).
    property int failures: 0

    Process {
        id: proc
        command: [root.bin]
        running: true
        stdinEnabled: true

        stdout: SplitParser {
            onRead: line => root.handle(line)
        }
        stderr: SplitParser {
            onRead: line => console.warn(line)
        }

        onExited: (code, status) => {
            root.ready = false
            root.request = null
            root.failures++
            if (root.failures <= 5) restart.start()
            else console.warn("pulsar-btagent keeps exiting; Bluetooth pairing prompts are off. Is it installed at", root.bin + "?")
        }
    }

    Timer {
        id: restart
        interval: 2000 * root.failures
        onTriggered: proc.running = true
    }
}
