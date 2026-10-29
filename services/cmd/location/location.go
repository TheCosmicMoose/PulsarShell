package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"pulsar_shell/internal/atomicwrite"
	"strconv"
	"time"
)

const wttrURL = "https://wttr.in/?format=j1"

// Shape of the parts of the wttr.in j1 response we care about.
type wttrResponse struct {
	NearestArea []struct {
		AreaName []struct {
			Value string `json:"value"`
		} `json:"areaName"`
		Region []struct {
			Value string `json:"value"`
		} `json:"region"`
		Country []struct {
			Value string `json:"value"`
		} `json:"country"`
		Latitude  string `json:"latitude"`
		Longitude string `json:"longitude"`
	} `json:"nearest_area"`
}

// What gets written to the state file.
type Location struct {
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	Town      string  `json:"town"`
	Region    string  `json:"region"`
	Country   string  `json:"country"`
	Updated   string  `json:"updated"`
}

func first(v []struct {
	Value string `json:"value"`
}) string {
	if len(v) > 0 {
		return v[0].Value
	}
	return ""
}

func fetchLocation() (*Location, error) {
	client := &http.Client{Timeout: 15 * time.Second}

	req, err := http.NewRequest(http.MethodGet, wttrURL, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("User-Agent", "pulsar-location/1.0")

	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("unexpected status: %s", resp.Status)
	}

	var data wttrResponse
	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		return nil, fmt.Errorf("decoding response: %w", err)
	}
	if len(data.NearestArea) == 0 {
		return nil, fmt.Errorf("response contained no location data")
	}

	area := data.NearestArea[0]
	lat, err := strconv.ParseFloat(area.Latitude, 64)
	if err != nil {
		return nil, fmt.Errorf("parsing latitude %q: %w", area.Latitude, err)
	}
	lon, err := strconv.ParseFloat(area.Longitude, 64)
	if err != nil {
		return nil, fmt.Errorf("parsing longitude %q: %w", area.Longitude, err)
	}

	return &Location{
		Latitude:  lat,
		Longitude: lon,
		Town:      first(area.AreaName),
		Region:    first(area.Region),
		Country:   first(area.Country),
		Updated:   time.Now().Format(time.RFC3339),
	}, nil
}

func main() {
	home, err := os.UserHomeDir()
	if err != nil {
		fmt.Fprintln(os.Stderr, "error: cannot determine home directory:", err)
		os.Exit(1)
	}
	outPath := filepath.Join(home, ".local", "state", "pulsar_shell", "location.json")
	tempPattern := ".location-*.tmp"

	loc, err := fetchLocation()
	if err != nil {
		// Leave any existing file untouched so the widget keeps its last known location.
		fmt.Fprintln(os.Stderr, "error:", err)
		os.Exit(1)
	}

	out, err := json.MarshalIndent(loc, "", "  ")
	if err != nil {
		fmt.Fprintln(os.Stderr, "error:", err)
		os.Exit(1)
	}
	out = append(out, '\n')

	if err := atomicwrite.Write(outPath, out, tempPattern); err != nil {
		fmt.Fprintln(os.Stderr, "error writing file:", err)
		os.Exit(1)
	}

	fmt.Printf("Wrote %s (%s, %.4f, %.4f)\n", outPath, loc.Town, loc.Latitude, loc.Longitude)
}
