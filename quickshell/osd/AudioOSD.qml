import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import Quickshell.Hyprland
import "../theme"
import "../services"

Scope {
    id: root

    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink ]
    }

    property bool open: false
    property var targetScreen: null

    // Opens on the currently focused monitor. Each call restarts the hide
    // timer, so holding the volume key keeps the OSD up.
    function show() {
        const name = Hyprland.focusedMonitor?.name
        targetScreen = Quickshell.screens.find(s => s.name === name) || Quickshell.screens[0]
        open = true
        hideTimer.restart()
    }

    function hide() {
        open = false
    }

    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: root.hide()
    }

    // IPC handler to plug into the Hyprland audio keybinds so that
    // the OSD only appears when volume is adjusted through keybinds,
    // not from the flyout menu sliders.
    IpcHandler {
        target: "audioosd"

        function show(): void { root.show() }
    }

    LazyLoader {
        active: root.open

        PanelWindow {
            id: osd

            screen: root.targetScreen
            anchors.bottom: true
            margins.bottom: osd.screen ? osd.screen.height / 20 : 0
            exclusiveZone: 0
            WlrLayershell.namespace: "pulsar-osd"
            WlrLayershell.layer: WlrLayer.Overlay

            implicitWidth: Theme.barButtonWidth * 8
            implicitHeight: Theme.barThickness
            color: "transparent"

            // Empty input region: clicks pass straight through the OSD.
            mask: Region {}

            Rectangle {
                anchors.fill: parent
                radius: Theme.barRadius
                color: Theme.bgModule
                border.width: 2
                border.color: Theme.accentBlue
                border.pixelAligned: true

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: Theme.horizontalPadding
                        rightMargin: Theme.horizontalPadding
                    }
                    spacing: 25

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text:           AudioService.audioIcon + " | " + AudioService.deviceIcon
                        font.family:    Theme.fontFamily
                        font.pointSize: Theme.fontSizeLarge
                        color:          Theme.textPrimary
                    }

                    // Volume track spanning the remaining width.
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredHeight: Theme.fontSizeSmall
                        radius: Theme.barButtonRadius
                        color:  Theme.textBg

                        // Filled part: the current volume (capped at 100%).
                        Rectangle {
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            width: parent.width * Math.min(1, AudioService.volume)
                            radius: parent.radius
                            color: Theme.textPrimary
                        }
                    }
                }
            }
        }
    }
}
