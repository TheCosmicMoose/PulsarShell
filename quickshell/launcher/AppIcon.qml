import QtQuick
import Quickshell
import Quickshell.Widgets
import "../theme"

// An app's icon, or a tidy fallback when it has none.
//
// Quickshell draws a magenta/black "missing" texture for icon names that
// aren't in the icon theme (including the usual application-x-executable
// fallback on many setups), so the name is checked first. Apps without a
// usable icon get a rounded tile with their first letter, colored from the
// theme's accents (the same color for the same app every time).
Item {
    id: root

    property string icon: ""        // desktop entry Icon= (theme name or file path)
    property string name: ""        // app name, for the letter tile
    property int size: 28

    implicitWidth: size
    implicitHeight: size

    readonly property bool isFile: icon.startsWith("/")
    readonly property bool hasIcon: icon !== "" && (isFile || Quickshell.hasThemeIcon(icon))

    IconImage {
        id: image
        anchors.fill: parent
        visible: root.hasIcon && status !== Image.Error
        source: !root.hasIcon ? ""
              : root.isFile ? "file://" + root.icon
              : Quickshell.iconPath(root.icon)
    }

    // Fallback: first letter on an accent-colored tile.
    Rectangle {
        anchors.fill: parent
        visible: !image.visible
        radius: Math.max(4, Theme.barButtonRadius)

        readonly property var accents: [Theme.accentBlue, Theme.accentAqua, Theme.accentGreen,
            Theme.accentYellow, Theme.accentOrange, Theme.accentRed, Theme.accentPurple]
        // Simple stable hash of the name.
        readonly property int hash: {
            let h = 0
            for (let i = 0; i < root.name.length; i++) h = (h * 31 + root.name.charCodeAt(i)) % 9973
            return h
        }
        color: accents[hash % accents.length]

        Text {
            anchors.centerIn: parent
            text: root.name.trim().charAt(0).toUpperCase() || "?"
            color: Theme.bgPrimary
            font.family: Theme.fontFamily
            font.pointSize: Math.max(8, Math.round(root.size * 0.42))
            font.bold: true
        }
    }
}
