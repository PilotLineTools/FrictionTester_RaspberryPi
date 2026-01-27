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

    // optional: hold last known Z position from device (mm)
    property real zPosMm: 0.0

    // --- Fixed Start gating ---
    property bool fixedStartEnabled: false
    property real fixedStartMm: 0.0
    property real startTolMm: 0.20   // tolerance band (mm)
    property bool atStartPos: true

    function computeAtStart() {
        if (!fixedStartEnabled) return true
        return Math.abs(Number(zPosMm) - Number(fixedStartMm)) <= startTolMm
    }

    function fmtOrDash(v) {
        return (v === undefined || v === null) ? "-" : ("" + v)
    }

    function currentProto() {
        return (appMachine && appMachine.selectedProtocol) ? appMachine.selectedProtocol : null
    }

    // Push wrapper state -> UI form (so .ui.qml can bind to it)
    function syncStartUiProps() {
        // only set if the UI file actually defines these props; harmless if it doesn't
        try {
            view.currentPositionMm = Number(zPosMm) || 0
        } catch(e) {}

        try {
            view.fixedStartEnabled = !!fixedStartEnabled
        } catch(e) {}

        try {
            view.fixedStartMm = Number(fixedStartMm) || 0
        } catch(e) {}

        try {
            view.atFixedStart = !!atStartPos
        } catch(e) {}
    }

    function refreshProtocolUI() {
        const p = currentProto()

        protocolSelected = !!p

        if (!p) {
            protocolTitleText.text = "No protocol selected"
            speedValueText.text      = "-"
            clampForceValueText.text = "-"
            strokeValueText.text     = "-"
            waterTempValueText.text  = "-"
            cyclesValueText.text     = "-"

            fixedStartEnabled = false
            fixedStartMm = 0.0
            atStartPos = true
            syncStartUiProps()
            return
        }

        // --- Fixed start data from protocol ---
        fixedStartEnabled = !!p.fixed_start_enabled
        fixedStartMm = Number(p.fixed_start_mm || 0)
        atStartPos = computeAtStart()

        // --- Protocol summary ---
        protocolTitleText.text = p.name ? p.name : "Unnamed Protocol"
        speedValueText.text      = fmtOrDash(p.speed)
        clampForceValueText.text = fmtOrDash(p.clamp_force_g)
        strokeValueText.text     = fmtOrDash(p.stroke_length_mm)
        waterTempValueText.text  = fmtOrDash(p.water_temp_c)
        cyclesValueText.text     = fmtOrDash(p.cycles)

        syncStartUiProps()
    }

    // Keep Z position field updated from device unless user is editing
    function setZPositionFromDevice(mm) {
        zPosMm = Number(mm) || 0

        if (!zPositionField.activeFocus) {
            zPositionField.text = Number(zPosMm).toFixed(2)
        }

        atStartPos = computeAtStart()
        syncStartUiProps()
    }

    // Similar helper for temp
    function setTempFromDevice(celsius) {
        currentTempText.text = Number(celsius).toFixed(1) + " °C"

        const p = currentProto()
        if (p && p.water_temp_c !== undefined && p.water_temp_c !== null) {
            const sp = Number(p.water_temp_c)
            const pv = Number(celsius)
            tempStatusText.text = (Math.abs(pv - sp) <= 1.0) ? "READY" : "PREHEAT"
        }
    }

    Component.onCompleted: {
        console.log("✅ ConfigScreen wrapper loaded")
        protocolSelected = !!currentProto()
        refreshProtocolUI()
        syncStartUiProps()
    }

    Connections {
        target: appMachine
        function onSelectedProtocolChanged() {
            refreshProtocolUI()
        }
    }

    Connections {
        target: serialController
        ignoreUnknownSignals: true

        function onZPositionChanged(mm) {
            setZPositionFromDevice(mm)
        }

        function onWaterTempChanged(c) {
            setTempFromDevice(c)
        }
    }

    // ===== Choose Protocol =====
    chooseProtocolButton.onClicked: chooseProtocolRequested()

    // ===== Preheat =====
    preheatButton.onClicked: {
        const p = currentProto()
        if (!p) return

        if (serialController && serialController.set_heater && p.water_temp_c !== undefined) {
            serialController.set_heater(p.water_temp_c)
            console.log("Preheat set to", p.water_temp_c, "°C")
        } else {
            console.log("Preheat pressed (wire serialController.set_heater when available)")
        }
    }

    // ===== Jog Z Axis (hold-to-jog) =====
    jogUpButton.onPressed:    { if (serialController && serialController.jog_up)    serialController.jog_up("Z") }
    jogDownButton.onPressed:  { if (serialController && serialController.jog_down)  serialController.jog_down("Z") }

    jogUpButton.onReleased:   { if (serialController && serialController.jog_stop)  serialController.jog_stop("Z") }
    jogDownButton.onReleased: { if (serialController && serialController.jog_stop)  serialController.jog_stop("Z") }

    // ===== Z Position manual set =====
    zPositionField.onAccepted: {
        const p = currentProto()
        if (!p) return

        const mm = parseFloat(zPositionField.text)
        if (isNaN(mm)) {
            console.warn("Invalid Z position:", zPositionField.text)
            return
        }

        if (serialController && serialController.move_abs) {
            serialController.move_abs("Z", mm)
        } else if (serialController && serialController.send_cmd) {
            serialController.send_cmd(`CMD MOVE_ABS axis=Z pos=${mm}`)
        } else {
            console.warn("No move_abs or send_cmd available for Z move")
        }
    }

    // ===== Run Test =====
    runTestButton.onClicked: {
        const p = currentProto()
        if (!p) {
            console.warn("Run requested but no protocol selected")
            return
        }

        // Recompute right before gating (in case zPos updated but atStartPos not yet)
        atStartPos = computeAtStart()
        syncStartUiProps()

        if (fixedStartEnabled && !atStartPos) {
            console.warn("Run blocked: move Z to fixed start:", fixedStartMm)

            // Optional: auto-move to start
            if (serialController && serialController.move_abs) {
                serialController.move_abs("Z", fixedStartMm)
            }
            return
        }

        runTestRequested(appMachine.selectedProtocol)
    }
}
