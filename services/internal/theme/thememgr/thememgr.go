// Package theme loads and validates the shell theme file.
package theme

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"regexp"
)

var (
	// Exactly #rrggbb, because that's the format every generator expects.
	hexColor = regexp.MustCompile(`^#[0-9a-fA-F]{6}$`)
	// Conservative font-name check so a stray quote or newline can't break a
	// generated TOML/Lua/CSS string.
	fontName = regexp.MustCompile(`^[A-Za-z0-9 ._-]+$`)
)

// Colors holds every color in the theme. Every field must be a #rrggbb string.
// The validator checks all fields in this struct by reflection, so only put
// colors here.
type Colors struct {
	// Background colors
	BgPrimary   string `json:"bgPrimary"`
	BgSecondary string `json:"bgSecondary"`
	BgModule    string `json:"bgModule"`
	// Text colors
	TextPrimary   string `json:"textPrimary"`
	TextSecondary string `json:"textSecondary"`
	TextContrast  string `json:"textContrast"`
	TextBg        string `json:"textBg"`
	// Accent and highlight colors
	AccentRed       string `json:"accentRed"`
	HighlightRed    string `json:"highlightRed"`
	AccentOrange    string `json:"accentOrange"`
	HighlightOrange string `json:"highlightOrange"`
	AccentYellow    string `json:"accentYellow"`
	HighlightYellow string `json:"highlightYellow"`
	AccentGreen     string `json:"accentGreen"`
	HighlightGreen  string `json:"highlightGreen"`
	AccentAqua      string `json:"accentAqua"`
	HighlightAqua   string `json:"highlightAqua"`
	AccentBlue      string `json:"accentBlue"`
	HighlightBlue   string `json:"highlightBlue"`
	AccentPurple    string `json:"accentPurple"`
	HighlightPurple string `json:"highlightPurple"`
	AccentGray      string `json:"accentGray"`
	HighlightGray   string `json:"highlightGray"`
	// Hyprland window border colors
	WindowBorderActiveStart   string `json:"windowBorderActiveStart"`
	WindowBorderActiveEnd     string `json:"windowBorderActiveEnd"`
	WindowBorderInactiveStart string `json:"windowBorderInactiveStart"`
	WindowBorderInactiveEnd   string `json:"windowBorderInactiveEnd"`
	// Cursor and selection colors for kitty, nvim, and zed
	CursorBg    string `json:"cursorBg"`
	SelectionBg string `json:"selectionBg"`
	SelectionFg string `json:"selectionFg"`
}

type Transparency struct {
	AlphaBarBg                float64 `json:"alphaBarBg"`
	AlphaAccent               float64 `json:"alphaAccent"`
	AlphaHighlight            float64 `json:"alphaHighlight"`
	AlphaActiveWindow         float64 `json:"alphaActiveWindow"`
	AlphaInactiveWindow       float64 `json:"alphaInactiveWindow"`
	AlphaActiveWindowBorder   float64 `json:"alphaActiveWindowBorder"`
	AlphaInactiveWindowBorder float64 `json:"alphaInactiveWindowBorder"`
	BlurRadius                int     `json:"blurRadius"`
	BlurPasses                int     `json:"blurPasses"`
	BorderGradientAngle       int     `json:"borderGradientAngle"`
	AlphaTerminal             float64 `json:"alphaTerminal"`
}

type Font struct {
	FontFamily      string `json:"fontFamily"`
	FontFamilyAlt   string `json:"fontFamilyAlt"`
	FontSizePrimary int    `json:"fontSizePrimary"`
	FontSizeLarge   int    `json:"fontSizeLarge"`
	FontSizeSmall   int    `json:"fontSizeSmall"`
}

type QuickshellMetrics struct {
	BarThickness        int `json:"barThickness"`
	BarSpacing          int `json:"barSpacing"`
	EdgeMargin          int `json:"edgeMargin"`
	YPadding            int `json:"yPadding"`
	XPadding            int `json:"xPadding"`
	BarButtonWidth      int `json:"barButtonWidth"`
	BarButtonHeight     int `json:"barButtonHeight"`
	BarButtonHalfHeight int `json:"barButtonHalfHeight"`
	BarRadius           int `json:"barRadius"`
	BarButtonRadius     int `json:"barButtonRadius"`
	AnimDuration        int `json:"animDuration"`
	AnimLong            int `json:"animLong"`
	AnimShort           int `json:"animShort"`
}

type HyprlandMetrics struct {
	WindowBorderWidth  int `json:"windowBorderWidth"`
	WindowCornerRadius int `json:"windowCornerRadius"`
	GapsIn             int `json:"gapsIn"`
	GapsOut            int `json:"gapsOut"`
}
type ZenColors struct {
	ZenPrimaryColor       string `json:"zenPrimaryColor"`
	ZenBrandingBg         string `json:"zenBrandingBg"`
	ZenBrandingReverse    string `json:"zenBrandingBgReverse"`
	ToolboxTextColor      string `json:"toolboxTextColor"`
	ToolbarBgTransparent  string `json:"toolbarBgTransparent"`
	SurfaceSecondary      string `json:"surfaceSecondary"`
	BorderColor           string `json:"borderColor"`
	TabLabelColor         string `json:"tabLabelColor"`
	PersonalToolbarColor1 string `json:"personalToolbarColor1"`
	PersonalToolbarColor2 string `json:"personalToolbarColor2"`
	BrowserBg1            string `json:"browserBg1"`
	BrowserBg2            string `json:"broserBg2"`
	WorkspaceAccent1      string `json:"workspaceAccent1"`
	WorkspaceAccent2      string `json:"workspaceAccent2"`
	WorkspaceAccent3      string `json:"workspaceAccent3"`
	WorkspaceAccent4      string `json:"workspaceAccent4"`
	WorkspaceAccent5      string `json:"workspaceAccent5"`
}

// Theme is the whole theme file. Helpers can take the whole thing or just one
// section, for example kitty.Render(t.Colors, t.Font).
type Theme struct {
	Name              string            `json:"name"`
	Colors            Colors            `json:"colors"`
	Transparency      Transparency      `json:"transparency"`
	Font              Font              `json:"font"`
	QuickshellMetrics QuickshellMetrics `json:"quickshellMetrics"`
	HyprlandMetrics   HyprlandMetrics   `json:"hyprlandMetrics"`
	ZenColors         ZenColors         `json:"zenColors"`
}

// DefaultPath returns the location of the current theme file, respecting
// XDG_CONFIG_HOME.
func DefaultPath() (string, error) {
	dir, err := os.UserConfigDir()
	if err != nil {
		return "", fmt.Errorf("finding config directory: %w", err)
	}
	return filepath.Join(dir, "pulsar_shell_theme", "current_theme.json"), nil
}

// Load reads and parses a theme file. Unknown keys are an error, so a typo in
// a key name is caught instead of silently ignored. Load does not check the
// values; call Validate for that.
func Load(path string) (*Theme, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("reading %s: %w", path, err)
	}

	dec := json.NewDecoder(bytes.NewReader(b))
	dec.DisallowUnknownFields()

	var t Theme
	if err := dec.Decode(&t); err != nil {
		return nil, fmt.Errorf("parsing %s: %w", path, err)
	}
	return &t, nil
}

// Validate checks every value in the theme and reports all problems at once.
//
// Note: a numeric key that's missing from the JSON decodes as 0, so range
// checks that reject 0 also catch missing keys. Fields where 0 is a legitimate
// value (gaps, radii, margins) can't tell "missing" from "zero".
func (t *Theme) Validate() error {
	var problems []error
	add := func(format string, args ...any) {
		problems = append(problems, fmt.Errorf(format, args...))
	}
	atLeast := func(key string, v, lo int) {
		if v < lo {
			add("%s: %d must be at least %d", key, v, lo)
		}
	}
	alpha := func(key string, v float64) {
		if v <= 0 || v > 1 {
			add("%s: %v must be greater than 0 and at most 1", key, v)
		}
	}

	if t.Name == "" {
		add("name: must not be empty")
	}

	// Colors: check every field in the struct by reflection, and report the
	// JSON key name so the message matches what's in the file.
	v := reflect.ValueOf(t.Colors)
	typ := v.Type()
	for i := 0; i < v.NumField(); i++ {
		key := typ.Field(i).Tag.Get("json")
		val := v.Field(i).String()
		if !hexColor.MatchString(val) {
			add("colors.%s: %q is not a #rrggbb color", key, val)
		}
	}
	zenv := reflect.ValueOf(t.ZenColors)
	zentyp := zenv.Type()
	for i := 0; i < zenv.NumField(); i++ {
		key := zentyp.Field(i).Tag.Get("json")
		val := zenv.Field(i).String()
		if !hexColor.MatchString(val) {
			add("colors.%s: %q is not an #rrggbb color", key, val)
		}
	}

	// Transparency and effects
	tr := t.Transparency
	alpha("transparency.alphaBarBg", tr.AlphaBarBg)
	alpha("transparency.alphaAccent", tr.AlphaAccent)
	alpha("transparency.alphaHighlight", tr.AlphaHighlight)
	alpha("transparency.alphaActiveWindow", tr.AlphaActiveWindow)
	alpha("transparency.alphaInactiveWindow", tr.AlphaInactiveWindow)
	alpha("transparency.alphaActiveWindowBorder", tr.AlphaActiveWindowBorder)
	alpha("transparency.alphaInactiveWindowBorder", tr.AlphaInactiveWindowBorder)
	alpha("transparency.alphaTerminal", tr.AlphaTerminal)
	atLeast("transparency.blurRadius", tr.BlurRadius, 1)
	atLeast("transparency.blurPasses", tr.BlurPasses, 1)
	if tr.BorderGradientAngle < 0 || tr.BorderGradientAngle > 360 {
		add("transparency.borderGradientAngle: %d must be between 0 and 360", tr.BorderGradientAngle)
	}

	// Fonts
	f := t.Font
	if !fontName.MatchString(f.FontFamily) {
		add("font.fontFamily: %q is empty or contains unsupported characters", f.FontFamily)
	}
	if !fontName.MatchString(f.FontFamilyAlt) {
		add("font.fontFamilyAlt: %q is empty or contains unsupported characters", f.FontFamilyAlt)
	}
	atLeast("font.fontSizePrimary", f.FontSizePrimary, 1)
	atLeast("font.fontSizeLarge", f.FontSizeLarge, 1)
	atLeast("font.fontSizeSmall", f.FontSizeSmall, 1)

	// Quickshell metrics
	q := t.QuickshellMetrics
	atLeast("quickshellMetrics.barThickness", q.BarThickness, 1)
	atLeast("quickshellMetrics.barSpacing", q.BarSpacing, 0)
	atLeast("quickshellMetrics.edgeMargin", q.EdgeMargin, 0)
	atLeast("quickshellMetrics.yPadding", q.YPadding, 0)
	atLeast("quickshellMetrics.xPadding", q.XPadding, 0)
	atLeast("quickshellMetrics.barButtonWidth", q.BarButtonWidth, 1)
	atLeast("quickshellMetrics.barButtonHeight", q.BarButtonHeight, 1)
	atLeast("quickshellMetrics.barButtonHalfHeight", q.BarButtonHalfHeight, 1)
	atLeast("quickshellMetrics.barRadius", q.BarRadius, 0)
	atLeast("quickshellMetrics.barButtonRadius", q.BarButtonRadius, 0)
	// A radius larger than half the shape's smaller side just gets clipped.
	if q.BarRadius*2 > q.BarThickness {
		add("quickshellMetrics.barRadius: %d is more than half of barThickness (%d)", q.BarRadius, q.BarThickness)
	}
	if q.BarButtonRadius*2 > min(q.BarButtonWidth, q.BarButtonHeight) {
		add("quickshellMetrics.barButtonRadius: %d is more than half of the button's smaller side (%d)",
			q.BarButtonRadius, min(q.BarButtonWidth, q.BarButtonHeight))
	}
	atLeast("quickshellMetrics.animShort", q.AnimShort, 1)
	if q.AnimShort >= q.AnimDuration || q.AnimDuration >= q.AnimLong {
		add("quickshellMetrics: animation times must satisfy animShort < animDuration < animLong (got %d, %d, %d)",
			q.AnimShort, q.AnimDuration, q.AnimLong)
	}

	// Hyprland metrics
	h := t.HyprlandMetrics
	atLeast("hyprlandMetrics.windowBorderWidth", h.WindowBorderWidth, 0)
	atLeast("hyprlandMetrics.windowCornerRadius", h.WindowCornerRadius, 0)
	atLeast("hyprlandMetrics.gapsIn", h.GapsIn, 0)
	atLeast("hyprlandMetrics.gapsOut", h.GapsOut, 0)

	return errors.Join(problems...)
}
