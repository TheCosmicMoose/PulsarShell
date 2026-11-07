pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Weather singleton.
//
// Flow: on startup the location program runs once. When it exits, the weather
// timer starts; it runs the weather program immediately and then every 30
// minutes. Each time the weather program exits, weather.json is re-read.
//
//   WeatherService.temperatureF
//   WeatherService.forecast        -> array of 3 day objects
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

    // Where the two Go programs are installed, for example with:
    //   go build -o ~/.local/bin/pulsar-location ./cmd/location
    //   go build -o ~/.local/bin/pulsar-weather  ./cmd/weather
    readonly property string binDir: Quickshell.env("HOME") + "/.local/bin"
    readonly property string locationBin: binDir + "/pulsar-location"
    readonly property string weatherBin: binDir + "/pulsar-weather"

    readonly property int refreshMs: 30 * 60 * 1000   // 30 minutes

    // 1. Fetch the location once at startup.
    Process {
        id: locationProc
        running: true
        command: [root.locationBin]

        stderr: StdioCollector {
            onStreamFinished: if (text.length > 0) console.warn("pulsar-location:", text.trim())
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) console.warn("pulsar-location exited with code", exitCode)
            // Start the refresh cycle either way. If the fetch failed, the weather
            // program can still use the location file from an earlier run.
            refreshWeather.restart()
        }
    }

    // 2. Fetch the weather.
    Process {
        id: weatherProc
        running: false
        command: [root.weatherBin]

        stderr: StdioCollector {
            onStreamFinished: if (text.length > 0) console.warn("pulsar-weather:", text.trim())
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) console.warn("pulsar-weather exited with code", exitCode)
            // Re-read the file now rather than relying on the file watcher, which
            // might not notice a file that didn't exist when the shell started.
            file.reload()
        }
    }

    // 3. Run the weather program at once, then every refreshMs.
    Timer {
        id: refreshWeather

        interval: root.refreshMs
        running: false
        repeat: true
        triggeredOnStart: true

        onTriggered: weatherProc.running = true
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
                property real   temperature_f:    0
                property real   feels_like_f:     0
                property string condition:        ""
                property string icon:             ""
                property int    weather_code:     0
                property bool   is_day:           true
                property real   wind_speed_mph:   0
                property int    humidity_percent: 0
            }

            // "forecast" is an array in the JSON, so it's a var. Each element:
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
