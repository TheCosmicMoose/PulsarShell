pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU and memory usage, 0-100, refreshed every second.
//
// CPU usage is the share of non-idle time between two readings of /proc/stat.
// (A single `top -bn1` reports the average since boot, which barely moves.)
// Memory usage is 1 - MemAvailable / MemTotal, the same "used" figure as `free`.
Singleton {
    id: root

    property real cpuPercent: 0
    property real memPercent: 0

    property int interval: 1000

    // Previous /proc/stat totals, for the CPU delta.
    property real prevIdle: 0
    property real prevTotal: 0

    function parse(text) {
        const lines = text.trim().split("\n")

        // Line 1: "cpu  user nice system idle iowait irq softirq steal ..."
        const f = lines[0].trim().split(/\s+/).slice(1).map(Number)
        const idle = f[3] + f[4]
        const total = f.reduce((a, b) => a + b, 0)
        if (prevTotal > 0 && total > prevTotal) {
            cpuPercent = 100 * (1 - (idle - prevIdle) / (total - prevTotal))
        }
        prevIdle = idle
        prevTotal = total

        // Remaining lines: "MemTotal:  16303520 kB" and "MemAvailable: ..."
        let memTotal = 0, memAvail = 0
        for (const line of lines.slice(1)) {
            const [key, val] = line.split(/:\s+/)
            if (key === "MemTotal") memTotal = parseFloat(val)
            else if (key === "MemAvailable") memAvail = parseFloat(val)
        }
        if (memTotal > 0) memPercent = 100 * (1 - memAvail / memTotal)
    }

    Process {
        id: proc
        running: true
        command: ["sh", "-c", "head -1 /proc/stat; grep -E '^(MemTotal|MemAvailable):' /proc/meminfo"]

        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Timer {
        interval: root.interval
        running: true
        repeat: true
        onTriggered: proc.running = true
    }
}
