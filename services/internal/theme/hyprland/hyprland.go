// Package hyprland renders the hyprland theme file from a theme json.
package hyprland

import (
	"bytes"
	_ "embed"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"text/template"

	theme "pulsar_shell/internal/theme/thememgr"
)

//imbed template into compiled binary

//go:embed theme.lua.tmpl
var tmplText string

// template.Must panics if the template text is malformed
var tmpl = template.Must(template.New("hyprland").Parse(tmplText))

// data holds values to fill in the template
type data struct {
	//Metrics for Hyprland windows
	GapsIn              int
	GapsOut             int
	WindowBorderWidth   int
	WindowCornerRadius  int
	AlphaActiveWindow   float64
	AlphaInactiveWindow float64
	BlurRadius          int
	BlurPasses          int
	//Window Border Colors
	WindowBorderActiveStart   string
	WindowBorderActiveEnd     string
	WindowBorderInactiveStart string
	WindowBorderInactiveEnd   string
}

func Path() (string, error) {
	dir, err := os.UserConfigDir()
	if err != nil {
		return "", fmt.Errorf("finding config directory: %w", err)
	}
	return filepath.Join(dir, "hypr", "theme.lua"), nil
}

// Render turns a validated theme into the contents of hyprland's theme.lua.
// Does not write until /cmd/theme runs it through atomicwrite
func Render(t *theme.Theme) ([]byte, error) {
	d := data{
		GapsIn:                    t.HyprlandMetrics.GapsIn,
		GapsOut:                   t.HyprlandMetrics.GapsOut,
		WindowBorderWidth:         t.HyprlandMetrics.WindowBorderWidth,
		WindowCornerRadius:        t.HyprlandMetrics.WindowCornerRadius,
		AlphaActiveWindow:         t.Transparency.AlphaActiveWindow,
		AlphaInactiveWindow:       t.Transparency.AlphaInactiveWindow,
		BlurRadius:                t.Transparency.BlurRadius,
		BlurPasses:                t.Transparency.BlurPasses,
		WindowBorderActiveStart:   t.Colors.WindowBorderActiveStart,
		WindowBorderActiveEnd:     t.Colors.WindowBorderActiveEnd,
		WindowBorderInactiveStart: t.Colors.WindowBorderInactiveStart,
		WindowBorderInactiveEnd:   t.Colors.WindowBorderInactiveEnd,
	}
	var buf bytes.Buffer
	if err := tmpl.Execute(&buf, d); err != nil {
		return nil, fmt.Errorf("rendering hyprland theme: %w", err)
	}
	return buf.Bytes(), nil
}
func Reload() {
	exec.Command("hyprctl", "reload").Run()
}
