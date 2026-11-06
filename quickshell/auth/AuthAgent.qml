pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Polkit
import "../theme"

// Polkit authentication agent (replaces hyprpolkitagent; only one agent can
// be registered per session). When an app asks for elevated rights, a
// password box appears where the audio OSD does, with a line above it saying
// what is being authorized.
//   Enter  -> submit
//   Escape -> cancel the request
Scope {
    id: root

    property var targetScreen: null

    PolkitAgent {
        id: agent

        // Open on whichever monitor has focus when the request comes in.
        onAuthenticationRequestStarted: {
            const name = Hyprland.focusedMonitor?.name
            root.targetScreen = Quickshell.screens.find(s => s.name === name) || Quickshell.screens[0]
        }
    }

    LazyLoader {
        active: agent.isActive && agent.flow !== null

        PanelWindow {
            id: win

            readonly property var flow: agent.flow

            screen: root.targetScreen
            anchors.bottom: true
            margins.bottom: win.screen ? win.screen.height / 20 : 0
            exclusionMode: ExclusionMode.Ignore

            implicitWidth: Theme.barButtonWidth * 8
            implicitHeight: column.implicitHeight
            color: "transparent"

            WlrLayershell.namespace: "pulsar-auth"
            WlrLayershell.layer: WlrLayer.Overlay
            // Exclusive: typing goes to the password box until it closes.
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            // A new request (or a retry after a wrong password) starts empty.
            onFlowChanged: input.text = ""
            Connections {
                target: win.flow
                function onAuthenticationFailed() { input.text = "" }
            }

            Column {
                id: column
                width: parent.width
                spacing: Theme.barSpacing

                // What is asking ------------------------------------------------
                Rectangle {
                    width: parent.width
                    height: message.implicitHeight + 12
                    radius: Theme.barRadius
                    color: Qt.alpha(Theme.bgPrimary, Theme.alphaBG)

                    Text {
                        id: message
                        anchors.centerIn: parent
                        width: parent.width - 2 * Theme.horizontalPadding
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        text: win.flow?.message ?? ""
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.fontSizeSmall
                    }
                }

                // Password box (same size and look as the audio OSD) -------------
                Rectangle {
                    id: box

                    readonly property bool error: (win.flow?.failed ?? false)
                                                  || (win.flow?.supplementaryIsError ?? false)

                    width: parent.width
                    height: Theme.barThickness
                    radius: Theme.barRadius
                    color: Theme.bgModule
                    border.width: 2
                    border.color: error ? Theme.accentRed : Theme.accentBlue
                    border.pixelAligned: true

                    Text {
                        id: glyph
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.horizontalPadding
                        anchors.verticalCenter: parent.verticalCenter
                        text: ""     // lock
                        color: box.error ? Theme.highlightRed : Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.fontSizeLarge
                    }

                    TextInput {
                        id: input

                        anchors.left: glyph.right
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.horizontalPadding
                        anchors.verticalCenter: parent.verticalCenter

                        focus: true
                        clip: true
                        enabled: win.flow?.isResponseRequired ?? false
                        echoMode: (win.flow?.responseVisible ?? false) ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "●"
                        color: Theme.textPrimary
                        selectionColor: Theme.selectionBg
                        selectedTextColor: Theme.selectionFg
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.fontSizePrimary

                        Component.onCompleted: forceActiveFocus()

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                win.flow?.cancelAuthenticationRequest()
                                event.accepted = true
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (win.flow?.isResponseRequired) {
                                    win.flow.submit(input.text)
                                    input.text = ""
                                }
                                event.accepted = true
                            }
                        }

                        // Placeholder / status
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: input.text === ""
                            text: {
                                const f = win.flow
                                if (!f) return ""
                                if (f.supplementaryMessage !== "") return f.supplementaryMessage
                                if (f.failed) return "Incorrect password, try again"
                                if (!f.isResponseRequired) return "Waiting..."
                                return f.inputPrompt !== "" ? f.inputPrompt : "Password"
                            }
                            color: box.error ? Theme.highlightRed : Theme.textBg
                            elide: Text.ElideRight
                            width: parent.width
                            font: input.font
                        }
                    }
                }
            }
        }
    }
}
