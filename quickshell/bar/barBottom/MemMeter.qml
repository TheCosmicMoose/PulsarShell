import QtQuick
import "../../theme"
import "../../services"

Gauge {
    value:      SystemMonitor.memPercent
    icon:       ""
    trackColor: Theme.accentRed
    fillColor:  Theme.highlightRed
}
