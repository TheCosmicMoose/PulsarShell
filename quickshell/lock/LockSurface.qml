pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../theme"

// What one monitor shows while locked: its pre-lock screenshot blurred, a
// clock with the date underneath in the middle, and the password box where
// the audio OSD appears.
//   type     -> password (shown as dots)
//   Enter    -> unlock
//   Escape   -> clear
WlSessionLockSurface {
    id: surface

    // Shown if there is no screenshot.
    color: Theme.bgPrimary

    // Background ----------------------------------------------------------------
    Image {
        id: shot
        anchors.fill: parent
        visible: false              // drawn through the blur below
        source: surface.screen ? "file://" + Lock.shotPath(surface.screen.name) : ""
        cache: false                // a new screenshot every lock
        fillMode: Image.Stretch
    }

    MultiEffect {
        anchors.fill: parent
        source: shot
        visible: shot.status === Image.Ready
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 1.0
        blurMax: 64
    }

    // Dim it a little so the text stands out on bright wallpapers.
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.bgPrimary, 0.35)
    }

    // Clock and date ------------------------------------------------------------
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        anchors.centerIn: parent
        spacing: Theme.barSpacing

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(clock.date, "hh:mm")
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pointSize: Theme.fontSizeHeader
            font.bold: true
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(clock.date, "dddd, MMMM d")
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pointSize: Theme.fontSizeLarge
        }
    }

    // Password box (same size and position as the audio OSD) ----------------------
    Rectangle {
        id: box

        readonly property bool hasError: Lock.error !== "" && Lock.buffer === ""

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: surface.height / 20
        width: Theme.barButtonWidth * 8
        height: Theme.barThickness
        radius: Theme.barRadius
        color: Theme.bgModule
        border.width: 2
        border.color: Lock.busy ? Theme.accentYellow
                    : hasError ? Theme.accentRed
                    : Theme.accentBlue
        border.pixelAligned: true

        Text {
            id: glyph
            anchors.left: parent.left
            anchors.leftMargin: Theme.horizontalPadding
            anchors.verticalCenter: parent.verticalCenter
            text: ""     // lock
            color: box.hasError ? Theme.highlightRed : Theme.textPrimary
            font.family: Theme.fontFamily
            font.pointSize: Theme.fontSizeLarge
        }

        Text {
            anchors.left: glyph.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: Theme.horizontalPadding
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pointSize: Theme.fontSizePrimary

            text: {
                if (Lock.busy) return "Checking..."
                if (Lock.buffer !== "") return "*".repeat(Math.min(Lock.buffer.length, 32))
                if (Lock.error !== "") return Lock.error
                return "Password"
            }
            color: {
                if (Lock.buffer !== "") return Theme.textPrimary
                if (box.hasError) return Theme.highlightRed
                return Theme.textBg
            }
        }
    }

    // Keyboard ------------------------------------------------------------------
    // Typing is collected here rather than in a TextInput so every monitor's
    // box shows the same password state, whichever one has keyboard focus.
    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Component.onCompleted: forceActiveFocus()

        Keys.onPressed: event => {
            const ctrl = event.modifiers & Qt.ControlModifier
            switch (event.key) {
            case Qt.Key_Return:
            case Qt.Key_Enter:
                Lock.submit()
                break
            case Qt.Key_Escape:
                Lock.buffer = ""
                break
            case Qt.Key_Backspace:
                Lock.buffer = ctrl ? "" : Lock.buffer.slice(0, -1)
                break
            default:
                if (Lock.busy) break
                if (ctrl && event.key === Qt.Key_U) { Lock.buffer = ""; break }
                // Printable text only; ignore Ctrl/Alt combos and control characters.
                if (!ctrl && !(event.modifiers & Qt.AltModifier)
                        && event.text.length > 0 && event.text.charCodeAt(0) >= 32) {
                    Lock.buffer += event.text
                }
            }
            event.accepted = true
        }
    }

    // Clicking anywhere gives this monitor the keyboard back.
    MouseArea {
        anchors.fill: parent
        onClicked: keys.forceActiveFocus()
    }
}
