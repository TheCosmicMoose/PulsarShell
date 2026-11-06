import QtQuick
import "../../theme"
import "../../services"

Gauge {
    value:      SystemMonitor.cpuPercent
    icon:       ""
    trackColor: Theme.accentBlue
    fillColor:  Theme.highlightBlue
}
