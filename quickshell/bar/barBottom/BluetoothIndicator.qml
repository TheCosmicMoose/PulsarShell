import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../../theme"
import "../../flyouts"

Text {
    id: root
    width: Theme.barButtonWidth
    horizontalAlignment: Text.AlignHCenter

    color: {
        if (connected) return Theme.textPrimary
        if (adapterOn) return Theme.textSecondary
        else return Theme.textBg
    }
    font.family: Theme.fontFamilyAlt
    font.pointSize: Theme.fontSizePrimary

    //Icons
    readonly property string bluetoothConnected: "󰂱"
    readonly property string bluetoothDisconnected: "󰂯"
    readonly property string bluetoothDisabled: "󰂲"

    readonly property var connectedDevices: Bluetooth.devices.values.find(d => d.connected === true)
    readonly property var enabledAdapters: Bluetooth.adapters.values.find(d => d.enabled === true)

    readonly property bool connected: connectedDevices !== undefined
    // Not named "enabled": that would shadow Item.enabled, which turns off input.
    readonly property bool adapterOn: enabledAdapters !== undefined

    text: {
        if(connected) return bluetoothConnected
        if(adapterOn) return bluetoothDisconnected
        else return bluetoothDisabled
    }

    // Click to open the bluetooth flyout beside this icon.
    Component {
        id: flyoutComponent
        BluetoothFlyout {}
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: QsWindow.window.toggleFlyout(root, flyoutComponent)
    }
}
