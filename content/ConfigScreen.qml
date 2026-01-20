import QtQuick
import QtQuick.Controls
import QtQml
import PilotLine_FrictionTester

ConfigScreenForm {
    id: view
    anchors.fill: parent

    // passed in from NavShell
    property QtObject appMachine
    property var serialController
    property var backend

    // Tell NavShell what to do
    signal chooseProtocolRequested()
    signal runTestRequested()

    // internal clamp ui state (until you have real feedback)
    property bool clampOpen: true

    function fmtOrDash(v) {
        return (v === undefined || v === null) ? "-" : ("" + v)
    }

    function currentProto() {
        return (appMachine && appMachine.selectedProtocol) ? appMachine.selectedProtocol : null
    }

    function refreshProtocolUI() {
        const p = currentProto()

        if (!p) {
            protocolTitleText.text = "No protocol selected"
            speedValueText.text  = "-"
            clampValueText.text  = "-"
            strokeValueText.text = "-"
            tempValueText.text   = "-"
            cyclesValueText.text = "-"
            return
        }

        // Title
        protocolTitleText.text = p.name ? p.name : "Unnamed Protocol"

        // Values (map your backend field names)
        // Your API/storage uses: speed, clamp_force_g, stroke_length_mm, water_temp_c, cycles
        // Your UI labels: Speed mm/s, Clamp N, Stroke mm, Temp °C, Cycles count
        //
        // NOTE: If you later decide speed is cm/s, change the unit or conversion here.
        speedValueText.text  = fmtOrDash(p.speed)
        clampValueText.text  = fmtOrDash(p.clamp_force_g)
        strokeValueText.text = fmtOrDash(p.stroke_length_mm)
        tempValueText.text   = fmtOrDash(p.water_temp_c)
        cyclesValueText.text = fmtOrDash(p.cycles)
    }

    Component.onCompleted: {
        console.log("✅ ConfigScreen wrapper loaded")
        refreshProtocolUI()

        // set initial clamp button text
        clampToggleButton.text = clampOpen ? "OPEN CLAMP" : "CLOSE CLAMP"
    }

    Connections {
        target: appMachine
        function onSelectedProtocolChanged() {
            refreshProtocolUI()
        }
    }

    // ===== Choose Protocol =====
    chooseProtocolButton.onClicked: chooseProtocolRequested()

    // ===== Clamp Toggle =====
    clampToggleButton.onClicked: {
        // flip UI state
        clampOpen = !clampOpen
        clampToggleButton.text = clampOpen ? "OPEN CLAMP" : "CLOSE CLAMP"

        // Send to ESP32 (adjust command strings to what your firmware expects)
        if (!serialController) {
            console.warn("No serialController for clamp command")
            return
        }

        if (!serialController.connected) {
            const ok = serialController.connectPort()
            if (!ok) {
                console.warn("Failed to connect serial for clamp command")
                return
            }
        }

        const cmd = clampOpen ? "CLAMP_OPEN" : "CLAMP_CLOSE"
        console.log("➡️ Send:", cmd)
        serialController.send_cmd(cmd)
    }

    // ===== Jog Buttons =====
    function sendJog(cmd) {
        if (!serialController) {
            console.warn("No serialController for jog command")
            return
        }
        if (!serialController.connected) {
            const ok = serialController.connectPort()
            if (!ok) {
                console.warn("Failed to connect serial for jog command")
                return
            }
        }
        console.log("➡️ Send:", cmd)
        serialController.send_cmd(cmd)
    }

    jogUpButton.onPressed:  sendJog("JOG_UP")
    jogDownButton.onPressed: sendJog("JOG_DOWN")

    // If you want “stop on release” behavior (recommended for jogging):
    jogUpButton.onReleased:   sendJog("JOG_STOP")
    jogDownButton.onReleased: sendJog("JOG_STOP")

    // ===== Run Test =====
    runTestButton.onClicked: {
        if (!currentProto()) {
            console.warn("Run requested but no protocol selected")
            return
        }
        runTestRequested()
    }
}
