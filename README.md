# Pulsar Shell 
### What is Pulsar Shell
Pulsar is my personal work in progress Quickshell based shell for Hyprland. The style is heavily inspired by Omarchy's Quickshell config but with the implementation simplified a bit. I am using this as a project to learn more about coding so there may be bugs, and not everything is feature complete yet, but it should generally be fully functional.

** AI Disclosure **
I used Qwen 3.5 and Claude Opus 5.5 to assist with development, for both debugging, and helping me keep things rolling when I hit the limits of my knowledge and Quickshell's terrible documentation.

### Pulsar Shell Features
 - Menu Bar optimized for dual monitor setups with per monitor workspaces with their own indicators
 - Theming engine written in Go that uses simple json files for creating themes
    - Includes Gruvbox, Catpuccin Mocha, Tokyo Night, Nord, and Solarized Dark themes out of the box
    - Theme widget includes a toggle for the bar background for contrast
    - Double clicking the theme widget opens the wallpaper selector that maps to your Pictures/Wallpapers folder.
    - Themes Quickshell, hyprland, kitty, nvim, fastfetch, starship, and Zen Browser.
 - Fully functional flyout menus for audio, bluetooth, networking, theme changing, notifications and power (power includes your system power buttons: shutdown, suspend etc)
 - Weather widget that doesn't need any API keys, it just runs a simple go program, writes your location and weather to /.local/state/pulsar-shell and reads from the created jsons. Updates every 30 minutes through quickshell.
 - Notification daemon made with quickshell with a notification center.
 - Lock Screen made with quickshell that blurs your background, shows the time and date, and has a password field.
 - Polkit Agent made with quickshell for authentication.
 - Launcher made in quickshell with prefix controlled search
   - No prefix searches installed applications
   - @<website> directly opens a website in your default browser(defaults to zen browser)
   - #<query> opens a duckduckgo search in your default browser
   - /<query> fuzzy file search in your home directory
   - $<cmd> run a command in the kitty terminal
   - Keyboard first operation, open with Super + SPACE, TAB switches between launcher tabs, arrow keys and enter navigate, also works with mouse operation.
 - Easy install script: details in Install instructions.
### Missing/Planned Features
 - Launcher:
   - Clipboard History tab
   - System Tab with useful system shortcuts.
 - Calendar Flyout: will display calendar and sync with online calendars
 - System Info flyout: will open by clicking on the cpu or memory gauge bar widgets, and display detailed system stats.
 - HyprIdle configuration
## Installation Instructions
** This shell is for Arch Based Distros, the install script will NOT work on any other distribution **
### Preparation
Whether you are installing on a fresh system or an existing config, you need to install git and base-devel
`sudo pacman -S git base-devel`
Clone the repo to Home/.PulsarShell
`git clone https://github.com/TheCosmicMoose/PulsarShell.git ~/.PulsarShell`
### Install Script
Run the install script
`cd ~/.PulsarShell && ./scripts/install.sh`
Follow the prompts in the installer, you will need to enter your password in a couple places for installing dependencies, you can check out the dependency conf files in the scripts folder to be sure you know what is being installed. 
There are 5 options for you to choose from at the start:
 1. Full Install: this option is for folks installing on bare metal or who want to use Greetd as their login manager.
 2. Minimal Install: if you want to keep your login manager choose this option.
 3. Cosmic's Experience: This is really just for me, it installs things like blockbench, libresprite, gimp, and other creative applications I use in Minecraft modding.
 4. Update: This allows you to update while keeping your theme settings, keybinds, and other tweaks in place if you have modified them after the initial install.
 5. Cancel: cancel the installation.
Once you choose an option just monitor the terminal and enter your password as necessary and verify package installs. Once the script finishes running it will prompt you to reboot. When you log back in you should be in Pulsar Shell
### Post Install
** Hyprland will display an error at login because monitors.lua isn't present, this is not a critical bug, but I am going to look into fixing this issue. **
To fix the error open Display settings (nwg-look) set your display resolutions and placement and apply, nwg-look will generate monitors.lua and the error will go away.

** Unless your main monitor happens to be HDMI-A-1 and your second monitor is DP-3 workspace indicators will appear not to be working **
To configure your main and secondary monitors, first run: `hyprctl monitors` and make note of your monitor names (e.g. eDP1, HDMI-A-1) and then run ` ./~/.local/bin/displays newMain <YourMainMonitor> newSec <YourSecondaryMonitor>` This will set the per monitor workspace correctly.

After installing, place any wallpapers you want to use in your wallpaper folder and they should automatically be read by the wallpaper switcher. To change wallpaper right click the painter's palette on the menu bar and the wallpaper switcher will appear.

## Further Customization
If you want to do things like change the workspace glyphs or add widgets feel free to fork the project and make whatever modifications you like. I don't recommend changing any quickshell configs within your cloned repo, as they will be overwritten if you run the update script, so forking is necessary for changes like that.

## Screenshots:
<img width="1920" height="1200" alt="2026-11-07-152006_hyprshot" src="https://github.com/user-attachments/assets/c50a7f2f-b09a-4eb6-b979-4bbc30003e83" />
<img width="1920" height="1200" alt="2026-11-07-152544_hyprshot" src="https://github.com/user-attachments/assets/54dd59e6-f03e-4a3e-82b4-582d48c0e342" />
<img width="1920" height="1200" alt="2026-11-07-152634_hyprshot" src="https://github.com/user-attachments/assets/a2d8880e-751f-4496-be19-50e1c7f6287c" />
<img width="1920" height="1200" alt="2026-11-07-152910_hyprshot" src="https://github.com/user-attachments/assets/46a48ed0-ef1a-4979-85d0-730558cbba90" />



