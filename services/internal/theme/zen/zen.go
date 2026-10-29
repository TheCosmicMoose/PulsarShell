// package zen renders zen's theming css files from a theme json
package zen

import (
	"bufio"
	"bytes"
	_ "embed"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"text/template"

	theme "pulsar_shell/internal/theme/thememgr"
)

// imbed template into compiled binary
//
//go:embad userChrome.css.tmpl
var tmplText string
var tmpl = template.Must(template.New("zen").Parse(tmplText))

// chromeData holds values to fill in the template
type chromeData struct {
	//MainAccentColor
	ZenPrimaryColor string
	//Base surface for Zen mixing
	ZenBrandingBg        string
	ZenBrandingBgReverse string
	//Text color
	ToolboxTextColor string
	//Secondary Surfaces
	ToolbarBgTransparent string
	SurfaceSecondary     string
	//Borders
	BorderColor string
	//Tab label Color
	TabLabelColor         string
	PersonalToolbarColor1 string
	PersonalToolbarColor2 string
	//Browser Background
	BrowserBg1       string
	BrowserBg2       string
	WorkspaceAccent1 string
	WorkspaceAccent2 string
	WorkspaceAccent3 string
	WorkspaceAccent4 string
	WorkspaceAccent5 string
}

// section is one [Name] block of profiles.ini and its key=value pairs.
type section struct {
	name string
	keys map[string]string
}

// baseDirs returns the places Zen can keep profiles.ini, in priority order.
// Zen keeps using ~/.zen if it already exists; newer installs use
// ~/.config/zen; the Flatpak build keeps its own copy under ~/.var.
func baseDirs() ([]string, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return nil, fmt.Errorf("finding home directory: %w", err)
	}
	dirs := []string{filepath.Join(home, ".zen")}
	if cfg, err := os.UserConfigDir(); err == nil {
		dirs = append(dirs, filepath.Join(cfg, "zen"))
	}
	dirs = append(dirs, filepath.Join(home, ".var", "app", "app.zen_browser.zen", ".zen"))
	return dirs, nil
}

// parseINI reads the small subset of INI that profiles.ini uses.
func parseINI(path string) ([]section, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	var sections []section
	sc := bufio.NewScanner(f)
	for sc.Scan() {
		line := strings.TrimSpace(sc.Text())
		switch {
		case line == "" || line[0] == ';' || line[0] == '#':
			continue
		case line[0] == '[' && line[len(line)-1] == ']':
			sections = append(sections, section{name: line[1 : len(line)-1], keys: map[string]string{}})
		default:
			k, v, ok := strings.Cut(line, "=")
			if !ok || len(sections) == 0 {
				continue
			}
			sections[len(sections)-1].keys[strings.TrimSpace(k)] = strings.TrimSpace(v)
		}
	}
	return sections, sc.Err()
}

// resolve turns a Path= value into a full path. Relative paths are relative
// to the directory that holds profiles.ini.
func resolve(base, p string, relative bool) string {
	if relative && !filepath.IsAbs(p) {
		return filepath.Join(base, p)
	}
	return p
}

// pickProfile chooses the profile the browser actually uses.
func pickProfile(base string, secs []section) (string, bool) {
	// 1. The profile this install is locked to.
	for _, s := range secs {
		if strings.HasPrefix(s.name, "Install") && s.keys["Default"] != "" {
			return resolve(base, s.keys["Default"], true), true
		}
	}
	// 2. Otherwise, a profile flagged Default=1.
	for _, s := range secs {
		if strings.HasPrefix(s.name, "Profile") && s.keys["Default"] == "1" && s.keys["Path"] != "" {
			return resolve(base, s.keys["Path"], s.keys["IsRelative"] != "0"), true
		}
	}
	return "", false
}

// ProfileDir returns the directory of Zen's default profile.
func ProfileDir() (string, error) {
	bases, err := baseDirs()
	if err != nil {
		return "", err
	}
	for _, base := range bases {
		secs, err := parseINI(filepath.Join(base, "profiles.ini"))
		if err != nil {
			continue // no profiles.ini here; try the next location
		}
		dir, ok := pickProfile(base, secs)
		if !ok {
			continue
		}
		if info, err := os.Stat(dir); err == nil && info.IsDir() {
			return dir, nil
		}
	}
	return "", errors.New("no Zen profile found (looked for profiles.ini in ~/.zen, ~/.config/zen and the Flatpak directory)")
}

// Path returns the desired directory for the generated files
func Path() (string, error) {
	profDir, err := ProfileDir()
	if err != nil {
		return "", fmt.Errorf("%x", err)
	}
	return filepath.Join(profDir, "chrome", "userChrome.css"), nil
}

// Render turns a validated theme into the contents of zen's userChrome.css
// Does not write until /cmd/theme runs it through atomicwrite
func Render(t *theme.Theme) ([]byte, error) {
	z := t.ZenColors

	//maps theme colors to stylesheet
	d := chromeData{
		ZenPrimaryColor:       z.ZenPrimaryColor,
		ZenBrandingBg:         z.ZenBrandingBg,
		ZenBrandingBgReverse:  z.ZenBrandingReverse,
		ToolboxTextColor:      z.ToolboxTextColor,
		ToolbarBgTransparent:  z.ToolbarBgTransparent,
		SurfaceSecondary:      z.SurfaceSecondary,
		BorderColor:           z.BorderColor,
		TabLabelColor:         z.TabLabelColor,
		PersonalToolbarColor1: z.PersonalToolbarColor1,
		PersonalToolbarColor2: z.PersonalToolbarColor2,
		BrowserBg1:            z.BrowserBg1,
		BrowserBg2:            z.BrowserBg2,
		WorkspaceAccent1:      z.WorkspaceAccent1,
		WorkspaceAccent2:      z.WorkspaceAccent2,
		WorkspaceAccent3:      z.WorkspaceAccent3,
		WorkspaceAccent4:      z.WorkspaceAccent4,
		WorkspaceAccent5:      z.WorkspaceAccent5,
	}
	var buf bytes.Buffer
	if err := tmpl.Execute(&buf, d); err != nil {
		return nil, fmt.Errorf("rendering zen theme: %w", err)
	}
	return buf.Bytes(), nil
}
