import QtQuick
import Quickshell
import "../../theme"

// Vertical clock: hours, a divider glyph, then minutes. The minutes change
// color through the evening and night.
Column {
    id: root

    width: Theme.barButtonWidth

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property int timeHours:   clock.hours
    readonly property int timeMinutes: clock.minutes

    function pad(n) { return n < 10 ? "0" + n : "" + n }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        font.family:    Theme.fontFamily
        font.pointSize: Theme.fontSizePrimary
        color:          Theme.textPrimary
        text:           root.pad(root.timeHours)
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        font.family:    Theme.fontFamilyAlt   // glyph, like the bar icons
        font.pointSize: Theme.fontSizePrimary
        color:          Theme.textSecondary
        text:           ""
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        font.family:    Theme.fontFamily
        font.pointSize: Theme.fontSizePrimary
        color: {
            const h = root.timeHours
            if (h >= 22 || h <= 5) return Theme.highlightPurple
            if (h >= 20 || h <= 6) return Theme.highlightRed
            if (h >= 19 || h <= 7) return Theme.highlightOrange
            if (h >= 18 || h <= 8) return Theme.highlightYellow
            if (h >= 17 || h <= 9) return Theme.highlightAqua
            return Theme.highlightBlue
        }
        text: root.pad(root.timeMinutes)
    }
}
