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
    property int elapsedSeconds: 0

    // derived
    property int totalCycles: protocolObj ? Number(protocolObj.cycles) : 0

    Timer {
        id: elapsedTimer
        interval: 1000
        running: view.runStatus === "RUNNING"
        repeat: true
        onTriggered: {
            view.elapsedSeconds += 1

            // Fake cycle progress for now (replace with real ESP32 data later)
            if (view.totalCycles > 0 && view.currentCycle < view.totalCycles) {
                if (view.elapsedSeconds % 5 === 0) view.currentCycle += 1
            }
        }
    }

    function fmtTime(sec) {
        const s = Math.max(0, sec | 0)
        const hh = Math.floor(s / 3600)
        const mm = Math.floor((s % 3600) / 60)
        const ss = s % 60
        function pad(n){ return (n < 10 ? "0" : "") + n }
        return (hh > 0 ? (pad(hh) + ":") : "") + pad(mm) + ":" + pad(ss)
    }

    function safeText(v) {
        return (v === undefined || v === null || v === "") ? "-" : String(v)
    }

    function updateUi() {
        // Header
        if (protocolTitleText)
            protocolTitleText.text = (protocolObj && protocolObj.name) ? String(protocolObj.name) : "No protocol"

        if (statusBadgeText)
            statusBadgeText.text = view.runStatus

        // Metric cards
        if (speedValueText)  speedValueText.text  = protocolObj ? safeText(protocolObj.speed) : "-"
        if (clampValueText)  clampValueText.text  = protocolObj ? safeText(protocolObj.clamp_force_g) : "-"
        if (strokeValueText) strokeValueText.text = protocolObj ? safeText(protocolObj.stroke_length_mm) : "-"
        if (tempValueText)   tempValueText.text   = protocolObj ? safeText(protocolObj.water_temp_c) : "-"
        if (cyclesValueText) cyclesValueText.text = protocolObj ? safeText(protocolObj.cycles) : "-"

        // Right panel
        if (cycleText) {
            cycleText.text = (view.totalCycles > 0)
                ? (view.currentCycle + " / " + view.totalCycles)
                : "- / -"
        }

        if (elapsedText)
            elapsedText.text = fmtTime(view.elapsedSeconds)

        if (progressBar) {
            progressBar.value = (view.totalCycles > 0)
                ? Math.max(0, Math.min(1, view.currentCycle / view.totalCycles))
                : 0
        }

        // Buttons
        if (pauseResumeButton) {
            pauseResumeButton.text =
                (view.runStatus === "PAUSED") ? "▶  RESUME TEST" : "⏸  PAUSE TEST"

            // this property exists in your .ui.qml button
            pauseResumeButton.backgroundColor =
                (view.runStatus === "PAUSED") ? "#16A34A" : "#F59E0B"
        }
    }

    // Keep UI synced
    Component.onCompleted: updateUi()
    onProtocolObjChanged: {
        // reset local counters when a new protocol starts
        currentCycle = 0
        elapsedSeconds = 0
        updateUi()
    }
    onRunStatusChanged: updateUi()
    onCurrentCycleChanged: updateUi()
    onElapsedSecondsChanged: updateUi()

    // Wire button clicks (these are safe at top level)
    Connections {
        target: pauseResumeButton
        function onClicked() { view.pauseResumeRequested() }
    }

    Connections {
        target: abortButton
        function onClicked() { view.abortRequested() }
    }
}
