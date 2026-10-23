import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../theme"

Column {
    id: root

    spacing:    Theme.barSpacing

    property string configProvider:     "lua"
    property bool isSpecialToggle:      false
    //Workspace Dispatcher-------------------
    function dispatchWorkspace(wsTarget, isSpecialToggle) {
        if(root.configProvider === "lua") {
            if(isSpecialToggle) {
                Hyprland.dispatch('hl.dsp.workspace.toggle_special("${wsTarget}")');
            } else {
                Hyprland.dispatch('hl.dsp.focus({workspace = "${wsTarget}"})')
            }
        }
        else {
            if (isSpecialToggle) {
                Hyprland.dispatch(`togglespecialworkspace ${wsTarget}`);
            } else {
                Hyprland.dispatch(`workspace ${wsTarget}`);
            }
        }
    }
    //Raw event handler----------------------
    property bool scrollBusy:       false
    Timer {
        id:scrollCooldown
        interval:       400
        repeat:         false
        onTriggered:    root.scrollBusy = false
    }
    //Scroll Handler-------------------------
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function(event) {
            if(root.scrollBusy) return;
            root.scrollBusy = true;
            scrollCooldown.restart();

            let occupied = Hyprland.workspaces.values.map(w=>w.id).sort((a, b) => a-b);
			if (occupied.length === 0) return;

			let currentID = Hyprland.focusedWorkspace?.id || occupied[0];
			let idx = occupied.indexOf(currentID)
			if (idx === -1) idx = 0;

			if (event.angleDelta.y <0) {
				idx = (idx + 1) % occupied.length;
			}
			else {
				idx = (idx - 1 + occupied.length) % occupied.length;
			}

			root.dispatchWorkspace(occupied[idx])
        }
    }
    Connections {
        target: Hyprland
        // Quickshell emits (name, data) for raw events
        function onRawEvent(event) {
        // 1. Handle Scratchpad Toggle
            if (event.name === "activespecial" || event.name === "activespecialv2") {
            // Event data format: "workspaceName,monitorName"
            // Example: "special:magic,eDP-1" or ",eDP-1" (closed)
                const wsName = event.data.split(',')[0];
            // If name is not empty, scratchpad is open.
                root.isScratchpad = (wsName !== "");
            }
            // 2. Reset when switching to a normal workspace
            if (event.name === "destroyworkspace") {
                root.isScratchpad = false;
            }
        }
    }
    Repeater {
        model: 6
        delegate: Text {
            id: wsIcon

            property var ws: Hyprland.workspaces.values.find(w=> w.id === index+1)
            property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
            property bool isOccupied: ws !== undefined
            property bool isUrgent: ws !== undefined && ws.urgent
            property bool hovered: false

            color: {
                if(hovered && isActive) return Theme.highlightBlue
                if(!hovered && isActive) return Theme.accentBlue
                if(hovered && isUrgent) return Theme.highlightRed
                if(!hovered && isUrgent) return Theme.accentRed
                if(hovered && isOccupied) return Theme.textPrimary
                if(!hovered && isOccupied) return Theme.textSecondary
                if(hovered) return Theme.highlightGray
                else return Theme.accentGray
            }
            font: {
                family: Theme.fontFamily
                pointSize: Theme.fontSizePrimary
            }
            text: {
                if(index + 1 == 1) return "󰚀"
                if(index + 1 == 2) return "󰙯"
                if(index + 1 == 3) return ""
                if(index + 1 == 4) return ""
                if(index + 1 == 5) return ""
                if(index + 1 == 6) return ""
                else return ""
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onContainsMouseChanged: {
                    if(containsMouse) wsDot.hovered = true
                    else wsDot.hovered = false
                }
                onClicked: root.dispatchWorkspace(index + 1)
            }
        }
    }
}
