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

    // run state
    property bool isPaused: false
    property int elapsedSeconds: 0

    function formatTime(totalSeconds) {
        const m = Math.floor(totalSeconds / 60)
        const s = totalSeconds % 60
        const mm = (m < 10 ? "0" : "") + m
        const ss = (s < 10 ? "0" : "") + s
        return mm + ":" + ss
    }

    function applyPauseUI() {
        statusBadgeText.text = isPaused ? "PAUSED" : "RUNNING"

        // Button text + color
        if (isPaused) {
            pauseResumeButton.text = "▶  RESUME TEST"
            pauseResumeButton.backgroundColor = "#10B981" // green
        } else {
            pauseResumeButton.text = "⏸  PAUSE TEST"
            pauseResumeButton.backgroundColor = "#F59E0B" // amber
        }
    }

    Component.onCompleted: {
        applyPauseUI()

        // populate protocol info from selected protocol if available
        const p = appMachine && appMachine.selectedProtocol ? appMachine.selectedProtocol : null

        protocolTitleText.text = p ? p.name : "No protocol selected"
        speedValueText.text  = p ? String(p.speed) : "-"
        clampValueText.text  = p ? String(p.clamp_force_g) : "-"
        strokeValueText.text = p ? String(p.stroke_length_mm) : "-"
        tempValueText.text   = p ? String(p.water_temp_c) : "-"

        // ✅ cycles card uses cycleText (not cyclesValueText)
        cycleText.text = p ? ("0 / " + String(p.cycles)) : "- / -"

        elapsedText.text = formatTime(elapsedSeconds)
    }

    // Tick timer (pauses/resumes without resetting)
    Timer {
        id: elapsedTimer
        interval: 1000
        repeat: true
        running: !view.isPaused
        onTriggered: {
            view.elapsedSeconds += 1
            elapsedText.text = view.formatTime(view.elapsedSeconds)
        }
    }

    pauseResumeButton.onClicked: {
        // toggle pause
        view.isPaused = !view.isPaused
        view.applyPauseUI()

        // TODO: call your backend/serial pause/resume when ready:
        // if (view.isPaused) serialController.send_cmd("PAUSE")
        // else serialController.send_cmd("RESUME")
    }

    abortButton.onClicked: {
        // TODO: abort command + route back when ready
        // serialController.send_cmd("ABORT")

        console.log("ABORT pressed")
    }
}
