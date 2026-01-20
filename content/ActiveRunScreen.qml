import QtQuick
import QtQuick.Controls
import QtQml
import PilotLine_FrictionTester

ActiveRunScreenForm {
    id: view

    // IMPORTANT: don't anchors.fill in StackView pages
    width: parent ? parent.width : Constants.width
    height: parent ? parent.height : Constants.height

    // passed in from NavShell
    property QtObject appMachine
    property var serialController
    property var backend

    // ✅ inputs from NavShell
    property var protocolObj: null
    property bool paused: false

    // ✅ outputs to NavShell
    signal abortRequested()
    signal pauseResumeRequested()

    // elapsed
    property int elapsedSeconds: 0

    function formatTime(totalSeconds) {
        const m = Math.floor(totalSeconds / 60)
        const s = totalSeconds % 60
        const mm = (m < 10 ? "0" : "") + m
        const ss = (s < 10 ? "0" : "") + s
        return mm + ":" + ss
    }

    function applyUIFromProtocol() {
        const p = protocolObj

        protocolTitleText.text = p ? p.name : "No protocol selected"
        speedValueText.text  = p ? String(p.speed) : "-"
        clampValueText.text  = p ? String(p.clamp_force_g) : "-"
        strokeValueText.text = p ? String(p.stroke_length_mm) : "-"
        tempValueText.text   = p ? String(p.water_temp_c) : "-"
        cycleText.text       = p ? ("0 / " + String(p.cycles)) : "- / -"
    }

    function applyPauseUI() {
        statusBadgeText.text = paused ? "PAUSED" : "RUNNING"

        if (paused) {
            pauseResumeButton.text = "▶  RESUME TEST"
            pauseResumeButton.backgroundColor = "#10B981" // green
        } else {
            pauseResumeButton.text = "⏸  PAUSE TEST"
            pauseResumeButton.backgroundColor = "#F59E0B" // amber
        }
    }

    Component.onCompleted: {
        applyUIFromProtocol()
        applyPauseUI()
        elapsedText.text = formatTime(elapsedSeconds)
    }

    onProtocolObjChanged: applyUIFromProtocol()
    onPausedChanged: applyPauseUI()

    // ✅ tick timer (pauses/resumes without resetting)
    Timer {
        id: elapsedTimer
        interval: 1000
        repeat: true
        running: !view.paused
        onTriggered: {
            view.elapsedSeconds += 1
            elapsedText.text = view.formatTime(view.elapsedSeconds)
        }
    }

    pauseResumeButton.onClicked: pauseResumeRequested()
    abortButton.onClicked: abortRequested()
}
