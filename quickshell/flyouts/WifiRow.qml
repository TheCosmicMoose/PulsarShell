pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Networking
import "../theme"
import "common"

// One Wi-Fi network in the network flyout.
//   Known network:     click toggles the connection.
//   Unknown network:   click shows a Connect button, or a password box for
//                      WPA/WPA2/WPA3-Personal networks.
// If a connection needs a (new) password, the password box opens.
ListRow {
    id: row

    required property var network
    property bool showPassword: false
    property string error: ""

    readonly property int security: network.security
    readonly property bool isOpen: security === WifiSecurityType.Open || security === WifiSecurityType.Owe
    readonly property bool usesPassword: security === WifiSecurityType.WpaPsk
                                         || security === WifiSecurityType.Wpa2Psk
                                         || security === WifiSecurityType.Sae
    readonly property bool unsupported: !isOpen && !usesPassword

    // Index 0 = weakest, 4 = strongest (same glyphs as the bar icon).
    readonly property var bars: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]

    icon: bars[Math.min(4, Math.floor(network.signalStrength * 5))]
    title: network.name
    trailing: isOpen ? "" : "󰌾"      // lock
    active: network.connected
    subtitle: {
        if (network.stateChanging) return network.connected ? "Disconnecting..." : "Connecting..."
        if (error !== "") return error
        if (network.connected) return "Connected"
        return ""
    }

    function connect() {
        error = ""
        if (network.known || isOpen) network.connect()
        else if (usesPassword) { showPassword = true; passwordField.focusInput() }
    }

    function submitPassword(psk) {
        if (psk === "") return
        error = ""
        network.connectWithPsk(psk)
        passwordField.text = ""
    }

    onClicked: {
        if (network.known) {
            // Known networks toggle straight away.
            error = ""
            if (network.connected) network.disconnect()
            else network.connect()
        } else {
            expanded = !expanded
        }
    }

    Connections {
        target: row.network

        function onConnectionFailed(reason) {
            if (reason === ConnectionFailReason.NoSecrets) {
                row.error = row.network.known ? "Password needed" : "Wrong password"
                if (row.usesPassword) {
                    row.expanded = true
                    row.showPassword = true
                    passwordField.focusInput()
                }
            } else if (reason === ConnectionFailReason.WifiAuthTimeout) {
                row.error = "Timed out"
            } else if (reason === ConnectionFailReason.WifiNetworkLost) {
                row.error = "Network out of range"
            } else {
                row.error = "Couldn't connect"
            }
        }

        function onConnectedChanged() {
            if (row.network.connected) {
                row.error = ""
                row.showPassword = false
                row.expanded = false
            }
        }
    }

    // Expanded area ---------------------------------------------------------------
    InputField {
        id: passwordField
        width: parent.width
        visible: row.showPassword
        password: true
        placeholder: "Password"
        onAccepted: t => row.submitPassword(t)
    }

    Text {
        width: parent.width
        visible: row.unsupported
        wrapMode: Text.Wrap
        text: "This network needs settings this menu can't set (enterprise or WEP). Use nm-connection-editor."
        color: Theme.textBg
        font.family: Theme.fontFamily
        font.pointSize: Theme.fontSizeSmall
    }

    Row {
        spacing: 8
        visible: !row.unsupported

        FlyoutButton {
            text: "Connect"
            enabled: !row.network.stateChanging && (!row.showPassword || passwordField.text !== "")
            onClicked: row.showPassword ? row.submitPassword(passwordField.text) : row.connect()
        }

        FlyoutButton {
            visible: row.network.known
            text: "Forget"
            accent: Theme.accentRed
            onClicked: row.network.forget()
        }
    }
}
