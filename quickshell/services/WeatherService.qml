pragma Singleton
import Quickshell
import Quickshell.Io

// Weather singleton. Reads weather.json (written by the weather program) and
// exposes flat, camelCase properties for the widget.
//
//   WeatherService.temperatureF
//   WeatherService.forecast        -> array of 3 day objects (see below)
//   WeatherService.hasData         -> false until a file has been loaded
Singleton {
    id: root

    // The weather program writes to $XDG_STATE_HOME/pulsar_shell/weather.json,
    // which defaults to ~/.local/state/pulsar_shell/weather.json.
    readonly property string weatherPath: {
        const xdg = Quickshell.env("XDG_STATE_HOME")
        const base = xdg ? xdg : Quickshell.env("HOME") + "/.local/state"
        return base + "/pulsar_shell/weather.json"
    }

    FileView {
        id: file
        path: root.weatherPath

        blockLoading: true
        watchChanges: true
        onFileChanged: reload()

        // Property names must match the JSON keys exactly.
        JsonAdapter {
            id: json

            property string town: ""
            property string updated: ""

            property JsonObject current: JsonObject {
                property real   temperature_f:   0
                property real   feels_like_f:    0
                property string condition:       ""
                property string icon:            ""
                property int    weather_code:    0
                property bool   is_day:          true
                property real   wind_speed_mph:  0
                property int    humidity_percent: 0
            }

            // "forecast" is an array in the JSON, and a JsonObject can only
            // describe a single object. A var property holds the whole array as
            // plain JavaScript. Each element looks like:
            //   { day, date, condition, icon, weather_code,
            //     high_f, low_f, precip_chance_percent }
            property var forecast: []
        }
    }

    // ---- Public properties ----

    // The file hasn't been read (or doesn't exist) while "updated" is empty.
    readonly property bool hasData: json.updated !== ""
    readonly property string updated: json.updated
    readonly property string town: json.town

    readonly property real   temperatureF: json.current.temperature_f
    readonly property real   feelsLikeF:   json.current.feels_like_f
    readonly property string condition:    json.current.condition
    readonly property string icon:         json.current.icon
    readonly property int    weatherCode:  json.current.weather_code
    readonly property bool   isDay:        json.current.is_day
    readonly property real   windMph:      json.current.wind_speed_mph
    readonly property int    humidity:     json.current.humidity_percent

    // Array of up to 3 day objects; empty until data loads.
    readonly property var forecast: json.forecast
}
