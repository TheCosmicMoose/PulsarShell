pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// The shell's notification daemon (replaces swaync/mako/dunst; only one
// program can own the notification D-Bus name, so don't run those alongside).
//
// Every notification is kept until the user interacts with it:
//   - left click  -> activate(): open it in its app, then it's gone
//   - right click -> dismiss():  gone
//   - an action button -> that action, then it's gone
// Popups that time out only hide; the notification stays in the center.
//
// Usage:
//   NotificationService.list      -> notifications not yet interacted with, newest first
//   NotificationService.count
//   NotificationService.popups    -> notifications currently showing as popups, oldest first
Singleton {
    id: root

    // How long a popup stays up (ms). The timer pauses while hovered.
    property int popupTimeout: 5000
    // Keep critical notifications (low battery etc.) up until handled.
    property bool criticalSticky: true
    // Most popups shown at once; older ones drop off the stack (they stay in the center).
    property int maxPopups: 5

    readonly property var list: server.trackedNotifications.values.slice().reverse()
    readonly property int count: server.trackedNotifications.values.length

    property var popups: []

    // Arrival time of each notification, by id.
    property var times: ({})

    NotificationServer {
        id: server

        keepOnReload: true          // keep notifications across `qs` reloads
        persistenceSupported: true  // we keep them in the center after the popup goes
        bodySupported: true
        bodyMarkupSupported: true   // the card renders the body as StyledText
        actionsSupported: true      // without this, apps don't send a "default" (click) action
        imageSupported: true

        onNotification: n => {
            n.tracked = true
            root.times[n.id] = new Date()
            n.closed.connect(() => root.hidePopup(n))

            // Notifications re-sent after a reload were already seen.
            if (!n.lastGeneration) root.showPopup(n)
        }
    }

    // Popups ---------------------------------------------------------------
    function showPopup(n) {
        if (popups.includes(n)) return
        let next = popups.concat([n])
        if (next.length > maxPopups) next = next.slice(next.length - maxPopups)
        popups = next
    }

    function hidePopup(n) {
        if (popups.includes(n)) popups = popups.filter(p => p !== n)
    }

    function clearPopups() {
        popups = []
    }

    // Interaction ------------------------------------------------------------
    // Open the notification in its app. Apps that support this send an action
    // with the identifier "default" (what libnotify calls the click action).
    // If there isn't one, launch/raise the app from its desktop entry instead.
    function activate(n) {
        hidePopup(n)

        const def = Array.from(n.actions).find(a => a.identifier === "default")
        if (def) {
            def.invoke()        // also dismisses it, unless the app marked it resident
            return
        }

        const entry = (n.desktopEntry ? DesktopEntries.byId(n.desktopEntry) : null)
                   ?? (n.appName ? DesktopEntries.heuristicLookup(n.appName) : null)
        if (entry) entry.execute()
        n.dismiss()
    }

    function invokeAction(n, action) {
        hidePopup(n)
        action.invoke()
    }

    function dismiss(n) {
        n.dismiss()             // closed -> hidePopup
    }

    function clearAll() {
        for (const n of server.trackedNotifications.values.slice()) n.dismiss()
    }

    function timeOf(n) {
        const t = times[n.id]
        return t ? Qt.formatTime(t, "hh:mm") : ""
    }
}
