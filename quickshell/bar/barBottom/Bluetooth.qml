import QtQuick
import Quickshell.Bluetooth
import "../../theme"

Text {
    id: root
    width: Theme.barButtonWidth
    horizontalAlignment: Text.AlignHCenter

    color: {
        if (connected) return Theme.textPrimary
        if (enabled) return Theme.textSecondary
        else return Theme.textBg
    }
    font.family: Theme.fontFamily
    font.pointSize: Theme.fontSizePrimary

    //Icons
    readonly property string bluetoothConnected: "󰂱"
    readonly property string bluetoothDisconnected: "󰂯"
    readonly property string bluetoothDisabled: "󰂲"

    readonly property var connectedDevices: Bluetooth.devices.values.find(d => d.connected === true)
    readonly property var enabledAdapters: Bluetooth.adapters.values.find(d => d.enabled === true)

    readonly property bool connected: connectedDevices !== undefined
    readonly property bool enabled: enabledAdapters !== undefined

    text: {
        if(connected) return bluetoothConnected
        if(enabled) return bluetoothDisconnected
        else return bluetoothDisabled
    }
}
