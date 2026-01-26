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
    signal runTestRequested(var protocol)

    // internal clamp ui state (until you have real feedback)
    //property bool clampOpen: true

    // optional: hold last known Z position from device (mm)
    property real zPosMm: 0.0

    function fmtOrDash(v) {
        return (v === undefined || v === null) ? "-" : ("" + v)
    }

    function currentProto() {
        return (appMachine && appMachine.selectedProtocol) ? appMachine.selectedProtocol : null
    }

    function refreshProtocolUI() {
        const p = currentProto()

        // ✅ drive UI lock state
        protocolSelected = !!p

        if (!p) {
            protocolTitleText.text = "No protocol selected"

            // NOTE: match your latest .ui.qml aliases
            speedValueText.text       = "-"
            clampForceValueText.text  = "-"
            strokeValueText.text      = "-"
            waterTempValueText.text   = "-"
            cyclesValueText.text      = "-"

            return
        }

        protocolTitleText.text = p.name ? p.name : "Unnamed Protocol"

        // Your API/storage uses: speed, clamp_force_g, stroke_length_mm, water_temp_c, cycles
        speedValueText.text       = fmtOrDash(p.speed)
        clampForceValueText.text  = fmtOrDash(p.clamp_force_g)
        strokeValueText.text      = fmtOrDash(p.stroke_length_mm)
        waterTempValueText.text   = fmtOrDash(p.water_temp_c)
        cyclesValueText.text      = fmtOrDash(p.cycles)

        // Optional: show READY/PREHEAT from protocol temp setpoint
        if (p.water_temp_c !== undefined && p.water_temp_c !== null) {
            // wrapper can decide status once it knows current temp
            // leave as-is until you wire temp telemetry
        }
    }

    // Keep Z position field updated from device unless user is editing
    function setZPositionFromDevice(mm) {
        zPosMm = mm
        if (!zPositionField.activeFocus) {
            zPositionField.text = Number(mm).toFixed(2)
        }
    }

    // Similar helper for temp
    function setTempFromDevice(celsius) {
        currentTempText.text = Number(celsius).toFixed(1) + " °C"

        const p = currentProto()
        if (p && p.water_temp_c !== undefined && p.water_temp_c !== null) {
            const sp = Number(p.water_temp_c)
            const pv = Number(celsius)
            // simple band; tune later
            tempStatusText.text = (Math.abs(pv - sp) <= 1.0) ? "READY" : "PREHEAT"
        }
    }

    Component.onCompleted: {
        console.log("✅ ConfigScreen wrapper loaded")
        refreshProtocolUI()

        // initial clamp button text
        //clampToggleButton.text = clampOpen ? "OPEN CLAMP" : "CLOSE CLAMP"

        // initial lock state if no protocol
        protocolSelected = !!currentProto()

        // If your serial controller supports callbacks/signals, wire them here.
        // See "Connections" section below.
    }

    Connections {
        target: appMachine
        function onSelectedProtocolChanged() {
            refreshProtocolUI()
        }
    }

    // OPTIONAL: listen to serialController signals (update names to match your SerialController)
    // If you don't have these signals yet, ignore this block for now.
    Connections {
        target: serialController
        ignoreUnknownSignals: true

        // Example: serialController emits position updates:
        // signal zPositionChanged(real mm)
        function onZPositionChanged(mm) {
            setZPositionFromDevice(mm)
        }

        // Example: serialController emits temperature updates:
        // signal waterTempChanged(real c)
        function onWaterTempChanged(c) {
            setTempFromDevice(c)
        }
    }

    // ===== Choose Protocol =====
    chooseProtocolButton.onClicked: chooseProtocolRequested()

    // ===== Clamp Toggle =====
    /*
    clampToggleButton.onClicked: {
        clampOpen = !clampOpen
        clampToggleButton.text = clampOpen ? "OPEN CLAMP" : "CLOSE CLAMP"

        if (serialController && serialController.set_clamp) {
            serialController.set_clamp(clampOpen)
        } else {
            console.warn("serialController.set_clamp missing")
        }
    }
    */

    // ===== Preheat =====
    preheatButton.onClicked: {
        const p = currentProto()
        if (!p) return

        // If you have an explicit heater setpoint command, call it here.
        // Example (adjust to your API):
        if (serialController && serialController.set_heater && p.water_temp_c !== undefined) {
            serialController.set_heater(p.water_temp_c)
            console.log("Preheat set to", p.water_temp_c, "°C")
        } else {
            console.log("Preheat pressed (wire serialController.set_heater when available)")
        }
    }

    // ===== Jog Z Axis =====
    // Hold-to-jog behavior
    jogUpButton.onPressed:  { if (serialController && serialController.jog_up)   serialController.jog_up("Z") }
    jogDownButton.onPressed:{ if (serialController && serialController.jog_down) serialController.jog_down("Z") }

    jogUpButton.onReleased:   { if (serialController && serialController.jog_stop) serialController.jog_stop("Z") }
    jogDownButton.onReleased: { if (serialController && serialController.jog_stop) serialController.jog_stop("Z") }

    // ===== Z Position manual set =====
    // User types a number and hits enter/done
    zPositionField.onAccepted: {
        const p = currentProto()
        if (!p) return

        const mm = parseFloat(zPositionField.text)
        if (isNaN(mm)) {
            console.warn("Invalid Z position:", zPositionField.text)
            return
        }

        // Choose ONE strategy depending on your motion model:
        // A) Move absolute to the requested Z (recommended)
        if (serialController && serialController.move_abs) {
            serialController.move_abs("Z", mm)
        }
        // B) Or send a raw command line if that's how your SerialController works:
        else if (serialController && serialController.send_cmd) {
            serialController.send_cmd(`CMD MOVE_ABS axis=Z pos=${mm}`)
        } else {
            console.warn("No move_abs or send_cmd available for Z move")
        }
    }

    // ===== Run Test =====
    runTestButton.onClicked: {
        if (!currentProto()) {
            console.warn("Run requested but no protocol selected")
            return
        }
        runTestRequested(appMachine.selectedProtocol)
    }
}
