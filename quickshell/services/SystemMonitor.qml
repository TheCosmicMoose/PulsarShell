pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpuPercent
    property real memPercent

    Process {
        id: cpuMonitor
        running: true
        command: ["sh", "-c", "top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\\([0-9.]*\\)%* id.*/\\1/' | awk '{print 100 - $1\"\"}'"]

        stdout:StdioCollector {
            onStreamFinished: {
                root.cpuPercent = parseFloat(text.trim())
            }
        }
    }

    Process {
        id: memMonitor
        running: true
        command: ["sh", "-c", "free | grep Mem | awk '{printf \"%.1f%%\", ($3/$2) * 100.0}'"]

        stdout:StdioCollector {
            onStreamFinished: {
                root.memPercent = parseFloat(text.trim())
            }
        }
    }
    Timer {
        id: sysTimer

        interval:   1000
        running:    true
        repeat:     true

        onTriggered: {
            cpuMonitor.running = true
            memMonitor.running = true
        }
    }
}
