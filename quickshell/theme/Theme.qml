pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Theme singleton. Reads current_theme.json (written by the theme program)
// and exposes its values as flat properties, so the rest of the shell can keep
// using Theme.bgPrimary, Theme.barThickness, and so on.
//
// The default values inside the adapter below are a fallback: they're what the
// shell uses if the file is missing or a key is absent.
Singleton {
    id: root

    // Same location the Go program writes to (XDG_CONFIG_HOME, else ~/.config).
    readonly property string themePath: {
        const xdg = Quickshell.env("XDG_CONFIG_HOME")
        const base = xdg ? xdg : Quickshell.env("HOME") + "/.config"
        return base + "/pulsar_shell_theme/current_theme.json"
    }

    FileView {
        id: file
        path: root.themePath

        // Load synchronously on startup so the bar doesn't flash default colors.
        blockLoading: true
        // Re-read whenever the theme program rewrites the file.
        watchChanges: true
        onFileChanged: reload()

        // Each property name below must match a key in the JSON exactly.
        // Keys in the file that aren't listed here (hyprlandMetrics, zenColors,
        // the border colors) are simply ignored.
        JsonAdapter {
            id: json

            property string name: "Rocky Mountain Sunset"

            property JsonObject colors: JsonObject {
                property string bgPrimary:       "#322828"
                property string bgSecondary:     "#383228"
                property string bgModule:        "#484236"

                property string textPrimary:     "#fbf1d0"
                property string textSecondary:   "#ede4c5"
                property string textContrast:    "#59564a"
                property string textBg:          "#bdae93"

                property string accentRed:       "#cc241d"
                property string highlightRed:    "#fb4934"
                property string accentOrange:    "#fe6e19"
                property string highlightOrange: "#fa8846"
                property string accentYellow:    "#ffd30d"
                property string highlightYellow: "#ffdf4f"
                property string accentGreen:     "#88981a"
                property string highlightGreen:  "#aeba30"
                property string accentAqua:      "#4f9d5c"
                property string highlightAqua:   "#5fba64"
                property string accentBlue:      "#40988e"
                property string highlightBlue:   "#4cb0a2"
                property string accentPurple:    "#b16286"
                property string highlightPurple: "#d3869b"
                property string accentGray:      "#868288"
                property string highlightGray:   "#a29692"

                property string cursorBg:        "#fb4934"
                property string selectionBg:     "#cc241d"
                property string selectionFg:     "#fbf1d0"
            }

            property JsonObject transparency: JsonObject {
                property real alphaBarBg:                0.85
                property real alphaAccent:               0.95
                property real alphaHighlight:            0.95
                property real alphaActiveWindow:         1.0
                property real alphaInactiveWindow:       0.85
                property real alphaActiveWindowBorder:   1.0
                property real alphaInactiveWindowBorder: 0.75
                property real alphaTerminal:             0.85
            }

            property JsonObject font: JsonObject {
                property string fontFamily:      "JetBrainsMono Nerd Font"
                property string fontFamilyAlt:   "JetBrainsMono Nerd Font Propo"
                property int    fontSizePrimary: 12
                property int    fontSizeLarge:   14
                property int    fontSizeSmall:   10
            }

            property JsonObject quickshellMetrics: JsonObject {
                property int barThickness:        48
                property int barSpacing:          8
                property int edgeMargin:          8
                property int yPadding:            16
                property int xPadding:            16

                property int barButtonWidth:      40
                property int barButtonHeight:     40
                property int barButtonHalfHeight: 20

                property int barRadius:           24
                property int barButtonRadius:     20

                property int animDuration:        100
                property int animLong:            200
                property int animShort:           50
            }
        }
    }

    // ---- Public properties: the names the rest of the shell uses ----

    readonly property string themeName: json.name

    // Background colors
    readonly property color bgPrimary:       json.colors.bgPrimary
    readonly property color bgSecondary:     json.colors.bgSecondary
    readonly property color bgModule:        json.colors.bgModule
    // Text colors
    readonly property color textPrimary:     json.colors.textPrimary
    readonly property color textSecondary:   json.colors.textSecondary
    readonly property color textContrast:    json.colors.textContrast
    readonly property color textBg:          json.colors.textBg
    // Accent and highlight colors
    readonly property color accentRed:       json.colors.accentRed
    readonly property color highlightRed:    json.colors.highlightRed
    readonly property color accentOrange:    json.colors.accentOrange
    readonly property color highlightOrange: json.colors.highlightOrange
    readonly property color accentYellow:    json.colors.accentYellow
    readonly property color highlightYellow: json.colors.highlightYellow
    readonly property color accentGreen:     json.colors.accentGreen
    readonly property color highlightGreen:  json.colors.highlightGreen
    readonly property color accentAqua:      json.colors.accentAqua
    readonly property color highlightAqua:   json.colors.highlightAqua
    readonly property color accentBlue:      json.colors.accentBlue
    readonly property color highlightBlue:   json.colors.highlightBlue
    readonly property color accentPurple:    json.colors.accentPurple
    readonly property color highlightPurple: json.colors.highlightPurple
    readonly property color accentGray:      json.colors.accentGray
    readonly property color highlightGray:   json.colors.highlightGray
    // Cursor and selection colors
    readonly property color cursorBg:        json.colors.cursorBg
    readonly property color selectionBg:     json.colors.selectionBg
    readonly property color selectionFg:     json.colors.selectionFg

    // Alpha channels (alphaBG is the old name for alphaBarBg)
    readonly property real alphaBG:                  json.transparency.alphaBarBg
    readonly property real alphaAccent:              json.transparency.alphaAccent
    readonly property real alphaHighlight:           json.transparency.alphaHighlight
    readonly property real alphaActiveWindow:        json.transparency.alphaActiveWindow
    readonly property real alphaInactiveWindow:      json.transparency.alphaInactiveWindow
    readonly property real alphaActiveWindowBorder:  json.transparency.alphaActiveWindowBorder
    readonly property real alphaInactiveWindowBorder: json.transparency.alphaInactiveWindowBorder

    // Fonts (sizes are points: use font.pointSize, not font.pixelSize)
    readonly property string fontFamily:    json.font.fontFamily
    readonly property string fontFamilyAlt: json.font.fontFamilyAlt
    readonly property int fontSizePrimary:  json.font.fontSizePrimary
    readonly property int fontSizeLarge:    json.font.fontSizeLarge
    readonly property int fontSizeSmall:    json.font.fontSizeSmall

    // Bar size (vertPadding/horizontalPadding are the old names for yPadding/xPadding)
    readonly property int barThickness:       json.quickshellMetrics.barThickness
    readonly property int barSpacing:         json.quickshellMetrics.barSpacing
    readonly property int edgeMargin:         json.quickshellMetrics.edgeMargin
    readonly property int vertPadding:        json.quickshellMetrics.yPadding
    readonly property int horizontalPadding:  json.quickshellMetrics.xPadding
    // Button size
    readonly property int barButtonWidth:     json.quickshellMetrics.barButtonWidth
    readonly property int barButtonHeight:    json.quickshellMetrics.barButtonHeight
    readonly property int barButtonHalfHeight: json.quickshellMetrics.barButtonHalfHeight
    // Rounding
    readonly property int barRadius:          json.quickshellMetrics.barRadius
    readonly property int barButtonRadius:    json.quickshellMetrics.barButtonRadius

    // Animations
    readonly property int animDuration:       json.quickshellMetrics.animDuration
    readonly property int animLong:           json.quickshellMetrics.animLong
    readonly property int animShort:          json.quickshellMetrics.animShort
}
