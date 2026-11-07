import QtQuick
import Quickshell
import Quickshell.Networking
import "../../theme"
import "../../flyouts"

// Bar indicator for the network connection. Shows an icon for wired or Wi-Fi
// (with signal strength), and a different one when there's no connection.
Text {
    id: root

    width: Theme.barButtonWidth
    horizontalAlignment: Text.AlignHCenter

    color: {
        if(fullConnection) return Theme.textPrimary
        if(!wired && !wifi) return Theme.highlightRed
        else return Theme.highlightOrange
    }
    font.family: Theme.fontFamilyAlt
    font.pointSize: Theme.fontSizePrimary

    // Icons ------------------------------------------------------------
    readonly property string ethernetOnline:   "󰈀"
    readonly property string ethernetNoNet:    "󰈂"
    readonly property string wifiNoInternet:   "󰤫"
    readonly property string noNetwork:        "󰲛"
    // Index 0 = weakest (empty), 4 = strongest (full)
    readonly property var wifiBars: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]

    // Devices ----------------------------------------------------------
    // Look devices up by type
    readonly property var wiredDevice: Networking.devices.values.find(d => d.type === DeviceType.Wired)
    readonly property var wifiDevice:  Networking.devices.values.find(d => d.type === DeviceType.Wifi)

    readonly property bool wired: wiredDevice !== undefined && wiredDevice.connected
    readonly property bool wifi:  wifiDevice !== undefined && wifiDevice.connected

    // True when the system can actually reach the internet (not just a link).
    // If NetworkManager's connectivity check is off, connectivity stays Unknown;
    // treat any link as online then, rather than always showing "no internet".
    readonly property bool fullConnection: Networking.connectivity === NetworkConnectivity.Full
        || (Networking.connectivity === NetworkConnectivity.Unknown && (wired || wifi))

    // Wi-Fi details ------------------------------------------------------
    // wifiDevice.networks lists every network in range, so pick the one that is
    // actually connected rather than the first in the list.
    readonly property var wifiNetwork: wifiDevice !== undefined
        ? wifiDevice.networks.values.find(n => n.connected)
        : undefined
    readonly property string wifiName: wifiNetwork !== undefined ? wifiNetwork.name : ""
    readonly property real wifiStrength: wifiNetwork !== undefined ? wifiNetwork.signalStrength : 0   // 0.0 - 1.0

    // Wired takes priority when both are connected.
    text: {
        if (wired) return fullConnection ? ethernetOnline : ethernetNoNet
        if (wifi) {
            if (!fullConnection) return wifiNoInternet
            // 0.0-0.2 -> 0, 0.2-0.4 -> 1, ... 0.8-1.0 -> 4
            return wifiBars[Math.min(4, Math.floor(wifiStrength * 5))]
        }
        return noNetwork
    }

    // Click to open the network flyout beside this icon.
    Component {
        id: flyoutComponent
        NetworkFlyout {}
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: QsWindow.window.toggleFlyout(root, flyoutComponent)
    }
}
