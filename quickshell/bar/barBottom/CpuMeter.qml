pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../theme/"
import "../../services/"

Rectangle {
	id: root

	height:		Theme.barButtonWidth
	width:		Theme.barButtonWidth
	radius:		Theme.barButtonRadius
	color:		Theme.bgModule

	property string icon:		""
	property real cpuDecimal:	Math.floor(SystemInfo.cpuPercent)/100
	property int cpuPercent:	Math.round(SystemInfo.cpuPercent)
	property bool showDetails:	mouse.containsMouse

	Item {
		id: progressMeter
		anchors.centerIn:	parent
		width:			root.width - 4
		height:			root.height -4

		property real angle:		root.cpuUsage * (360 - 2 * gapAngle)
		property real meterRadius:	width/2
		property real lineWidth:	3
		property real gapAngle:		45

		Canvas {
			id: canvas

			anchors.fill:		parent
			antialiasing:		true

			onPaint: {
				const ctx = getContext("2d");
				ctx.reset
				const centerX = width/2;
				const centerY = height/2;
				const start = Math.PI / 2 + progressMeter.gapAngle * Math.PI / 180;
				const total = (360 - 2 * progressMeter.gapAngle) * Math.PI / 180;
				const progress = progressMeter.angle * Math.PI / 180;

				ctx.lineCap =		"round";
				ctx.lineWidth =		progressMeter.lineWidth;
				ctx.strokeStyle = 	Theme.accentBlue;
				ctx.beginPath();
				ctx.arc(centerX, centerY, progressMeter.meterRadius, start, start + total, false);
				ctx.stroke();

				if (progressMeter.angle > 0) {
					ctx.strokeStyle =	Theme.highlightBlue;
					ctx.beginPath();
					ctx.arc(centerX, centerY, progressMeter.meterRadius, start, start + progress, false);
					ctx.stroke();
				}
			}
			Connections {
				target: progressMeter
				function onAngleChanged() {canvas.requestPaint();}
			}
		}
	}

	Text {
		id: icon

		anchors.centerIn:	parent
		font.family:		Theme.fontFamily
		color:			Theme.textPrimary
		font.pointSize:		Theme.fontSizeSmall
		font.bold:		root.showDetails
		horizontalAlignment: Text.AlignHCenter
		text: {
			if (root.showDetails) {
				return root.cpuPercent
			}
			else {
				return root.icon
			}
		}
	}

	MouseArea {
	    id: mouse
		anchors.fill:		parent
		cursorShape:		Qt.PointingHandCursor
		hoverEnabled:		true
		}
	}

}
