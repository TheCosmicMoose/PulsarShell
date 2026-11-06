pragma ComponentBehavior: Bound
import QtQuick
import "../../theme"

// Speedometer-style ring gauge with a glyph in the middle. Shows the value as
// a number while hovered. CpuMeter and MemMeter are thin wrappers around this.
Rectangle {
    id: root

    property real value: 0              // 0-100
    property string icon: ""
    property color trackColor: Theme.accentBlue
    property color fillColor: Theme.highlightBlue

    readonly property bool showDetails: mouse.containsMouse
    readonly property real fraction: Math.max(0, Math.min(1, value / 100))

    width: Theme.barButtonWidth
    height: Theme.barButtonWidth
    radius: Theme.barButtonRadius
    color: Theme.bgModule

    Canvas {
        id: canvas

        readonly property real lineWidth: 3
        readonly property real gapAngle: 45     // degrees left open at the bottom

        anchors.fill: parent
        anchors.margins: 2
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()

            const cx = width / 2
            const cy = height / 2
            // Keep the stroke inside the canvas instead of clipping half of it.
            const r = Math.min(width, height) / 2 - lineWidth / 2
            const start = Math.PI / 2 + gapAngle * Math.PI / 180
            const total = (360 - 2 * gapAngle) * Math.PI / 180

            ctx.lineCap = "round"
            ctx.lineWidth = lineWidth

            ctx.strokeStyle = root.trackColor
            ctx.beginPath()
            ctx.arc(cx, cy, r, start, start + total, false)
            ctx.stroke()

            if (root.fraction > 0) {
                ctx.strokeStyle = root.fillColor
                ctx.beginPath()
                ctx.arc(cx, cy, r, start, start + total * root.fraction, false)
                ctx.stroke()
            }
        }
    }

    // Repaint when the value or the theme colors change.
    onFractionChanged: canvas.requestPaint()
    onTrackColorChanged: canvas.requestPaint()
    onFillColorChanged: canvas.requestPaint()

    Text {
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        font.family: Theme.fontFamily
        font.pointSize: Theme.fontSizeSmall
        font.bold: root.showDetails
        color: Theme.textPrimary
        text: root.showDetails ? Math.round(root.value) : root.icon
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
    }
}
