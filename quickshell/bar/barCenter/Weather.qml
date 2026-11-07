import QtQuick
import "../../theme"
import "../../services"

// Bar indicator: shows the current condition glyph, and the temperature
// while hovered.
Text {
    id: root

    visible: WeatherService.hasData

    // A fixed width keeps the bar from shifting when the text swaps between
    // a glyph and "55°".
    width: Theme.barButtonWidth
    horizontalAlignment: Text.AlignHCenter

    font.family: Theme.fontFamilyAlt
    font.pointSize: Theme.fontSizePrimary
    color: Theme.textPrimary

    readonly property bool hovered: mouse.containsMouse

    text: hovered ? Math.round(WeatherService.temperatureF) + "°" : WeatherService.icon

    MouseArea {
        id: mouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
    }
}
