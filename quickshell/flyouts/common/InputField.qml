import QtQuick
import "../../theme"

// One-line text box for flyouts (Wi-Fi passwords, Bluetooth PINs).
// Enter emits accepted(text).
Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: ""
    property bool password: false
    property alias inputMethodHints: input.inputMethodHints
    signal accepted(string text)

    function focusInput() { input.forceActiveFocus() }

    implicitWidth: 200
    implicitHeight: input.implicitHeight + 14
    radius: Theme.barButtonRadius
    color: Theme.bgPrimary
    border.width: 1
    border.color: input.activeFocus ? Theme.accentBlue : Theme.accentGray

    TextInput {
        id: input
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 8
        anchors.verticalCenter: parent.verticalCenter
        clip: true
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        passwordCharacter: "●"
        color: Theme.textPrimary
        selectionColor: Theme.selectionBg
        selectedTextColor: Theme.selectionFg
        font.family: Theme.fontFamily
        font.pointSize: Theme.fontSizePrimary
        onAccepted: root.accepted(text)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === ""
            text: root.placeholder
            color: Theme.textBg
            font: input.font
        }
    }

    // Clicking the box focuses it (the flyout only gets the keyboard once clicked).
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onPressed: e => { input.forceActiveFocus(); e.accepted = false }
    }
}
