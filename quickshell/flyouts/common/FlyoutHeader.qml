import QtQuick
import "../../theme"

// Flyout title with an on/off switch on the right.
Item {
    id: root

    property string title: ""
    property bool checked: false
    property bool showToggle: true
    signal toggled()

    implicitHeight: Math.max(label.implicitHeight, toggle.implicitHeight)

    Text {
        id: label
        anchors.left: parent.left
        anchors.right: toggle.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        text: root.title
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pointSize: Theme.fontSizeLarge
        font.bold: true
    }

    ToggleSwitch {
        id: toggle
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: root.showToggle
        enabled: root.enabled
        checked: root.checked
        onToggled: root.toggled()
    }
}
