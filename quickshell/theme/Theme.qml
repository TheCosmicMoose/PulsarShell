pragma Singleton
import QtQuick
import "./"

QtObject {
    id: themeManager

    //installed themes go here
    property var rMSTheme:          RockyMountainSunset
    //
    property var curTheme:          rMSTheme

    //Background Colors
    property color bgPrimary:       curTheme.bgPrimary
    property color bgSecondary:     curTheme.bgSecondary
    property color bgModule:        curTheme.bgModule
    //Text Color
    property color textPrimary:     curTheme.textPrimary
    property color textSecondary:   curTheme.textSecondary
    property color textContrast:    curTheme.textContrast
    //Accent Color
    property color accentRed:       curTheme.accentRed
    property color highlightRed:    curTheme.highlightRed
    property color accentOrange:    curTheme.accentOrange
    property color highlightOrange: curTheme.highlightOrange
    property color accentYellow:    curTheme.accentYellow
    property color highlightYellow: curTheme.highlightYellow
    property color accentGreen:     curTheme.accentGreen
    property color highlightGreen:  curTheme.highlightGreen
    property color accentAqua:      curTheme.accentAqua
    property color highlightAqua:   curTheme.highlightAqua
    property color accentLightBlue: curTheme.accentLightBlue
    property color highlightLightBlue: curTheme.highlightLightBlue
    property color accentBlue:      curTheme.accentBlue
    property color highlightBlue:   curTheme.highlightBlue
    property color accentPurple:    curTheme.accentPurple
    property color highlightPurple: curTheme.highlightPurple
    property color accentGray:      curTheme.accentGray
    property color highlightGray:   curTheme.highlightGray

    //Alpha Channels
    property real alphaBG:          curTheme.alphaBG
    property real alphaAccent:      curTheme.alphaAccent
    property real alphaHighlight:   curTheme.alphaHighlight

    //Font
    property string fontFamily:         curTheme.fontFamily
    property string fontSizePrimary:    curTheme.fontSizePrimary
    property string fontSizeLarge:      curTheme.fontSizeLarge
    property string fontSizeSmall:      curTheme.fontSizeSmall

    //Border and Window Metrics
    //Bar Size
    property int barThickness:      curTheme.barThickness
    property int barSpacing:        curTheme.barSpacing
    property int edgeMargin:        curTheme.edgeMargin
    property int vertPadding:       curTheme.vertPadding
    property int horizontalPadding: curTheme.horizontalPadding
    //Button Size
    property int barButtonWidth:    curTheme.buttonWidth
    property int barButtonHeight:   curTheme.buttonHeight
    //Rounding
    property int barRadius:         curTheme.barRadius
    property int barButtonRadius:   curTheme.buttonRadius

    //Animations
    property int animDuration:      curTheme.animDuration
    property int animLong:          curTheme.animLong
    property int animShort:         curTheme.animShort
}
