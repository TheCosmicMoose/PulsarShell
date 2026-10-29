import QtQuick
import Quickshell
import "../../theme"

Column {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
    property int timeHours:     clock.hours
    property int timeMinutes:   clock.minutes

    Text {
        id: hours
        anchors.horizontalCenter: parent
        font: {
            family:     Theme.fontFamily
            pointSize:  Theme.fontSizePrimary
        }
        color:          Theme.textPrimary
        text: {
            if(root.timeHours>=10) return root.timeHours
            else return "0" + root.timeHours
        }
    }
    Text {
        id: divider
        anchors.horizontalCenter: parent
        font: {
            family:     Theme.fontFamily
            pointSize:  Theme.fontSizePrimary
        }
        color:          Theme.textSecondary
        text:           ""
    }
    Text {
        id: minutes
        anchors.horizontalCenter: parent
        font: {
            family:     Theme.fontFamily
            pointSize:  Theme.fontSizePrimary
        }
        color: {
            if(root.timeHours>=22 || root.timeHours<=5) return Theme.highlightPurple
            if(root.timeHours>=20 || root.timeHours<=6) return Theme.highlightRed
            if(root.timeHours>=19 || root.timeHours<=7) return Theme.highlightOrange
            if(root.timeHours>=18 || root.timeHours<=8) return Theme.highlightYellow
            if(root.timeHours>=17 || root.timeHours<=9) return Theme.highlightAqua
            else return Theme.highlightBlue
        }
        text: {
            if(root.timeMinutes>=10) return root.timeMinutes
            else return "0" + root.timeMinutes
        }
    }
}
