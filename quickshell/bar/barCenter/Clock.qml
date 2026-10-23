import QtQuick
import Quickshell
import Quickshell.Io
import "../../theme"

Column {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
    property int timeHours:     clock.hours
    property int timeMinutes:   clock.minutes



}
