// Command theme applies a theme file: it validates the theme, renders the
// config for each app, writes everything, and reloads the apps.
//
// Usage:
//
//	theme [-out file] <theme.json>
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"

	"pulsar_shell/internal/atomicwrite"
	"pulsar_shell/internal/theme/fastfetch"
	"pulsar_shell/internal/theme/hyprland"
	"pulsar_shell/internal/theme/kitty"
	"pulsar_shell/internal/theme/starship"
	theme "pulsar_shell/internal/theme/thememgr"
	"pulsar_shell/internal/theme/zen"
)

// outFile is one file that will be written once every render has succeeded.
type outFile struct {
	label   string // used in error messages
	path    string
	data    []byte
	pattern string // temp file name pattern for atomicwrite
}

func fail(args ...any) {
	fmt.Fprintln(os.Stderr, append([]any{"error:"}, args...)...)
	os.Exit(1)
}

func warn(args ...any) {
	fmt.Fprintln(os.Stderr, append([]any{"warning:"}, args...)...)
}

func main() {
	// --- Arguments ---
	defaultOut, err := theme.DefaultPath()
	if err != nil {
		fail(err)
	}

	out := flag.String("out", defaultOut, "current theme file to update")
	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "usage: %s [-out file] <theme.json>\n", os.Args[0])
		flag.PrintDefaults()
	}
	flag.Parse()
	if flag.NArg() != 1 {
		flag.Usage()
		os.Exit(2)
	}
	src := flag.Arg(0)

	// --- Load and validate ---
	t, err := theme.Load(src)
	if err != nil {
		fail(err)
	}
	if err := t.Validate(); err != nil {
		fail("invalid theme:\n", err)
	}

	// --- Render everything in memory. Nothing is written yet, so a failure
	// here leaves every existing file untouched. ---
	var files []outFile
	//Prep kitty theme
	kittyPath, err := kitty.Path()
	if err != nil {
		fail(err)
	}
	kittyConf, err := kitty.Render(t)
	if err != nil {
		fail(err)
	}
	files = append(files, outFile{"kitty theme.conf", kittyPath, kittyConf, ".theme-*.tmp"})
	//Prep Starship theme
	starshipPath, err := starship.Path()
	if err != nil {
		fail(err)
	}
	starshipConf, err := starship.Render(t)
	if err != nil {
		fail(err)
	}
	files = append(files, outFile{"starship starship.toml", starshipPath, starshipConf, ".starship-*.tmp"})
	//Prep hyprland theme
	hyprlandPath, err := hyprland.Path()
	if err != nil {
		fail(err)
	}
	hyprlandConf, err := hyprland.Render(t)
	if err != nil {
		fail(err)
	}
	files = append(files, outFile{"hyprland theme.lua", hyprlandPath, hyprlandConf, ".theme-*.tmp"})
	//Prep zen theme
	zenPath, err := zen.Path()
	if err != nil {
		fail(err)
	}
	zenConf, err := zen.Render(t)
	if err != nil {
		fail(err)
	}
	files = append(files, outFile{"zen userChrome.css", zenPath, zenConf, ".userChrome-*.tmp"})
	//Prep fastfetch theme
	fastfetchPath, err := fastfetch.ConfigPath()
	if err != nil {
		fail(err)
	}
	fastfetchConf, err := fastfetch.Render(t)
	if err != nil {
		fail(err)
	}
	files = append(files, outFile{"fastfetch config.jsonc", fastfetchPath, fastfetchConf, ".config-*.tmp"})
	// Add the other apps here the same way (starship, hyprland, and so on).

	// The current theme file goes last, so anything watching it (Quickshell)
	// only reloads after the other configs are already in place.
	current, err := json.MarshalIndent(t, "", "  ")
	if err != nil {
		fail("encoding current theme:", err)
	}
	current = append(current, '\n')
	files = append(files, outFile{"current theme", *out, current, ".current-*.tmp"})

	// --- Write ---
	for _, f := range files {
		if err := atomicwrite.Write(f.path, f.data, f.pattern); err != nil {
			fail("writing "+f.label+":", err)
		}
	}

	// --- Reload. The files are already written, so a failed reload (for
	// example, the app isn't running) is only a warning. ---
	if err := kitty.Reload(); err != nil {
		warn(err)
	}

	fmt.Println("applied", t.Name)
}
