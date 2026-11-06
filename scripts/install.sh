#!/usr/bin/env bash
#
# Pulsar Shell installer.
#
#   scripts/install.sh             interactive menu
#   scripts/install.sh --full      full install (greetd + tuigreet login screen)
#   scripts/install.sh --minimal   no login manager changes
#   scripts/install.sh --cosmic    full install + Cosmic's applications
#   scripts/install.sh --update    pull the latest version and apply it
#
# Run it as your normal user (not with sudo); it asks for your password when
# it needs root.
#
# Configs are symlinked from this repository, so keep the repository where it
# is after installing. Files that the theme and display programs generate
# (hypr/theme.lua, hypr/rules.lua, fastfetch, kitty/theme.conf, starship.toml,
# current_theme.json) are written into ~/.config by those programs instead,
# so changing your theme never modifies the repository.
#
# Everything lives in functions and `main` runs from the last line, so bash
# has read the whole file before anything runs. That matters for --update,
# which replaces this file while it is running.

set -uo pipefail

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
REPO_DIR="$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd)"
DEPS_DIR="$REPO_DIR/scripts/dependencies"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/pulsar_shell"
BIN_DIR="$HOME/.local/bin"
STAMP="$(date +%Y-%m-%d_%H-%M-%S)"
BACKUP_DIR="$STATE_DIR/backups/$STAMP"
LOG_FILE="$STATE_DIR/logs/install_$STAMP.log"
INSTALL_TYPE_FILE="$STATE_DIR/install-type"
DEFAULT_THEME="$REPO_DIR/pulsar_shell_theme/rocky_mountain_sunset.json"

# Where each repo folder is linked. Files listed in GENERATED are skipped:
# the Go programs write them.
LINK_DIRS=(quickshell hypr kitty nvim pulsar_shell_theme zed)
GENERATED=(hypr/theme.lua hypr/rules.lua pulsar_shell_theme/current_theme.json)
FISH_SYSTEM_DIR="/usr/share/pulsar-fish-config"   # config.fish sources this
GREETD_CONFIG="/etc/greetd/config.toml"

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------
# Only the 8 basic colors: the Linux console (TTY) can't show 24-bit color.
if [[ -t 1 ]]; then
    C_RESET=$'\e[0m' C_BOLD=$'\e[1m' C_RED=$'\e[31m' C_GREEN=$'\e[32m'
    C_YELLOW=$'\e[33m' C_BLUE=$'\e[34m' C_CYAN=$'\e[36m' C_WHITE=$'\e[1;37m'
else
    C_RESET='' C_BOLD='' C_RED='' C_GREEN='' C_YELLOW='' C_BLUE='' C_CYAN='' C_WHITE=''
fi

log_to_file() { [[ -n "${LOG_READY:-}" ]] && printf '%s\n' "$*" >>"$LOG_FILE"; return 0; }
say()     { printf '%s\n' "$*"; log_to_file "$*"; }
info()    { printf '%s::%s %s\n' "$C_BLUE$C_BOLD" "$C_RESET" "$*"; log_to_file ":: $*"; }
ok()      { printf '%s ok %s %s\n' "$C_GREEN$C_BOLD" "$C_RESET" "$*"; log_to_file " ok $*"; }
warn()    { printf '%s !! %s %s\n' "$C_YELLOW$C_BOLD" "$C_RESET" "$*" >&2; log_to_file " !! $*"; }
err()     { printf '%s xx %s %s\n' "$C_RED$C_BOLD" "$C_RESET" "$*" >&2; log_to_file " xx $*"; }
die()     { err "$*"; exit 1; }
heading() { printf '\n%s==> %s%s\n' "$C_CYAN$C_BOLD" "$*" "$C_RESET"; log_to_file "==> $*"; }

# ask "Question?" default(y|n) -> returns 0 for yes
ask() {
    local prompt="$1" default="${2:-n}" reply hint="[y/N]"
    [[ "$default" == y ]] && hint="[Y/n]"
    while true; do
        read -r -p "$prompt $hint " reply || return 1
        reply="${reply,,}"
        [[ -z "$reply" ]] && reply="$default"
        case "$reply" in
            y|yes) return 0 ;;
            n|no)  return 1 ;;
        esac
    done
}

# Package names from a list file: one per line, # comments and blanks ignored.
read_list() {
    local file="$1"
    [[ -f "$file" ]] || return 0
    sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^[[:space:]]*$/d' "$file"
}

# ---------------------------------------------------------------------------
# Step bookkeeping for the summary
# ---------------------------------------------------------------------------
STEP_NAMES=()
STEP_RESULTS=()
NOTES=()

record() { STEP_NAMES+=("$1"); STEP_RESULTS+=("$2"); }
note()   { NOTES+=("$*"); }

# run_step "Description" function [args...]
# On failure, asks whether to keep going.
run_step() {
    local name="$1"; shift
    heading "$name"
    if "$@"; then
        record "$name" ok
        return 0
    fi
    record "$name" failed
    err "$name failed. Details are above and in $LOG_FILE"
    if ! ask "Continue with the remaining steps anyway?" n; then
        print_summary
        exit 1
    fi
    return 1
}

skip_step() { record "$1" skipped; }

# ---------------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------------
check_arch() {
    local id="" id_like=""
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        id="$(. /etc/os-release && printf '%s' "${ID:-}")"
        # shellcheck disable=SC1091
        id_like="$(. /etc/os-release && printf '%s' "${ID_LIKE:-}")"
    fi
    if [[ "$id" == arch || " $id_like " == *" arch "* ]] && command -v pacman >/dev/null; then
        return 0
    fi
    err "Pulsar Shell only supports Arch Linux and Arch-based distributions."
    err "This system reports ID='${id:-unknown}' ID_LIKE='${id_like:-none}'."
    exit 1
}

check_user() {
    if [[ $EUID -eq 0 ]]; then
        die "Run this as your normal user, not as root or with sudo. It will ask for your password when it needs it."
    fi
    command -v sudo >/dev/null || die "sudo is required (pacman -S sudo, and add yourself to the wheel group)."
}

# Ask for the sudo password once, then keep the timestamp fresh until the
# script exits so long AUR builds don't stop at a password prompt.
start_sudo() {
    info "Some steps need root. Enter your password for sudo:"
    sudo -v || die "Couldn't get sudo access."
    (
        while kill -0 "$$" 2>/dev/null; do
            sudo -n -v 2>/dev/null
            sleep 50
        done
    ) &
    SUDO_KEEPALIVE_PID=$!
}

cleanup() {
    [[ -n "${SUDO_KEEPALIVE_PID:-}" ]] && kill "$SUDO_KEEPALIVE_PID" 2>/dev/null
    [[ -n "${YAY_BUILD_DIR:-}" && -d "$YAY_BUILD_DIR" ]] && rm -rf -- "$YAY_BUILD_DIR"
    return 0
}

# ---------------------------------------------------------------------------
# Banner and menu
# ---------------------------------------------------------------------------
print_logo() {
    local logo="$REPO_DIR/fastfetch/logo.txt" rows c1 c2
    rows="$(stty size 2>/dev/null | cut -d' ' -f1)"
    [[ "$rows" =~ ^[0-9]+$ ]] || rows=50

    # A small console (e.g. 80x25) can't fit the logo and the menu; skip the
    # logo so the menu isn't scrolled off the top.
    if (( rows < 36 )) || [[ ! -r "$logo" ]]; then
        printf '\n%s  * PULSAR SHELL *%s\n' "$C_CYAN$C_BOLD" "$C_RESET"
        return
    fi

    # $1 = cream (white here), $2 = teal (cyan here): the fastfetch logo
    # colors, reduced to the TTY's basic palette.
    c1="$C_WHITE" c2="$C_CYAN"
    local text
    text="$(cat "$logo")"
    # Without a UTF-8 locale the block characters come out as garbage, so
    # draw them with plain ASCII instead.
    if [[ "$(locale charmap 2>/dev/null)" != "UTF-8" ]]; then
        text="${text//█/#}"; text="${text//▄/.}"; text="${text//▀/\'}"
    fi
    text="${text//\$1/$c1}"
    text="${text//\$2/$c2}"
    printf '\n%s%s\n' "$text" "$C_RESET"
}

print_banner() {
    [[ -t 1 ]] && clear
    print_logo
    printf '\n  %sWelcome to Pulsar Shell!%s\n' "$C_BOLD" "$C_RESET"
    printf '  A Hyprland + Quickshell desktop. Pick how you would like to set it up.\n\n'
}

choose_mode() {
    local choice
    printf '  %s1)%s Full install         Pulsar Shell with greetd + tuigreet as the login screen\n' "$C_CYAN$C_BOLD" "$C_RESET"
    printf '  %s2)%s Minimal install      Pulsar Shell, keeping your current login manager\n' "$C_CYAN$C_BOLD" "$C_RESET"
    printf "  %s3)%s Cosmic's experience  Full install plus Cosmic's everyday applications\n" "$C_CYAN$C_BOLD" "$C_RESET"
    printf '  %s4)%s Update               Get the latest version and apply it\n' "$C_CYAN$C_BOLD" "$C_RESET"
    printf '  %sq)%s Quit\n\n' "$C_CYAN$C_BOLD" "$C_RESET"
    while true; do
        read -r -p "  Choose an option [1-4, q]: " choice || exit 1
        case "${choice,,}" in
            1) MODE=full; return ;;
            2) MODE=minimal; return ;;
            3) MODE=cosmic; return ;;
            4) MODE=update; return ;;
            q|quit) say "Nothing was changed."; exit 0 ;;
        esac
    done
}

# What each mode does. Update repeats whatever was installed last time.
set_mode_flags() {
    WITH_GREETD=false
    WITH_COSMIC=false
    case "$MODE" in
        full)    WITH_GREETD=true ;;
        cosmic)  WITH_GREETD=true; WITH_COSMIC=true ;;
        minimal) ;;
        update)
            local previous=""
            [[ -r "$INSTALL_TYPE_FILE" ]] && previous="$(<"$INSTALL_TYPE_FILE")"
            if [[ -z "$previous" ]]; then
                # No record (installed before this was saved): look for our greetd link.
                if [[ "$(readlink -f "$GREETD_CONFIG" 2>/dev/null)" == "$REPO_DIR/greetd/config.toml" ]]; then
                    previous=full
                else
                    previous=minimal
                fi
            fi
            [[ "$previous" == full || "$previous" == cosmic ]] && WITH_GREETD=true
            [[ "$previous" == cosmic ]] && WITH_COSMIC=true
            INSTALLED_MODE="$previous"
            ;;
    esac
}

confirm_plan() {
    local label
    case "$MODE" in
        full)    label="Full install" ;;
        minimal) label="Minimal install" ;;
        cosmic)  label="Cosmic's experience" ;;
        update)  label="Update (your install: ${INSTALLED_MODE:-minimal})" ;;
    esac
    printf '\n  %s%s%s will:\n' "$C_BOLD" "$label" "$C_RESET"
    [[ "$MODE" == update ]] && say "    - pull the latest version of $REPO_DIR"
    say "    - back up existing configs to $BACKUP_DIR"
    say "    - install packages with pacman (and update the system, as Arch requires)"
    say "    - install yay if needed, then the AUR packages"
    say "    - symlink the configs from this repository into $CONFIG_HOME"
    if $WITH_GREETD; then
        say "    - set up greetd + tuigreet as your login screen ($GREETD_CONFIG)"
    fi
    say "    - build the Go helper programs into $BIN_DIR and run them"
    if $WITH_COSMIC; then
        say "    - install Cosmic's applications (enables the [multilib] repository for Steam)"
    fi
    say ""
    say "  Keep the repository at $REPO_DIR afterwards: the configs link to it."
    say ""
    ask "Continue?" y || { say "Nothing was changed."; exit 0; }
}

# ---------------------------------------------------------------------------
# Update: pull, then re-run the new version of this script
# ---------------------------------------------------------------------------
pull_latest() {
    command -v git >/dev/null || { err "git is not installed."; return 1; }
    if ! git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        err "$REPO_DIR is not a git repository, so it can't be updated."
        return 1
    fi
    if ! git -C "$REPO_DIR" diff --quiet || ! git -C "$REPO_DIR" diff --cached --quiet; then
        warn "The repository has local changes:"
        git -C "$REPO_DIR" status --short
        ask "Try to update anyway? (it stops if the changes conflict)" n || return 1
    fi
    local before after
    before="$(git -C "$REPO_DIR" rev-parse HEAD)"
    info "Pulling the latest version..."
    git -C "$REPO_DIR" pull --ff-only || {
        err "git pull failed. If you have local commits or changes, sort them out and run the update again."
        return 1
    }
    after="$(git -C "$REPO_DIR" rev-parse HEAD)"
    if [[ "$before" == "$after" ]]; then
        ok "Already up to date. Re-applying the current version."
    else
        ok "Updated $(git -C "$REPO_DIR" rev-parse --short "$before") -> $(git -C "$REPO_DIR" rev-parse --short "$after"):"
        git -C "$REPO_DIR" log --oneline "$before..$after" | sed 's/^/      /'
    fi
    return 0
}

# ---------------------------------------------------------------------------
# 1. Backups
# ---------------------------------------------------------------------------
# Copy each existing config location (as it is, symlinks included) into the
# backup folder before anything is written.
backup_path() {
    local src="$1" use_sudo="${2:-}" dest
    [[ -e "$src" || -L "$src" ]] || return 0
    if [[ "$src" == "$HOME"/* ]]; then
        dest="$BACKUP_DIR/home/${src#"$HOME"/}"
    else
        dest="$BACKUP_DIR/system$src"
    fi
    mkdir -p "$(dirname "$dest")"
    if [[ -n "$use_sudo" ]]; then
        sudo cp -a -- "$src" "$dest" && sudo chown -R "$(id -u):$(id -g)" "$dest"
    else
        cp -a -- "$src" "$dest"
    fi || { err "Couldn't back up $src"; return 1; }
    say "    backed up $src"
    BACKED_UP=$((BACKED_UP + 1))
}

step_backup() {
    BACKED_UP=0
    mkdir -p "$BACKUP_DIR" || return 1
    local d
    for d in "${LINK_DIRS[@]}" fish fastfetch; do
        backup_path "$CONFIG_HOME/$d" || return 1
    done
    backup_path "$CONFIG_HOME/starship.toml" || return 1
    backup_path "$FISH_SYSTEM_DIR" sudo || return 1
    if $WITH_GREETD; then
        backup_path "/etc/greetd" sudo || return 1
    fi
    if $WITH_COSMIC; then
        backup_path "/etc/pacman.conf" sudo || return 1
    fi
    if (( BACKED_UP == 0 )); then
        ok "Nothing to back up (no existing configs)."
        rmdir "$BACKUP_DIR" 2>/dev/null
        BACKUP_DIR=""
    else
        ok "Backed up $BACKED_UP location(s) to $BACKUP_DIR"
    fi
}

# Move a single file out of the way (into the backup folder) before
# replacing it with a symlink.
set_aside() {
    local path="$1" use_sudo="${2:-}" dest
    [[ -n "$BACKUP_DIR" ]] || { BACKUP_DIR="$STATE_DIR/backups/$STAMP"; mkdir -p "$BACKUP_DIR"; }
    if [[ "$path" == "$HOME"/* ]]; then
        dest="$BACKUP_DIR/replaced/home/${path#"$HOME"/}"
    else
        dest="$BACKUP_DIR/replaced/system$path"
    fi
    mkdir -p "$(dirname "$dest")"
    if [[ -n "$use_sudo" ]]; then
        sudo mv -- "$path" "$dest" && sudo chown -R "$(id -u):$(id -g)" "$dest"
    else
        mv -- "$path" "$dest"
    fi
}

# ---------------------------------------------------------------------------
# 2-4. Packages
# ---------------------------------------------------------------------------
step_pacman() {
    local -a pkgs
    mapfile -t pkgs < <(read_list "$DEPS_DIR/pacmandeps.conf")
    (( ${#pkgs[@]} )) || { warn "No packages listed."; return 0; }
    info "Installing ${#pkgs[@]} packages with pacman (already-installed ones are skipped)."
    info "Arch doesn't support partial upgrades, so this also updates the system (-Syu)."
    sudo pacman -Syu --needed -- "${pkgs[@]}"
}

step_yay() {
    if command -v yay >/dev/null; then
        ok "yay is already installed."
        return 0
    fi
    if ! command -v git >/dev/null || ! command -v makepkg >/dev/null; then
        err "git and base-devel are needed to build yay."
        return 1
    fi
    YAY_BUILD_DIR="$(mktemp -d)"
    info "Building yay from the AUR..."
    git clone --depth 1 https://aur.archlinux.org/yay.git "$YAY_BUILD_DIR/yay" &&
        (cd "$YAY_BUILD_DIR/yay" && makepkg -si --needed --noconfirm) || return 1
    rm -rf -- "$YAY_BUILD_DIR"
    YAY_BUILD_DIR=""
    command -v yay >/dev/null && ok "yay installed."
}

# yay -S --needed with the review menus turned off; yay still asks before installing.
yay_install() {
    command -v yay >/dev/null || { err "yay isn't installed."; return 1; }
    yay -S --needed --answerclean None --answerdiff None -- "$@"
}

step_aur() {
    local -a pkgs
    mapfile -t pkgs < <(read_list "$DEPS_DIR/aurdeps.conf")
    (( ${#pkgs[@]} )) || { ok "No AUR packages listed."; return 0; }
    info "Installing ${#pkgs[@]} AUR packages: ${pkgs[*]}"
    yay_install "${pkgs[@]}"
}

# ---------------------------------------------------------------------------
# 5. Symlinks
# ---------------------------------------------------------------------------
is_generated() {
    local rel="$1" g
    for g in "${GENERATED[@]}"; do [[ "$rel" == "$g" ]] && return 0; done
    return 1
}

# link_file <repo file> <destination> [sudo]
link_file() {
    local src="$1" dest="$2" use_sudo="${3:-}" run=()
    [[ -n "$use_sudo" ]] && run=(sudo)
    # Already linked correctly.
    if [[ -L "$dest" && "$(readlink -- "$dest")" == "$src" ]]; then
        LINKS_KEPT=$((LINKS_KEPT + 1))
        return 0
    fi
    "${run[@]}" mkdir -p -- "$(dirname "$dest")" || return 1
    if [[ -e "$dest" || -L "$dest" ]]; then
        set_aside "$dest" "$use_sudo" || return 1
        LINKS_REPLACED=$((LINKS_REPLACED + 1))
    fi
    "${run[@]}" ln -s -- "$src" "$dest" || return 1
    LINKS_MADE=$((LINKS_MADE + 1))
}

# Link every file under repo/<name> into ~/.config/<name>, one by one, so
# programs can still create their own files next to them.
link_tree() {
    local name="$1" src_root="$REPO_DIR/$1" dest_root="$CONFIG_HOME/$1" file rel
    [[ -d "$src_root" ]] || { warn "Missing $src_root, skipping."; return 0; }

    # If ~/.config/<name> is itself a symlink (e.g. into another dotfiles
    # repo), set it aside so we don't write into someone else's files.
    if [[ -L "$dest_root" ]]; then
        set_aside "$dest_root" || return 1
    fi
    mkdir -p -- "$dest_root" || return 1

    while IFS= read -r -d '' file; do
        rel="${file#"$REPO_DIR"/}"
        is_generated "$rel" && continue
        link_file "$file" "$CONFIG_HOME/$rel" || { err "Couldn't link $rel"; return 1; }
    done < <(find "$src_root" -type f -print0)

    # Remove links to files that have since been deleted from the repo.
    find "$dest_root" -xtype l -lname "$REPO_DIR/*" -print -delete 2>/dev/null | sed 's/^/    removed stale link /'
    return 0
}

step_links() {
    LINKS_MADE=0 LINKS_KEPT=0 LINKS_REPLACED=0
    local name
    for name in "${LINK_DIRS[@]}"; do
        link_tree "$name" || return 1
    done

    # fish: the shared config is linked into the system path config.fish
    # sources; ~/.config/fish/config.fish is your own file for overrides, so
    # it's copied once rather than linked (your edits stay out of the repo).
    link_file "$REPO_DIR/fish/pulsar-config.fish" "$FISH_SYSTEM_DIR/pulsar-config.fish" sudo || return 1
    local user_fish="$CONFIG_HOME/fish/config.fish"
    if [[ -L "$user_fish" ]] || ! grep -qs "pulsar-config.fish" "$user_fish"; then
        [[ -e "$user_fish" || -L "$user_fish" ]] && set_aside "$user_fish"
        mkdir -p "$CONFIG_HOME/fish" && cp -- "$REPO_DIR/fish/config.fish" "$user_fish" || return 1
        say "    created $user_fish (yours to edit)"
    fi

    if $WITH_GREETD; then
        link_file "$REPO_DIR/greetd/config.toml" "$GREETD_CONFIG" sudo || return 1
    fi

    ok "$LINKS_MADE new link(s), $LINKS_KEPT already in place, $LINKS_REPLACED existing file(s) moved to the backup."
}

# Services the shell relies on. Only enabled, not started: starting
# NetworkManager now could drop the connection mid-install. They start on
# the next boot.
step_services() {
    local svc failed=0
    for svc in NetworkManager bluetooth power-profiles-daemon; do
        if systemctl is-enabled --quiet "$svc.service" 2>/dev/null; then
            ok "$svc is already enabled."
        elif sudo systemctl enable "$svc.service"; then
            ok "Enabled $svc (starts on next boot)."
        else
            err "Couldn't enable $svc."; failed=1
        fi
    done
    if systemctl is-enabled --quiet systemd-networkd.service 2>/dev/null ||
       systemctl is-enabled --quiet iwd.service 2>/dev/null; then
        note "systemd-networkd or iwd is also enabled. NetworkManager should manage your connections; disable the other one if you see network problems."
    fi

    if $WITH_GREETD; then
        # display-manager.service is a symlink to the active login manager's unit.
        local current="" dm_link=/etc/systemd/system/display-manager.service
        if [[ -L "$dm_link" ]]; then
            current="$(basename "$(readlink -f "$dm_link")" .service)"
        fi
        if [[ "$current" == greetd ]]; then
            ok "greetd is already your login manager."
        else
            if [[ -n "$current" ]]; then
                info "Replacing $current with greetd as the login manager."
                sudo systemctl disable "$current.service" || { err "Couldn't disable $current."; failed=1; }
                note "Your previous login manager ($current) was disabled. To go back: sudo systemctl disable greetd && sudo systemctl enable $current"
            fi
            if sudo systemctl enable greetd.service; then
                ok "Enabled greetd (login screen on next boot)."
            else
                err "Couldn't enable greetd."; failed=1
            fi
        fi
    fi
    return "$failed"
}

# ---------------------------------------------------------------------------
# 6-7. Go programs
# ---------------------------------------------------------------------------
step_build_go() {
    command -v go >/dev/null || { err "go is not installed."; return 1; }
    mkdir -p "$BIN_DIR" || return 1
    local dir name failed=0
    for dir in "$REPO_DIR"/services/cmd/*/; do
        name="$(basename "$dir")"
        info "Building pulsar-$name"
        if (cd "$REPO_DIR/services" && go build -trimpath -o "$BIN_DIR/pulsar-$name" "./cmd/$name"); then
            ok "$BIN_DIR/pulsar-$name"
        else
            err "Building pulsar-$name failed."; failed=1
        fi
    done
    return "$failed"
}

step_run_go() {
    local failed=0 theme_src

    # Theme: re-apply the current theme on updates, the default on installs.
    theme_src="$CONFIG_HOME/pulsar_shell_theme/current_theme.json"
    if [[ "$MODE" != update || ! -f "$theme_src" || -L "$theme_src" ]]; then
        theme_src="$DEFAULT_THEME"
    fi
    info "Applying the theme ($(basename "$theme_src"))"
    "$BIN_DIR/pulsar-theme" "$theme_src" || { err "pulsar-theme failed."; failed=1; }

    # Displays: only on first install, so an update keeps your monitor setup.
    local rules="$CONFIG_HOME/hypr/rules.lua"
    if [[ -f "$rules" && ! -L "$rules" ]]; then
        ok "Keeping your display setup ($rules)."
    else
        [[ -L "$rules" ]] && set_aside "$rules"
        info "Writing the default display setup"
        "$BIN_DIR/pulsar-display" || { err "pulsar-display failed."; failed=1; }
        note "Monitors are set to HDMI-A-1 (main) and DP-3 (secondary). For yours: pulsar-display -newMain <name> -newSec <name> (names from: hyprctl monitors)"
    fi

    # Hyprland won't start without these two files, so fall back to the
    # repo's copies if a program couldn't write them.
    local f
    for f in theme.lua rules.lua; do
        if [[ ! -f "$CONFIG_HOME/hypr/$f" ]]; then
            warn "Using the repository's default hypr/$f"
            cp -- "$REPO_DIR/hypr/$f" "$CONFIG_HOME/hypr/$f" || failed=1
        fi
    done

    # Weather: needs internet; the shell retries on its own later.
    info "Fetching location and weather"
    if "$BIN_DIR/pulsar-location" && "$BIN_DIR/pulsar-weather"; then
        ok "Weather data saved."
    else
        warn "Couldn't fetch the weather now (no internet?). The bar will try again when the shell starts."
    fi
    return "$failed"
}

# ---------------------------------------------------------------------------
# 8. Cosmic's applications
# ---------------------------------------------------------------------------
enable_multilib() {
    if grep -q '^\[multilib\]' /etc/pacman.conf; then
        return 0
    fi
    info "Enabling the [multilib] repository (needed for Steam)."
    # Uncomment "#[multilib]" and the "#Include" line right after it.
    sudo sed -i '/^#\[multilib\]/{s/^#//;n;s/^#//}' /etc/pacman.conf || return 1
    grep -q '^\[multilib\]' /etc/pacman.conf || {
        err "Couldn't find a [multilib] section to enable in /etc/pacman.conf."
        return 1
    }
}

step_cosmic() {
    local -a pac aur
    mapfile -t pac < <(read_list "$DEPS_DIR/cosmicspacman.conf")
    mapfile -t aur < <(read_list "$DEPS_DIR/cosmicsaur.conf")
    enable_multilib || return 1
    if (( ${#pac[@]} )); then
        info "Installing: ${pac[*]}"
        sudo pacman -Syu --needed -- "${pac[@]}" || return 1
    fi
    if (( ${#aur[@]} )); then
        info "Installing from the AUR: ${aur[*]}"
        yay_install "${aur[@]}" || return 1
    fi
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
print_summary() {
    local i color
    printf '\n%s==================== Summary ====================%s\n' "$C_CYAN$C_BOLD" "$C_RESET"
    for i in "${!STEP_NAMES[@]}"; do
        case "${STEP_RESULTS[$i]}" in
            ok)      color="$C_GREEN" ;;
            failed)  color="$C_RED" ;;
            *)       color="$C_YELLOW" ;;
        esac
        printf '  %s%-8s%s %s\n' "$color$C_BOLD" "${STEP_RESULTS[$i]}" "$C_RESET" "${STEP_NAMES[$i]}"
        log_to_file "  ${STEP_RESULTS[$i]} ${STEP_NAMES[$i]}"
    done
    say ""
    if [[ -n "${BACKUP_DIR:-}" && -d "$BACKUP_DIR" ]]; then
        say "  Backups:  $BACKUP_DIR"
    fi
    say "  Log:      $LOG_FILE"
    if (( ${#NOTES[@]} )); then
        say ""
        say "  Notes:"
        for i in "${NOTES[@]}"; do say "    - $i"; done
    fi
    say ""
}

finish() {
    print_summary
    local any_failed=false r
    for r in "${STEP_RESULTS[@]}"; do [[ "$r" == failed ]] && any_failed=true; done
    if $any_failed; then
        warn "Some steps failed. You can fix the problem and run the installer again; it picks up where things are."
    fi
    if [[ "$MODE" == update ]]; then
        say "  Reload Hyprland (or log out and back in) to use the update."
    fi
    if ask "Reboot now to start Pulsar Shell?" n; then
        sudo systemctl reboot
    else
        say "  Reboot when you're ready."
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
usage() {
    sed -n '3,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

main() {
    MODE=""
    local after_pull=false
    while (( $# )); do
        case "$1" in
            --full) MODE=full ;;
            --minimal) MODE=minimal ;;
            --cosmic) MODE=cosmic ;;
            --update) MODE=update ;;
            --after-pull) after_pull=true ;;     # internal: re-run after an update pull
            -h|--help) usage; exit 0 ;;
            *) usage; die "Unknown option: $1" ;;
        esac
        shift
    done

    check_arch
    check_user
    trap cleanup EXIT

    mkdir -p "$(dirname "$LOG_FILE")" && LOG_READY=1
    log_to_file "Pulsar Shell installer, $STAMP, repo $REPO_DIR"

    if [[ -z "$MODE" ]]; then
        print_banner
        choose_mode
    fi
    set_mode_flags

    if [[ "$MODE" == update && "$after_pull" == false ]]; then
        confirm_plan
        start_sudo
        run_step "Pull the latest version" pull_latest || true
        # Continue with the freshly pulled script (it may have new steps).
        exec "$REPO_DIR/scripts/install.sh" --update --after-pull
    fi
    [[ "$MODE" != update ]] && confirm_plan
    [[ -z "${SUDO_KEEPALIVE_PID:-}" ]] && start_sudo

    run_step "Back up existing configs" step_backup
    run_step "Install packages (pacman)" step_pacman
    run_step "Install yay" step_yay
    run_step "Install AUR packages" step_aur
    run_step "Link configs" step_links
    run_step "Enable system services" step_services
    run_step "Build the Go programs" step_build_go
    run_step "Run the Go programs" step_run_go
    if $WITH_COSMIC; then
        run_step "Install Cosmic's applications" step_cosmic
    else
        skip_step "Install Cosmic's applications"
    fi

    # Remember the install type for future updates.
    if [[ "$MODE" != update ]]; then
        printf '%s\n' "$MODE" >"$INSTALL_TYPE_FILE"
    fi

    finish
}

main "$@"
exit $?
