import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import Quickshell.Hyprland
import "../theme"

Scope {
    id: root

    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink ]
    }

    property bool open: false
    property var targetScreen: null
    //Opens on the currently focused monitor, and automatically starts
    // the autohide timer for the OSD.
    function show() {
        const name = Hyprland.focusedMonitor?.name
        targetScreen = Quickshell.screens.find(s => s.name === name) || Quickshell.screens[0]
        open = true
        audioOSDTimer.running = true
    }

    function hide() {
        open = false
    }

    Timer {
        id: audioOSDTimer
        interval: 2000
        onTriggered: root.hide()
    }
    // IPC handler to plug into the Hyprland audio keybinds so that
    // the OSD only appears when volume is adjusted through keybinds
    // not from the flyout menu sliders.
    IpcHandler {
        target: "audioosd"

        function show(): void { root.show() }
    }

    LazyLoader {
        active: root.open

        PanelWindow {
            anchors.bottom: true
            margins.bottom: screen.height/20
            exclusiveZone: 0

            implicitWidth: Theme.barButtonWidth * 8
            implicitHeight: Theme.barThickness
            color: "transparent"

            mask: Region {}

            Rectangle {
                anchors.fill: transparent
                radius: Theme.barRadius
                color: Theme.bgModule
                border.width: 2
                border.color: Theme.accentBlue
                border.pixelAligned: true

                RowLayout {
                    anchors {
                        fill: transparent
                        leftMargin: Theme.xPadding
                        rightMargin: Theme.xPadding
                    }
                    spacing: 25

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text:           ""
                        font.family:    Theme.fontFamily
                        color:          Theme.TextPrimary
                        font.pointSize: Theme.fontSizeLarge
                    }
                    // Empty volume bar that spans the remaining layout width.
                    Rectangle {
                        Layout.fillWidth: true

                        implicitHeight: Theme.fontSizeSmall
                        radius:         Theme.barButtonRadius
                        color:          Theme.textBg
                        //Bar that indicates the current volume
                        Rectangle {
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            implicitWidth: parent.width * (Pipewire.defaultAudioSink?.audio.volume ?? 0)
                            radius: parent.radius
                            color: Theme.textPrimary
                        }
                    }
                }
            }
        }
    }
}
