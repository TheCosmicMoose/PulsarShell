pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../theme"
import "../lock"

// Battery state (from UPower), power profiles (from power-profiles-daemon)
// and session actions, shared by the bar's power icon and the power flyout.
Singleton {
    id: root

    // Battery ------------------------------------------------------------------
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery.ready && battery.isLaptopBattery && battery.isPresent
    readonly property real level: battery.percentage           // 0-1
    readonly property int percent: Math.round(level * 100)
    readonly property int state: battery.state
    readonly property bool charging: state === UPowerDeviceState.Charging
                                     || state === UPowerDeviceState.PendingCharge
    readonly property bool full: state === UPowerDeviceState.FullyCharged
    // Plugged in (charging, full, or holding at a charge limit).
    readonly property bool pluggedIn: !UPower.onBattery

    readonly property string stateText: {
        switch (state) {
        case UPowerDeviceState.Charging:         return "Charging"
        case UPowerDeviceState.Discharging:      return "Discharging"
        case UPowerDeviceState.FullyCharged:     return "Fully charged"
        case UPowerDeviceState.Empty:            return "Empty"
        case UPowerDeviceState.PendingCharge:    return "Plugged in, not charging"
        case UPowerDeviceState.PendingDischarge: return "Not charging"
        }
        return pluggedIn ? "Plugged in" : "On battery"
    }

    // "Time to full: 1:05" / "Time left: 3:40", or "" when UPower has no estimate.
    readonly property string timeText: {
        if (charging && battery.timeToFull > 0) return "Time to full: " + formatDuration(battery.timeToFull)
        if (!pluggedIn && battery.timeToEmpty > 0) return "Time left: " + formatDuration(battery.timeToEmpty)
        return ""
    }

    function formatDuration(seconds) {
        const mins = Math.round(seconds / 60)
        const h = Math.floor(mins / 60)
        const m = mins % 60
        return h + ":" + (m < 10 ? "0" : "") + m
    }

    // Index 0 = empty ... 10 = full.
    readonly property var dischargingGlyphs: ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽",
                                              "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    readonly property var chargingGlyphs:    ["󰢟", "󰢜", "󰂆", "󰂇", "󰂈",
                                              "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"]
    readonly property string powerGlyph: "󰐥"

    readonly property string glyph: {
        if (!hasBattery) return powerGlyph
        const i = Math.max(0, Math.min(10, Math.round(level * 10)))
        return (charging || full) ? chargingGlyphs[i] : dischargingGlyphs[i]
    }

    // Accent for the icon and the charge bar.
    readonly property color levelColor: {
        if (charging || full) return Theme.highlightGreen
        if (percent <= 10) return Theme.highlightRed
        if (percent <= 25) return Theme.highlightOrange
        return Theme.textPrimary
    }

    // Power profiles --------------------------------------------------------------
    // Quickshell doesn't say whether power-profiles-daemon exists, so ask D-Bus
    // once. Without it the profile buttons are hidden.
    property bool profilesAvailable: false

    Process {
        running: true
        command: ["sh", "-c",
            "busctl --system --no-legend --activatable list 2>/dev/null " +
            "| grep -q -e org.freedesktop.UPower.PowerProfiles -e net.hadess.PowerProfiles"]
        onExited: code => root.profilesAvailable = code === 0
    }

    // Session actions ---------------------------------------------------------------
    function shutdown() { Quickshell.execDetached(["systemctl", "poweroff"]) }
    function reboot()   { Quickshell.execDetached(["systemctl", "reboot"]) }

    // End the login session (works whether Hyprland was started directly or
    // through a session manager).
    function logout() {
        Quickshell.execDetached(["sh", "-c",
            'if [ -n "$XDG_SESSION_ID" ]; then loginctl terminate-session "$XDG_SESSION_ID"; else hyprctl dispatch exit; fi'])
    }

    // Lock first, and only suspend once the lock is up, so the desktop is never
    // visible on wake.
    property bool suspendWhenLocked: false

    function suspend() {
        if (Lock.locked) {
            Quickshell.execDetached(["systemctl", "suspend"])
            return
        }
        suspendWhenLocked = true
        Lock.lock()
    }

    Connections {
        target: Lock
        function onLockedChanged() {
            if (Lock.locked && root.suspendWhenLocked) {
                root.suspendWhenLocked = false
                Quickshell.execDetached(["systemctl", "suspend"])
            }
        }
    }
}
