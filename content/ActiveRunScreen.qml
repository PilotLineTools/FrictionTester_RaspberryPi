import QtQuick
import QtQuick.Controls
import QtQml
import PilotLine_FrictionTester

ActiveRunScreenForm {
    id: view
    anchors.fill: parent

    // passed in from NavShell
    property QtObject appMachine
    property var serialController
    property var backend

    // passed in from NavShell
    property var protocolObj: null
    property string runStatus: "RUNNING" // "RUNNING" | "PAUSED"

    signal pauseResumeRequested()
    signal abortRequested()

    // ---- local run UI state (placeholder until real streaming comes in) ----
    property int currentCycle: 0
    property int totalCycles: protocolObj ? Number(protocolObj.cycles) : 0
    property int elapsedSeconds: 0

    Timer {
        id: elapsedTimer
        interval: 1000
        running: view.runStatus === "RUNNING"
        repeat: true
        onTriggered: {
            elapsedSeconds += 1
            if (totalCycles > 0 && currentCycle < totalCycles) {
                // Fake cycle progress for now (replace with real ESP32 data later)
                if (elapsedSeconds % 5 === 0) currentCycle += 1
            }
        }
    }

    function fmtTime(sec) {
        const s = Math.max(0, sec|0)
        const hh = Math.floor(s / 3600)
        const mm = Math.floor((s % 3600) / 60)
        const ss = s % 60
        function pad(n){ return (n < 10 ? "0" : "") + n }
        return (hh > 0 ? (pad(hh) + ":") : "") + pad(mm) + ":" + pad(ss)
    }

    Component.onCompleted: {
        console.log("✅ ActiveRunScreen WRAPPER LOADED", appMachine, protocolObj, runStatus)

        // fill header title + status
        protocolTitleText.text = protocolObj && protocolObj.name ? protocolObj.name : "No protocol"
        statusBadgeText.text = view.runStatus

        // fill metric cards (use '-' when missing)
        speedValueText.text  = protocolObj ? String(protocolObj.speed) : "-"
        clampValueText.text  = protocolObj ? String(protocolObj.clamp_force_g) : "-"
        strokeValueText.text = protocolObj ? String(protocolObj.stroke_length_mm) : "-"
        tempValueText.text   = protocolObj ? String(protocolObj.water_temp_c) : "-"
        cyclesValueText.text = protocolObj ? String(protocolObj.cycles) : "-"

        // init cycles
        currentCycle = 0
        elapsedSeconds = 0
    }

    onRunStatusChanged: {
        statusBadgeText.text = view.runStatus
        // Timer auto-runs only when RUNNING
    }

    // right stack bindings
    cycleText.text = (totalCycles > 0)
        ? (currentCycle + " / " + totalCycles)
        : "- / -"

    elapsedText.text = fmtTime(elapsedSeconds)

    progressBar.value = (totalCycles > 0)
        ? Math.max(0, Math.min(1, currentCycle / totalCycles))
        : 0

    pauseResumeButton.text = (view.runStatus === "PAUSED") ? "▶  RESUME TEST" : "⏸  PAUSE TEST"
    pauseResumeButton.backgroundColor = (view.runStatus === "PAUSED") ? "#16A34A" : "#F59E0B"

    pauseResumeButton.onClicked: pauseResumeRequested()
    abortButton.onClicked: abortRequested()
}
