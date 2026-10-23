pragma Singleton
import QtQuick

QtObject {
    id: theme

    property string themeName: "rocky-mountain-sunset"

        //Background Colors
        property color bgPrimary:       "#322828"
        property color bgSecondary:     "#383228"
        property color bgModule:        "#484236"
        //Text Color
        property color textPrimary:     "#fbf1d0"
        property color textSecondary:   "#ede4c5"
        property color textContrast:    "#59564a"
        //Accent Color
        property color accentRed:       "#cc241d"
        property color highlightRed:    "#fb4934"
        property color accentOrange:    "#fe6e19"
        property color highlightOrange: "#fa8846"
        property color accentYellow:    "#ffd30d"
        property color highlightYellow: "#ffdf4f"
        property color accentGreen:     "#88981a"
        property color highlightGreen:  "#aeba30"
        property color accentAqua:      "#4f9d5c"
        property color highlightAqua:   "#5fba64"
        property color accentBlue:      "#40988e"
        property color highlightBlue:   "#4cb0a2"
        property color accentPurple:    "#b16286"
        property color highlightPurple: "#d3869b"
        property color accentGray:      "#868288"
        property color highlightGray:   "#a29692"
        //Alpha Channels
        property real alphaBG:          0.85
        property real alphaAccent:      0.95
        property real alphaHighlight:   0.95

        //Font
        property string fontFamily:     "JetbrainsMono Nerd Font Propo"
        property int fontSizePrimary:   12
        property int fontSizeLarge:     14
        property int fontSizeSmall:     10

        //Border and Window Metrics
        //Bar Size
        property int barThickness:      48
        property int barSpacing:        8
        property int edgeMargin:        8
        property int vertPadding:       16
        property int horizontalPadding: 16
        //Button Size
        property int barButtonWidth:        40
        property int barButtonHeight:       40
        property int barButtonHalfHeight:   20
        //Rounding
        property int barRadius:         24
        property int barButtonRadius:   20

        //Animations
        property int animDuration:      100
        property int animLong:          200
        property int animShort:         50
}
