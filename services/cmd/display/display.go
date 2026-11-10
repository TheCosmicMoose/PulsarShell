// Command display renders hyprland's rules.lua from a template: it substitutes
// the main and secondary display names given on the command line, writes the
// result to the Hyprland config directory, and reloads Hyprland.
//
// Usage:
//
//	display [-newMain display] [-newSec display]
//
// Pass -newSec "" when there is no secondary display.
//
// Example:
//
//	display -newMain eDP-1 -newSec HDMI-A-2
package main

import (
	"bytes"
	_ "embed"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"pulsar_shell/internal/atomicwrite"
	"text/template"
)

//go:embed rules.lua.tmpl
var tmplText string

var tmpl = template.Must(template.New("rules").Parse(tmplText))

// data holds values to set in the template
type data struct {
	MainDisplay      string
	SecondaryDisplay string
}

// Path sets the output filepath.
func Path() (string, error) {
	dir, err := os.UserConfigDir()
	if err != nil {
		return "", fmt.Errorf("finding config directory: %w", err)
	}
	return filepath.Join(dir, "hypr", "rules.lua"), nil
}

// Render renderss rules.lua in memory
func Render(d data) ([]byte, error) {

	var buf bytes.Buffer
	if err := tmpl.Execute(&buf, d); err != nil {
		return nil, fmt.Errorf("rendering display settings: %w", err)
	}
	return buf.Bytes(), nil
}

func Reload() {
	exec.Command("hyprctl", "reload").Run()
}

func fail(args ...any) {
	fmt.Fprintln(os.Stderr, append([]any{"error:"}, args...)...)
	os.Exit(1)
}

func main() {
	// -----Args-----
	var defaultMain string = "HDMI-A-1"
	var defaultSecondary string = "DP-3"
	flagMain := flag.String("newMain", defaultMain, "desired main display")
	flagSec := flag.String("newSec", defaultSecondary, "desired secondary display")
	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "usage: %s [-newMain display] [-newSec display]\n", os.Args[0])
		flag.PrintDefaults()
	}
	flag.Parse()

	//end cli utilities

	d := data{
		MainDisplay:      *flagMain,
		SecondaryDisplay: *flagSec,
	}

	outPath, err := Path()
	if err != nil {
		fail(err)
	}
	rulesRender, err := Render(d)
	if err != nil {
		fail(err)
	}

	if err := atomicwrite.Write(outPath, rulesRender, ".rules-*.tmp"); err != nil {
		fail("writing rules.lua:", err)
	}

	Reload()

	fmt.Printf("wrote %s (main: %s, secondary: %s)\n", outPath, *flagMain, *flagSec)
}
