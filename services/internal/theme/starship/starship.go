// Pakage starship renders the starship toml from a theme.
package starship

import (
	"bytes"
	_ "embed"
	"fmt"
	"os"
	"path/filepath"
	"text/template"

	theme "pulsar_shell/internal/theme/thememgr"
)

// imbed the template file into compiled binary
//
//go:embed starship.toml.tmpl
var tmplText string

// template.Must panics if template is malformed
var tmpl = template.Must(template.New("starship").Parse(tmplText))

// data holds colors to fill in the template
type data struct {
	Foreground string
	Background string
	Module     string
	Blue       string
	Aqua       string
	Green      string
	Orange     string
	Purple     string
	Red        string
	Yellow     string
}

func Path() (string, error) {
	dir, err := os.UserConfigDir()
	if err != nil {
		return "", fmt.Errorf("finding config directory: %w", err)
	}
	return filepath.Join(dir, "starship.toml"), nil
}
func Render(t *theme.Theme) ([]byte, error) {
	c := t.Colors
	//Maps theme colors to starship color slots
	d := data{
		Foreground: c.TextPrimary,
		Background: c.BgSecondary,
		Module:     c.BgModule,
		Blue:       c.AccentBlue,
		Aqua:       c.AccentAqua,
		Green:      c.AccentGreen,
		Orange:     c.AccentOrange,
		Purple:     c.AccentPurple,
		Red:        c.AccentRed,
		Yellow:     c.AccentYellow,
	}
	var buf bytes.Buffer
	if err := tmpl.Execute(&buf, d); err != nil {
		return nil, fmt.Errorf("rendering starship theme: %w", err)
	}
	return buf.Bytes(), nil
}
