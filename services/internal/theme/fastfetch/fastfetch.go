// Package fastfetch renders fastfetch's config and logo from a theme.
package fastfetch

import (
	"bytes"
	_ "embed"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"text/template"

	theme "pulsar_shell/internal/theme/thememgr"
)

// Both files are copied into the compiled binary at build time.
//
//go:embed config.jsonc.tmpl
var tmplText string

//go:embed logo.txt
var logo []byte

// "json" turns a Go string into a correctly quoted and escaped JSON string,
// so a path with unusual characters can't break the generated file.
var tmpl = template.Must(
	template.New("fastfetch").
		Funcs(template.FuncMap{"json": toJSON}).
		Parse(tmplText),
)

func toJSON(s string) (string, error) {
	b, err := json.Marshal(s)
	return string(b), err
}

// data holds every value the template needs. The color fields are SGR
// strings like "38;2;251;241;208", which is the format fastfetch accepts for
// key colors, output colors and logo colors.
type data struct {
	ThemeName string
	LogoPath  string

	Text   string
	Yellow string
	Orange string
	Green  string
	Blue   string
	Purple string
	Red    string
	Aqua   string

	LogoWhite  string // the logo's $1 color
	LogoBlue   string // the logo's $2 color
	LogoCenter string // the logo's $3 color
}

// sgr converts "#rrggbb" into "38;2;r;g;b".
func sgr(hex string) (string, error) {
	if len(hex) != 7 || hex[0] != '#' {
		return "", fmt.Errorf("invalid color %q", hex)
	}
	v, err := strconv.ParseUint(hex[1:], 16, 32)
	if err != nil {
		return "", fmt.Errorf("invalid color %q: %w", hex, err)
	}
	return fmt.Sprintf("38;2;%d;%d;%d", v>>16&0xff, v>>8&0xff, v&0xff), nil
}

// converter converts colors one at a time and remembers the first error, so
// the mapping below reads as plain assignments.
type converter struct{ err error }

func (c *converter) sgr(hex string) string {
	out, err := sgr(hex)
	if err != nil && c.err == nil {
		c.err = err
	}
	return out
}

func dir() (string, error) {
	cfg, err := os.UserConfigDir()
	if err != nil {
		return "", fmt.Errorf("finding config directory: %w", err)
	}
	return filepath.Join(cfg, "fastfetch"), nil
}

// ConfigPath is where the generated config belongs.
func ConfigPath() (string, error) {
	d, err := dir()
	if err != nil {
		return "", err
	}
	return filepath.Join(d, "config.jsonc"), nil
}

// LogoPath is where the logo file belongs. The generated config points here.
func LogoPath() (string, error) {
	d, err := dir()
	if err != nil {
		return "", err
	}
	return filepath.Join(d, "logo.txt"), nil
}

// Logo returns the logo file's contents. It has no theme-specific data (the
// colors come from the config), so it's the same for every theme.
func Logo() []byte {
	return logo
}

// Render turns a validated theme into the contents of fastfetch's config.jsonc.
// It doesn't touch the disk.
func Render(t *theme.Theme) ([]byte, error) {
	logoPath, err := LogoPath()
	if err != nil {
		return nil, err
	}

	c := t.Colors
	var cv converter

	// This block is the design decision: which theme color replaces each of the
	// colors that were hard-coded in the original config. Change a mapping here
	// and nothing else needs to move.
	d := data{
		ThemeName: t.Name,
		LogoPath:  logoPath,

		Text:   cv.sgr(c.TextSecondary),   // was 223, the default output color
		Yellow: cv.sgr(c.HighlightYellow), // was 214
		Orange: cv.sgr(c.HighlightOrange), // was 208
		Green:  cv.sgr(c.HighlightGreen),  // was 142
		Blue:   cv.sgr(c.HighlightBlue),   // was 109
		Purple: cv.sgr(c.HighlightPurple), // was 175
		Red:    cv.sgr(c.HighlightRed),    // was 167 and 196
		Aqua:   cv.sgr(c.HighlightAqua),   // was 65

		LogoWhite:  cv.sgr(c.TextPrimary),
		LogoBlue:   cv.sgr(c.AccentBlue),
		LogoCenter: cv.sgr(c.HighlightBlue),
	}
	if cv.err != nil {
		return nil, fmt.Errorf("converting fastfetch colors: %w", cv.err)
	}

	var buf bytes.Buffer
	if err := tmpl.Execute(&buf, d); err != nil {
		return nil, fmt.Errorf("rendering fastfetch config: %w", err)
	}
	return buf.Bytes(), nil
}
