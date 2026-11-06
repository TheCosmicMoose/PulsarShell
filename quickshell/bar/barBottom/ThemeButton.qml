import QtQuick
import Quickshell
import "../../theme"
import "../../flyouts"
import "../../wallpaper"

// Theme button.
//   Left click  -> theme flyout (pick a theme)
//   Right click -> wallpaper picker
Text {
    id: root

    readonly property bool hovered: mouse.containsMouse

    width: Theme.barButtonWidth
    horizontalAlignment: Text.AlignHCenter
    font.family: Theme.fontFamily
    font.pointSize: Theme.fontSizePrimary
    color: hovered ? Theme.highlightBlue : Theme.textPrimary
    text: "󰏘"

    Component {
        id: flyoutComponent
        ThemeFlyout {}
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            if (event.button === Qt.RightButton) {
                QsWindow.window.closeFlyout()
                WallpaperPicker.show()
            } else {
                QsWindow.window.toggleFlyout(root, flyoutComponent)
            }
        }
    }
}
