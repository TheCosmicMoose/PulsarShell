import QtQuick
import "../../theme"

// Horizontal 0-1 slider. Like ToggleSwitch it doesn't store the value itself:
// dragging, clicking or scrolling emits moved(value) and the owner applies it.
Item {
    id: root

    property real value: 0
    property real step: 0.05            // per scroll notch
    property color fillColor: Theme.accentBlue
    signal moved(real value)

    // While dragging, show where the handle is rather than waiting for the
    // owner's value to catch up.
    property real dragValue: 0
    readonly property real shown: mouse.pressed ? dragValue : Math.max(0, Math.min(1, value))

    implicitWidth: 200
    implicitHeight: 20

    function clamp(v) { return Math.max(0, Math.min(1, v)) }
    function setFromX(x) {
        dragValue = clamp((x - handle.width / 2) / (width - handle.width))
        moved(dragValue)
    }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: height / 2
        color: Theme.textBg

        Rectangle {
            width: handle.x + handle.width / 2
            height: parent.height
            radius: parent.radius
            color: root.fillColor
        }
    }

    Rectangle {
        id: handle
        anchors.verticalCenter: parent.verticalCenter
        width: 14
        height: 14
        radius: width / 2
        x: root.shown * (root.width - width)
        color: Theme.textPrimary
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        onPressed: e => root.setFromX(e.x)
        onPositionChanged: e => { if (pressed) root.setFromX(e.x) }
        onWheel: e => root.moved(root.clamp(root.value + (e.angleDelta.y > 0 ? root.step : -root.step)))
    }
}
