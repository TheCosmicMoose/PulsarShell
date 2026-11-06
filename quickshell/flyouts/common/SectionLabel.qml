import QtQuick
import "../../theme"

// Small heading above a list in a flyout ("Connected", "Available", ...).
Text {
    topPadding: 4
    elide: Text.ElideRight
    color: Theme.textBg
    font.family: Theme.fontFamily
    font.pointSize: Theme.fontSizeSmall
    font.bold: true
}
