pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../theme"
import "../services"

// Weather flyout, opened from the weather icon in the bar.
//
//   [icon]  51 °F            ⌖ BUIES CREEK
//           Partly cloudy    FEELS   WIND    HUMID
//                            45°F    9 mph   81%
//   ─────────────────────────────────────────────
//     [icon] SUNDAY     [icon] MONDAY    [icon] TUESDAY
//            61° 41°           71° 49°          73° 49°
//
// Everything comes from WeatherService (weather.json from pulsar-weather).
Column {
    id: root

    readonly property int panelWidth: 460
    readonly property int bigSize: Theme.fontSizeHeader * 2

    spacing: 14

    // No data yet ---------------------------------------------------------------
    Column {
        width: root.panelWidth
        spacing: 6
        visible: !WeatherService.hasData

        Text {
            text: "Weather"
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pointSize: Theme.fontSizeLarge
            font.bold: true
        }

        Text {
            width: parent.width
            wrapMode: Text.Wrap
            text: "No weather data yet. It's fetched when the shell starts and every 30 minutes; "
                + "check that pulsar-location and pulsar-weather are installed in ~/.local/bin."
            color: Theme.textBg
            font.family: Theme.fontFamily
            font.pointSize: Theme.fontSizeSmall
        }
    }

    // Current conditions ----------------------------------------------------------
    Item {
        width: root.panelWidth
        height: Math.max(current.implicitHeight, details.implicitHeight)
        visible: WeatherService.hasData

        // Left: icon, temperature, condition
        Row {
            id: current
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: WeatherService.icon
                color: Theme.textPrimary
                font.family: Theme.fontFamilyAlt
                font.pointSize: Math.round(root.bigSize * 0.8)
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter

                Row {
                    Text {
                        id: bigTemp
                        text: Math.round(WeatherService.temperatureF)
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pointSize: root.bigSize
                        font.bold: true
                    }

                    Text {
                        // Sits at the top of the big number, like a superscript.
                        anchors.top: parent.top
                        anchors.topMargin: bigTemp.height * 0.12
                        leftPadding: 4
                        text: "°F"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.fontSizeLarge
                    }
                }

                Text {
                    text: WeatherService.condition
                    color: Theme.textBg
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.fontSizeSmall
                }
            }
        }

        // Right: location and the three stats
        Column {
            id: details
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Row {
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ""      // map marker
                    color: Theme.textBg
                    font.family: Theme.fontFamilyAlt
                    font.pointSize: Theme.fontSizePrimary
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: WeatherService.town.toUpperCase()
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.fontSizePrimary
                    font.letterSpacing: 1.5
                }
            }

            Row {
                spacing: 28

                Stat { label: "Feels"; value: Math.round(WeatherService.feelsLikeF) + "°F" }
                Stat { label: "Wind";  value: Math.round(WeatherService.windMph) + " mph" }
                Stat { label: "Humid"; value: WeatherService.humidity + "%" }
            }
        }
    }

    // Divider
    Rectangle {
        width: root.panelWidth
        height: 1
        visible: WeatherService.hasData
        color: Theme.accentGray
        opacity: 0.5
    }

    // Forecast ------------------------------------------------------------------------
    Row {
        id: forecastRow

        width: root.panelWidth
        visible: WeatherService.hasData && WeatherService.forecast.length > 0

        Repeater {
            model: WeatherService.forecast

            delegate: Item {
                id: day

                required property var modelData

                // Equal columns, each day centered in its column.
                width: forecastRow.width / Math.max(1, WeatherService.forecast.length)
                height: dayContent.implicitHeight

                Row {
                    id: dayContent
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: day.modelData.icon
                        color: Theme.textPrimary
                        font.family: Theme.fontFamilyAlt
                        font.pointSize: Theme.fontSizeHeader
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: (day.modelData.day ?? "").toUpperCase()
                            color: Theme.textBg
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.fontSizeSmall
                            font.letterSpacing: 1.2
                        }

                        Row {
                            spacing: 8

                            Text {
                                text: day.modelData.high_f + "°"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pointSize: Theme.fontSizePrimary
                            }

                            Text {
                                text: day.modelData.low_f + "°"
                                color: Theme.textBg
                                font.family: Theme.fontFamily
                                font.pointSize: Theme.fontSizePrimary
                            }
                        }
                    }
                }
            }
        }
    }

    // Label over value ("FEELS" / "45°F")
    component Stat: Column {
        id: stat
        property string label
        property string value
        spacing: 4

        Text {
            text: stat.label.toUpperCase()
            color: Theme.textBg
            font.family: Theme.fontFamily
            font.pointSize: Theme.fontSizeSmall
            font.letterSpacing: 1.2
        }

        Text {
            text: stat.value
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pointSize: Theme.fontSizeLarge
        }
    }
}
