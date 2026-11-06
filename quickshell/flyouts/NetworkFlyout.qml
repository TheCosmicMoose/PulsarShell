pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import "../theme"
import "common"

// Network flyout:
//   header: the connected network's name (or "Ethernet"), switch = Wi-Fi on/off
//   upload / download speed, then local IP / gateway
//   known Wi-Fi networks: click to connect or disconnect
//   other networks in range: click for Connect (and a password box if needed)
// The Wi-Fi card scans while the flyout is open.
Column {
    id: root

    readonly property int panelWidth: 320

    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDevice: Networking.devices.values.find(d => d.type === DeviceType.Wired) ?? null
    readonly property bool wired: wiredDevice?.connected ?? false
    readonly property var wifiNetwork: wifiDevice?.networks.values.find(n => n.connected) ?? null

    // The interface traffic and addresses are read from. Wired wins, like the bar icon.
    readonly property var activeDevice: wired ? wiredDevice : (wifiDevice?.connected ? wifiDevice : null)
    readonly property string iface: activeDevice?.name ?? ""

    readonly property var networks: (wifiDevice && Networking.wifiEnabled)
        ? wifiDevice.networks.values.filter(n => n.name !== "")
        : []
    readonly property var knownNetworks: networks
        .filter(n => n.known)
        .sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
    readonly property var otherNetworks: networks
        .filter(n => !n.known)
        .sort((a, b) => b.signalStrength - a.signalStrength)
        .slice(0, 12)

    // Scan while open.
    onWifiDeviceChanged: if (wifiDevice) wifiDevice.scannerEnabled = true
    Component.onCompleted: if (wifiDevice) wifiDevice.scannerEnabled = true
    Component.onDestruction: if (wifiDevice) wifiDevice.scannerEnabled = false

    spacing: Theme.barSpacing

    FlyoutHeader {
        width: root.panelWidth
        title: root.wired ? "Ethernet"
             : root.wifiNetwork ? root.wifiNetwork.name
             : "Not connected"
        enabled: root.wifiDevice !== null
        checked: Networking.wifiEnabled
        onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
    }

    // Throughput and addresses -------------------------------------------------------
    // Read once a second while the flyout is open: byte counters from /sys,
    // addresses from `ip`.
    QtObject {
        id: stats

        property real rxRate: 0         // bytes per second
        property real txRate: 0
        property string localIp: ""
        property string gateway: ""

        property real lastRx: -1
        property real lastTx: -1
        property real lastTime: 0

        function parse(text) {
            const [rx, tx, ip, gw] = text.split("\n")
            const now = Date.now()
            const rxBytes = parseFloat(rx), txBytes = parseFloat(tx)
            if (lastRx >= 0 && now > lastTime && rxBytes >= lastRx && txBytes >= lastTx) {
                const secs = (now - lastTime) / 1000
                rxRate = (rxBytes - lastRx) / secs
                txRate = (txBytes - lastTx) / secs
            }
            lastRx = rxBytes
            lastTx = txBytes
            lastTime = now
            localIp = ip && ip !== "-" ? ip : ""
            gateway = gw && gw !== "-" ? gw : ""
        }

        function reset() {
            rxRate = 0; txRate = 0; localIp = ""; gateway = ""
            lastRx = -1; lastTx = -1
        }
    }

    onIfaceChanged: stats.reset()

    Process {
        id: statsProc
        command: ["sh", "-c",
            's=/sys/class/net/$1/statistics; cat "$s/rx_bytes" "$s/tx_bytes"; ' +
            'ip=$(ip -4 -o addr show dev "$1" | awk \'{print $4}\' | cut -d/ -f1 | head -n1); echo "${ip:--}"; ' +
            'gw=$(ip -4 route show default dev "$1" | awk \'{print $3; exit}\'); echo "${gw:--}"',
            "sh", root.iface]
        stdout: StdioCollector {
            onStreamFinished: stats.parse(text)
        }
    }

    Timer {
        interval: 1000
        running: root.iface !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: statsProc.running = true
    }

    function formatRate(bytesPerSec) {
        const units = ["B/s", "KB/s", "MB/s", "GB/s"]
        let v = bytesPerSec, i = 0
        while (v >= 1000 && i < units.length - 1) { v /= 1000; i++ }
        return (i === 0 ? Math.round(v) : v.toFixed(1)) + " " + units[i]
    }

    Column {
        width: root.panelWidth
        spacing: 4
        visible: root.iface !== ""

        Row {
            width: parent.width

            StatText { width: parent.width / 2; text: "󰕒  " + root.formatRate(stats.txRate) }
            StatText { width: parent.width / 2; text: "󰇚  " + root.formatRate(stats.rxRate) }
        }

        Row {
            width: parent.width

            StatText { width: parent.width / 2; text: "IP  " + (stats.localIp || "-") }
            StatText { width: parent.width / 2; text: "GW  " + (stats.gateway || "-") }
        }
    }

    component StatText: Text {
        elide: Text.ElideRight
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pointSize: Theme.fontSizeSmall
    }

    Text {
        width: root.panelWidth
        visible: root.wifiDevice !== null && !Networking.wifiEnabled
        text: "Wi-Fi is off"
        color: Theme.textBg
        font.family: Theme.fontFamily
        font.pointSize: Theme.fontSizePrimary
    }

    // Known networks ---------------------------------------------------------------
    SectionLabel {
        width: root.panelWidth
        visible: root.knownNetworks.length > 0
        text: "Known networks"
    }

    Repeater {
        model: ScriptModel { values: root.knownNetworks }

        delegate: WifiRow {
            required property var modelData
            network: modelData
            width: root.panelWidth
        }
    }

    // Other networks ----------------------------------------------------------------
    SectionLabel {
        width: root.panelWidth
        visible: root.otherNetworks.length > 0
        text: "Available networks"
    }

    Repeater {
        model: ScriptModel { values: root.otherNetworks }

        delegate: WifiRow {
            required property var modelData
            network: modelData
            width: root.panelWidth
        }
    }

    Text {
        width: root.panelWidth
        visible: Networking.wifiEnabled && root.wifiDevice !== null && root.networks.length === 0
        text: "Scanning..."
        color: Theme.textBg
        font.family: Theme.fontFamily
        font.pointSize: Theme.fontSizeSmall
    }
}
