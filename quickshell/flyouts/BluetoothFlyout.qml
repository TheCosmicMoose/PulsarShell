pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../theme"
import "../services"
import "common"

// Bluetooth flyout:
//   "Bluetooth" header, switch = adapter on/off
//   a pairing prompt when the pairing agent needs an answer
//   connected devices; click one for a Disconnect button
//   available devices (paired and newly found); click one for Connect or
//   Pair & connect (and Forget for paired ones)
// The adapter scans for new devices while the flyout is open.
Column {
    id: root

    readonly property int panelWidth: 320

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter?.enabled ?? false
    readonly property var devices: adapter ? adapter.devices.values : []

    readonly property var connectedDevices: devices.filter(d => d.connected)
    // Paired devices first, then new ones; skip nameless devices nearby.
    readonly property var availableDevices: devices
        .filter(d => !d.connected && (d.paired || d.deviceName !== ""))
        .sort((a, b) => (b.paired - a.paired) || a.name.localeCompare(b.name))
        .slice(0, 12)

    // The row showing its buttons (by address); one at a time.
    property string expanded: ""
    // Devices to connect to as soon as pairing finishes.
    property var connectAfterPair: []

    function toggleExpanded(address) {
        expanded = expanded === address ? "" : address
    }

    function pairAndConnect(device) {
        if (device.paired) {
            device.connect()
            return
        }
        connectAfterPair = connectAfterPair.concat([device.address])
        device.pair()
    }

    function onPaired(device) {
        if (!connectAfterPair.includes(device.address)) return
        connectAfterPair = connectAfterPair.filter(a => a !== device.address)
        device.trusted = true           // reconnect without asking next time
        device.connect()
    }

    // Glyph for a device, from its freedesktop icon name.
    function iconFor(device) {
        const icon = device.icon ?? ""
        if (icon.includes("headset") || icon.includes("headphone")) return "󰋋"
        if (icon.startsWith("audio")) return "󰓃"
        if (icon.includes("mouse")) return "󰍽"
        if (icon.includes("keyboard")) return "󰌌"
        if (icon.includes("gaming")) return "󰊴"
        if (icon.includes("phone")) return "󰄜"
        if (icon.includes("computer")) return "󰌢"
        return "󰂯"
    }

    function statusOf(device) {
        if (device.pairing) return "Pairing..."
        if (device.state === BluetoothDeviceState.Connecting) return "Connecting..."
        if (device.state === BluetoothDeviceState.Disconnecting) return "Disconnecting..."
        if (device.connected && device.batteryAvailable) return "Battery " + Math.round(device.battery * 100) + "%"
        if (device.paired) return "Paired"
        return ""
    }

    // Scan while open (and the adapter is on).
    function updateScan() {
        if (adapter && adapter.enabled && !adapter.discovering) adapter.discovering = true
    }
    onPoweredChanged: updateScan()
    Component.onCompleted: {
        BluetoothAgent.viewers++
        updateScan()
    }
    Component.onDestruction: {
        BluetoothAgent.viewers--
        if (adapter && adapter.discovering) adapter.discovering = false
    }

    spacing: Theme.barSpacing

    FlyoutHeader {
        width: root.panelWidth
        title: "Bluetooth"
        enabled: root.adapter !== null
        checked: root.powered
        onToggled: root.adapter.enabled = !root.adapter.enabled
    }

    Text {
        width: root.panelWidth
        visible: !root.powered
        text: root.adapter === null ? "No Bluetooth adapter found" : "Bluetooth is off"
        color: Theme.textBg
        font.family: Theme.fontFamily
        font.pointSize: Theme.fontSizePrimary
    }

    // Pairing prompt ---------------------------------------------------------------
    Rectangle {
        id: prompt

        readonly property var req: BluetoothAgent.request
        readonly property string type: req?.type ?? ""

        width: root.panelWidth
        height: promptColumn.implicitHeight + 20
        visible: req !== null
        radius: Theme.barButtonRadius
        color: Theme.bgModule
        border.width: 1
        border.color: Theme.accentYellow

        onReqChanged: {
            codeField.text = ""
            if (type === "pin" || type === "passkey") codeField.focusInput()
        }

        Column {
            id: promptColumn
            x: 10
            y: 10
            width: parent.width - 20
            spacing: 8

            Text {
                width: parent.width
                wrapMode: Text.Wrap
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pointSize: Theme.fontSizePrimary
                text: {
                    const r = prompt.req
                    if (!r) return ""
                    switch (r.type) {
                    case "confirm":   return "Pair with " + r.name + "? Check that this code is shown on the device:"
                    case "authorize": return "Allow " + r.name + " to pair with this computer?"
                    case "pin":       return "Enter the PIN for " + r.name + " (often 0000 or 1234):"
                    case "passkey":   return "Enter the passkey shown on " + r.name + ":"
                    case "display-pin":
                    case "display-passkey":
                        return "Type this code on " + r.name + ", then press Enter on it:"
                    }
                    return ""
                }
            }

            // The code to compare or type on the device
            Text {
                visible: prompt.type === "confirm" || prompt.type.startsWith("display")
                text: prompt.req?.passkey ?? prompt.req?.pin ?? ""
                color: Theme.highlightYellow
                font.family: Theme.fontFamily
                font.pointSize: Theme.fontSizeHeader
                font.bold: true
                font.letterSpacing: 4
            }

            InputField {
                id: codeField
                width: parent.width
                visible: prompt.type === "pin" || prompt.type === "passkey"
                placeholder: prompt.type === "passkey" ? "6-digit passkey" : "PIN"
                inputMethodHints: prompt.type === "passkey" ? Qt.ImhDigitsOnly : Qt.ImhNone
                onAccepted: t => { if (t !== "") BluetoothAgent.respond(t) }
            }

            Row {
                spacing: 8

                FlyoutButton {
                    visible: prompt.type === "confirm" || prompt.type === "authorize"
                    text: prompt.type === "confirm" ? "Pair" : "Allow"
                    onClicked: BluetoothAgent.respond("yes")
                }
                FlyoutButton {
                    visible: prompt.type === "pin" || prompt.type === "passkey"
                    enabled: codeField.text !== ""
                    text: "OK"
                    onClicked: BluetoothAgent.respond(codeField.text)
                }
                FlyoutButton {
                    text: prompt.type.startsWith("display") ? "Done" : "Cancel"
                    accent: Theme.accentGray
                    onClicked: BluetoothAgent.dismiss()
                }
            }
        }
    }

    // Connected devices ------------------------------------------------------------
    SectionLabel {
        width: root.panelWidth
        visible: root.powered && root.connectedDevices.length > 0
        text: "Connected"
    }

    Repeater {
        model: ScriptModel { values: root.powered ? root.connectedDevices : [] }

        delegate: ListRow {
            id: connectedRow
            required property var modelData

            width: root.panelWidth
            icon: root.iconFor(modelData)
            title: modelData.name
            subtitle: root.statusOf(modelData)
            active: true
            expanded: root.expanded === modelData.address
            onClicked: root.toggleExpanded(modelData.address)

            FlyoutButton {
                text: "Disconnect"
                accent: Theme.accentRed
                onClicked: connectedRow.modelData.disconnect()
            }
        }
    }

    // Available devices --------------------------------------------------------------
    Item {
        width: root.panelWidth
        height: availableLabel.implicitHeight
        visible: root.powered

        SectionLabel {
            id: availableLabel
            anchors.left: parent.left
            text: "Available"
        }

        SectionLabel {
            anchors.right: parent.right
            visible: root.adapter?.discovering ?? false
            text: "Scanning..."
            font.bold: false
        }
    }

    Repeater {
        model: ScriptModel { values: root.powered ? root.availableDevices : [] }

        delegate: ListRow {
            id: availableRow
            required property var modelData

            width: root.panelWidth
            icon: root.iconFor(modelData)
            title: modelData.name
            subtitle: root.statusOf(modelData)
            expanded: root.expanded === modelData.address
            onClicked: root.toggleExpanded(modelData.address)

            // Finish "Pair & connect" once BlueZ reports the device paired.
            Connections {
                target: availableRow.modelData
                function onPairedChanged() {
                    if (availableRow.modelData.paired) root.onPaired(availableRow.modelData)
                }
            }

            Row {
                spacing: 8

                FlyoutButton {
                    enabled: !availableRow.modelData.pairing
                             && availableRow.modelData.state !== BluetoothDeviceState.Connecting
                    text: availableRow.modelData.paired ? "Connect" : "Pair & connect"
                    onClicked: root.pairAndConnect(availableRow.modelData)
                }

                FlyoutButton {
                    visible: availableRow.modelData.pairing
                    text: "Cancel"
                    accent: Theme.accentGray
                    onClicked: availableRow.modelData.cancelPair()
                }

                FlyoutButton {
                    visible: availableRow.modelData.paired
                    text: "Forget"
                    accent: Theme.accentRed
                    onClicked: availableRow.modelData.forget()
                }
            }
        }
    }

    Text {
        width: root.panelWidth
        visible: root.powered && root.availableDevices.length === 0
        text: "No devices found yet"
        color: Theme.textBg
        font.family: Theme.fontFamily
        font.pointSize: Theme.fontSizeSmall
    }
}
