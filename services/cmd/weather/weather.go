package main

import (
	"encoding/json"
	"fmt"
	"math"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"pulsar_shell/internal/atomicwrite"
	"strconv"
	"time"
)

// ---- Input: the location.json written by the first program ----

type Location struct {
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	Town      string  `json:"town"`
}

// ---- Open-Meteo response (only the fields we request) ----

type openMeteoResponse struct {
	Current struct {
		Temperature float64 `json:"temperature_2m"`
		FeelsLike   float64 `json:"apparent_temperature"`
		Humidity    float64 `json:"relative_humidity_2m"`
		WindSpeed   float64 `json:"wind_speed_10m"`
		WeatherCode int     `json:"weather_code"`
		IsDay       int     `json:"is_day"`
	} `json:"current"`
	Daily struct {
		Time         []string  `json:"time"`
		WeatherCode  []int     `json:"weather_code"`
		TempMax      []float64 `json:"temperature_2m_max"`
		TempMin      []float64 `json:"temperature_2m_min"`
		PrecipChance []float64 `json:"precipitation_probability_max"`
	} `json:"daily"`
}

// ---- Output: weather.json ----

type Current struct {
	TemperatureF float64 `json:"temperature_f"`
	FeelsLikeF   float64 `json:"feels_like_f"`
	Condition    string  `json:"condition"`
	Icon         string  `json:"icon"`
	WeatherCode  int     `json:"weather_code"`
	IsDay        bool    `json:"is_day"`
	WindSpeedMph float64 `json:"wind_speed_mph"`
	Humidity     int     `json:"humidity_percent"`
}

type ForecastDay struct {
	Day                 string `json:"day"`
	Date                string `json:"date"`
	Condition           string `json:"condition"`
	Icon                string `json:"icon"`
	WeatherCode         int    `json:"weather_code"`
	HighF               int    `json:"high_f"`
	LowF                int    `json:"low_f"`
	PrecipChancePercent int    `json:"precip_chance_percent"`
}

type Weather struct {
	Town     string        `json:"town"`
	Current  Current       `json:"current"`
	Forecast []ForecastDay `json:"forecast"`
	Updated  string        `json:"updated"`
}

// WMO weather interpretation codes, as used by Open-Meteo.
var weatherCodes = map[int]string{
	0:  "Clear sky",
	1:  "Mainly clear",
	2:  "Partly cloudy",
	3:  "Overcast",
	45: "Fog",
	48: "Rime fog",
	51: "Light drizzle",
	53: "Drizzle",
	55: "Heavy drizzle",
	56: "Light freezing drizzle",
	57: "Freezing drizzle",
	61: "Light rain",
	63: "Rain",
	65: "Heavy rain",
	66: "Light freezing rain",
	67: "Freezing rain",
	71: "Light snow",
	73: "Snow",
	75: "Heavy snow",
	77: "Snow grains",
	80: "Light rain showers",
	81: "Rain showers",
	82: "Violent rain showers",
	85: "Light snow showers",
	86: "Heavy snow showers",
	95: "Thunderstorm",
	96: "Thunderstorm with hail",
	99: "Thunderstorm with heavy hail",
}

func describe(code int) string {
	if s, ok := weatherCodes[code]; ok {
		return s
	}
	return "Unknown"
}

// Nerd Font "Weather Icons" glyphs (nf-weather-*), keyed by the same WMO codes.
// These are the daytime / time-independent icons.
var weatherIcons = map[int]string{
	0:  "\ue30d", // nf-weather-day_sunny
	1:  "\ue30c", // nf-weather-day_sunny_overcast
	2:  "\ue302", // nf-weather-day_cloudy
	3:  "\ue312", // nf-weather-cloudy
	45: "\ue313", // nf-weather-fog
	48: "\ue313", // nf-weather-fog
	51: "\ue31b", // nf-weather-sprinkle
	53: "\ue31b", // nf-weather-sprinkle
	55: "\ue31b", // nf-weather-sprinkle
	56: "\ue3ad", // nf-weather-sleet
	57: "\ue3ad", // nf-weather-sleet
	61: "\ue318", // nf-weather-rain
	63: "\ue318", // nf-weather-rain
	65: "\ue318", // nf-weather-rain
	66: "\ue3ad", // nf-weather-sleet
	67: "\ue3ad", // nf-weather-sleet
	71: "\ue31a", // nf-weather-snow
	73: "\ue31a", // nf-weather-snow
	75: "\ue31a", // nf-weather-snow
	77: "\ue31a", // nf-weather-snow
	80: "\ue319", // nf-weather-showers
	81: "\ue319", // nf-weather-showers
	82: "\ue319", // nf-weather-showers
	85: "\ue31a", // nf-weather-snow
	86: "\ue31a", // nf-weather-snow
	95: "\ue31d", // nf-weather-thunderstorm
	96: "\ue31d", // nf-weather-thunderstorm
	99: "\ue31d", // nf-weather-thunderstorm
}

// Night-specific overrides. Codes not listed here fall back to weatherIcons.
var nightIcons = map[int]string{
	0: "\ue32b", // nf-weather-night_clear
	1: "\ue32b", // nf-weather-night_clear
	2: "\ue37e", // nf-weather-night_alt_cloudy
}

const unknownIcon = "\ue374" // nf-weather-na

func iconFor(code int, isDay bool) string {
	if !isDay {
		if s, ok := nightIcons[code]; ok {
			return s
		}
	}
	if s, ok := weatherIcons[code]; ok {
		return s
	}
	return unknownIcon
}

func round(f float64) int { return int(math.Round(f)) }

func readLocation(path string) (*Location, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var loc Location
	if err := json.Unmarshal(b, &loc); err != nil {
		return nil, fmt.Errorf("parsing %s: %w", path, err)
	}
	if loc.Latitude == 0 && loc.Longitude == 0 {
		return nil, fmt.Errorf("%s has no coordinates", path)
	}
	return &loc, nil
}

func fetchWeather(loc *Location) (*openMeteoResponse, error) {
	q := url.Values{}
	q.Set("latitude", strconv.FormatFloat(loc.Latitude, 'f', 4, 64))
	q.Set("longitude", strconv.FormatFloat(loc.Longitude, 'f', 4, 64))
	q.Set("current", "temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,is_day")
	q.Set("daily", "weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max")
	q.Set("temperature_unit", "fahrenheit")
	q.Set("wind_speed_unit", "mph")
	q.Set("timezone", "auto")
	q.Set("forecast_days", "4") // today + next 3 days

	client := &http.Client{Timeout: 15 * time.Second}
	resp, err := client.Get("https://api.open-meteo.com/v1/forecast?" + q.Encode())
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("unexpected status: %s", resp.Status)
	}

	var data openMeteoResponse
	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		return nil, fmt.Errorf("decoding response: %w", err)
	}

	d := data.Daily
	if len(d.Time) < 4 || len(d.WeatherCode) < 4 || len(d.TempMax) < 4 ||
		len(d.TempMin) < 4 || len(d.PrecipChance) < 4 {
		return nil, fmt.Errorf("incomplete daily forecast in response")
	}
	return &data, nil
}

func buildWeather(town string, data *openMeteoResponse) (*Weather, error) {
	c := data.Current
	w := &Weather{
		Town: town,
		Current: Current{
			TemperatureF: math.Round(c.Temperature*10) / 10,
			FeelsLikeF:   math.Round(c.FeelsLike*10) / 10,
			Condition:    describe(c.WeatherCode),
			Icon:         iconFor(c.WeatherCode, c.IsDay == 1),
			WeatherCode:  c.WeatherCode,
			IsDay:        c.IsDay == 1,
			WindSpeedMph: math.Round(c.WindSpeed*10) / 10,
			Humidity:     round(c.Humidity),
		},
		Updated: time.Now().Format(time.RFC3339),
	}

	d := data.Daily
	// Index 0 is today; 1..3 are the next three days.
	for i := 1; i <= 3; i++ {
		// Dates come back as local-to-location "YYYY-MM-DD", so parsing
		// them as plain dates gives the correct weekday.
		t, err := time.Parse("2006-01-02", d.Time[i])
		if err != nil {
			return nil, fmt.Errorf("parsing date %q: %w", d.Time[i], err)
		}
		w.Forecast = append(w.Forecast, ForecastDay{
			Day:                 t.Weekday().String(),
			Date:                d.Time[i],
			Condition:           describe(d.WeatherCode[i]),
			Icon:                iconFor(d.WeatherCode[i], true),
			WeatherCode:         d.WeatherCode[i],
			HighF:               round(d.TempMax[i]),
			LowF:                round(d.TempMin[i]),
			PrecipChancePercent: round(d.PrecipChance[i]),
		})
	}
	return w, nil
}

func fail(args ...any) {
	fmt.Fprintln(os.Stderr, append([]any{"error:"}, args...)...)
	os.Exit(1)
}

func main() {
	home, err := os.UserHomeDir()
	if err != nil {
		fail("cannot determine home directory:", err)
	}
	stateDir := filepath.Join(home, ".local", "state", "pulsar_shell")
	inPath := filepath.Join(stateDir, "location.json")
	outPath := filepath.Join(stateDir, "weather.json")
	tempPattern := ".weather-*.tmp"

	loc, err := readLocation(inPath)
	if err != nil {
		fail(err)
	}

	data, err := fetchWeather(loc)
	if err != nil {
		// Existing weather.json is left untouched.
		fail(err)
	}

	weather, err := buildWeather(loc.Town, data)
	if err != nil {
		fail(err)
	}

	out, err := json.MarshalIndent(weather, "", "  ")
	if err != nil {
		fail(err)
	}
	out = append(out, '\n')

	if err := atomicwrite.Write(outPath, out, tempPattern); err != nil {
		fail("writing file:", err)
	}

	fmt.Printf("Wrote %s (%s, %.1f°F, %s)\n", outPath, weather.Town,
		weather.Current.TemperatureF, weather.Current.Condition)
}
