// Package kitty renders the kitty terminal theme file from a theme json.
package kitty

import (
	"bytes"
	_ "embed"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"text/template"

	theme "pulsar_shell/internal/theme/thememgr"
)

// imbed template into compiled binary

//go:embed theme.conf.tmpl
var tmplText string

// template.Must panics if the template text is malformed
var tmpl = template.Must(template.New("kitty").Parse(tmplText))

// data holds values to fill in the template
type data struct {
	ThemeName string

	FontFamily string
	FontSize   int

	BackgroundOpacity float64

	Foreground string
	Background string

	// The 16 ANSI colors: color0-7 are the normal set, color8-15 the bright set.
	Black, BrightBlack     string
	Red, BrightRed         string
	Green, BrightGreen     string
	Yellow, BrightYellow   string
	Blue, BrightBlue       string
	Magenta, BrightMagenta string
	Cyan, BrightCyan       string
	White, BrightWhite     string

	Cursor     string
	CursorText string

	SelectionFg string
	SelectionBg string

	URL string

	ActiveBorder   string
	InactiveBorder string
	BellBorder     string

	ActiveTabFg   string
	ActiveTabBg   string
	InactiveTabFg string
	InactiveTabBg string
	TabBarBg      string
}

// Path returns the desired directory for the generated file.
func Path() (string, error) {
	dir, err := os.UserConfigDir()
	if err != nil {
		return "", fmt.Errorf("finding config directory: %w", err)
	}
	return filepath.Join(dir, "kitty", "theme.conf"), nil
}

// Render turns a validated theme into the contents of kitty's theme.conf.
// Does not write until /cmd/theme runs it through atomicwrite
func Render(t *theme.Theme) ([]byte, error) {
	c := t.Colors

	// Maps theme colors to kitty color slots
	d := data{
		ThemeName: t.Name,

		FontFamily: t.Font.FontFamily,
		FontSize:   t.Font.FontSizePrimary,

		BackgroundOpacity: t.Transparency.AlphaTerminal,

		Foreground: c.TextPrimary,
		Background: c.BgPrimary,

		Black:       c.BgPrimary,
		BrightBlack: c.HighlightGray,

		Red:           c.HighlightRed,
		BrightRed:     c.HighlightRed,
		Green:         c.HighlightGreen,
		BrightGreen:   c.HighlightGreen,
		Yellow:        c.HighlightYellow,
		BrightYellow:  c.HighlightYellow,
		Blue:          c.HighlightBlue,
		BrightBlue:    c.HighlightBlue,
		Magenta:       c.HighlightPurple,
		BrightMagenta: c.HighlightPurple,
		Cyan:          c.HighlightAqua,
		BrightCyan:    c.HighlightAqua,

		White:       c.TextSecondary,
		BrightWhite: c.TextPrimary,

		Cursor:     c.CursorBg,
		CursorText: c.BgPrimary,

		SelectionFg: c.SelectionFg,
		SelectionBg: c.SelectionBg,

		URL: c.HighlightBlue,

		ActiveBorder:   c.WindowBorderActiveStart,
		InactiveBorder: c.WindowBorderInactiveStart,
		BellBorder:     c.HighlightOrange,

		ActiveTabFg:   c.BgPrimary,
		ActiveTabBg:   c.HighlightOrange,
		InactiveTabFg: c.TextSecondary,
		InactiveTabBg: c.BgModule,
		TabBarBg:      c.BgPrimary,
	}

	// Execute writes into anything that accepts writes. A bytes.Buffer
	// collects the output in memory, and Bytes() gives the []byte that
	// atomicwrite.Write wants.
	var buf bytes.Buffer
	if err := tmpl.Execute(&buf, d); err != nil {
		return nil, fmt.Errorf("rendering kitty theme: %w", err)
	}
	return buf.Bytes(), nil
}

// Reload asks every running kitty to reload its config (SIGUSR1). Does
// not present an error if kitty is not open.
func Reload() error {
	err := exec.Command("pkill", "-USR1", "-x", "kitty").Run()

	// pkill exits with status 1 when no process matched.
	var exitErr *exec.ExitError
	if errors.As(err, &exitErr) && exitErr.ExitCode() == 1 {
		return nil
	}
	if err != nil {
		return fmt.Errorf("signalling kitty to reload: %w", err)
	}
	return nil
}
