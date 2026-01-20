import QtQuick
import QtQuick.Controls
import QtQml
import PilotLine_FrictionTester

NavShellForm {
    id: shell

    width: Constants.width
    height: Constants.height

    property var serialController: null

    // "idle" | "initializing" | "config" | "running" | "paused" | "browse"
    property string uiState: "idle"
    property string initStatusText: "Initializing system…"

    // Leaving-config confirmation support
    property string pendingNavTarget: ""
    property string protocolsMode: "prepAndRun"

    // ===== Run state =====
    property var _pendingRunProtocol: null
    property var activeProtocol: null
    property bool isPaused: false

    // Sidebar enabled only when safe (idle/config/browse) and dialog not visible
    // (running/paused should lock nav)
    navEnabled: (uiState === "idle" || uiState === "config" || uiState === "browse") && !exitConfigDialog.visible

    function ensureConnectedAndSend(line) {
        if (!serialController) {
            console.error("❌ serialController is null, cannot send:", line)
            return false
        }

        if (!serialController.connected) {
            console.warn("Serial not connected; attempting connect...")
            const ok = serialController.connectPort()
            if (!ok) {
                console.error("❌ Failed to connect serial; cannot send:", line)
                return false
            }
        }

        serialController.send_cmd(line)
        return true
    }

    function ensureConnected() {
        if (!serialController) return false
        if (serialController.connected) return true
        return serialController.connectPort()
    }

    // Home "Begin" -> show loading -> wait for PREP_COMPLETE -> config (or run if queued)
    function beginInit() {
        if (uiState === "initializing") return
        uiState = "initializing"
        initStatusText = "Prepping for test"
        if (!ensureConnected()) {
            console.error("❌ Cannot prep: serial not connected")
            uiState = "idle"
            return
        }
        serialController.prep_test_run()
    }

    function startRunWithProtocol(proto) {
        if (!proto) return

        // Save for ActiveRunScreen UI
        activeProtocol = proto
        isPaused = false

        // ✅ Make sure connected
        if (!ensureConnected()) {
            console.error("❌ Cannot start test: serial not connected")
            // stay in config so user can retry
            uiState = "config"
            return
        }

        // ✅ Map protocol fields to your slot args
        // DB/API uses: speed, stroke_length_mm, clamp_force_g, water_temp_c, cycles
        const speed  = Number(proto.speed)                // cm/s (per storage.py comment)
        const stroke = Number(proto.stroke_length_mm)
        const clamp  = Number(proto.clamp_force_g)
        const temp   = Number(proto.water_temp_c)
        const cycles = Number(proto.cycles)

        console.log("➡️ START_TEST:", speed, stroke, clamp, temp, cycles)
        serialController.start_test(speed, stroke, clamp, temp, cycles)

        // Route to active run screen
        uiState = "running"
    }

    function togglePause() {
        if (uiState !== "running" && uiState !== "paused") return
        isPaused = !isPaused
        uiState = isPaused ? "paused" : "running"

        // When you add firmware commands later:
        // ensureConnectedAndSend(isPaused ? "PAUSE_TEST" : "RESUME_TEST")
    }

    function abortRun() {
        if (uiState !== "running" && uiState !== "paused") return

        // When you add firmware commands later:
        // ensureConnectedAndSend("ABORT_TEST")

        // Return to config (or idle, your choice)
        uiState = "config"
        isPaused = false
        // Keep activeProtocol if you want to display it back in config,
        // or clear it if abort should discard selection:
        // activeProtocol = null
    }

    // ===== Model/state =====
    QtObject {
        id: machineState
        property bool isHomed: true
        property string status: "Ready"
        property int position: 0
        property int jogSpeed: 1

        // Selected protocol shared across Config/Protocols
        property var selectedProtocol: null

        property bool motorEnabled: false
        function motorOn()  { motorEnabled = true;  shell.ensureConnectedAndSend("MOTOR_ON") }
        function motorOff() { motorEnabled = false; shell.ensureConnectedAndSend("MOTOR_OFF") }
    }

    QtObject {
        id: pythonBackend
        property string apiBase: "http://127.0.0.1:8080"

        function request(method, path, body, cb) {
            var xhr = new XMLHttpRequest()
            xhr.open(method, apiBase + path)
            xhr.setRequestHeader("Content-Type", "application/json")

            xhr.onload = function() {
                var ok = xhr.status >= 200 && xhr.status < 300
                var data = null
                try { data = xhr.responseText ? JSON.parse(xhr.responseText) : null } catch(e) {}
                if (cb) cb(ok, xhr.status, data)
            }

            xhr.onerror = function() {
                console.log("❌ XHR network error:", method, apiBase + path)
                if (cb) cb(false, 0, null)
            }

            xhr.send(body ? JSON.stringify(body) : null)
        }
    }

    // ===== Screens =====
    Component {
        id: beginComp
        HomeScreen {
            onBeginPressed: shell.beginInit()
        }
    }

    Component {
        id: loadingComp
        LoadingScreen { statusMessage: shell.initStatusText }
    }

    Component {
        id: configComp
        ConfigScreen {
            appMachine: machineState
            serialController: shell.serialController
            backend: pythonBackend

            onChooseProtocolRequested: {
                shell.protocolsMode = "selectOnly"
                shell.uiState = "browse"
                stack.replace(protocolsComp)
                setChecked("protocols")
                prevCheckedTarget = "protocols"
            }

            onRunTestRequested: function(protocol) {
                if (!protocol) return

                // Usually config implies prep already complete.
                // But if you ever allow running without prep, do it here:
                if (shell.uiState !== "config") {
                    console.log("Not in config; prepping first...")
                    shell._pendingRunProtocol = protocol
                    shell.beginInit()
                    return
                }

                shell.startRunWithProtocol(protocol)
            }
        }
    }

    Component {
        id: activeRunComp
        ActiveRunScreen {
            appMachine: machineState
            serialController: shell.serialController
            backend: pythonBackend

            protocolObj: shell.activeProtocol
            runStatus: shell.isPaused ? "PAUSED" : "RUNNING"

            onPauseResumeRequested: shell.togglePause()
            onAbortRequested: shell.abortRun()
        }
    }

    Component {
        id: protocolsComp
        ProtocolsScreen {
            appMachine: machineState
            serialController: shell.serialController
            backend: pythonBackend
            mode: shell.protocolsMode

            onProtocolChosen: function(proto) {
                machineState.selectedProtocol = proto

                if (mode === "selectOnly") {
                    shell.uiState = "config"
                    setChecked("home")
                    prevCheckedTarget = "home"
                    return
                }

                // prepAndRun mode: select + prep, then PREP_COMPLETE routes to config
                shell._pendingRunProtocol = null
                shell.uiState = "initializing"
                shell.initStatusText = "Prepping for test"
                if (!shell.ensureConnected()) {
                    shell.uiState = "idle"
                    return
                }
                shell.serialController.prep_test_run()
            }
        }
    }

    Component { id: settingsComp; SettingsScreen { appMachine: machineState } }
    Component { id: historyComp; TempScreen { appMachine: machineState } }
    Component { id: aboutComp; TempScreen { appMachine: machineState } }

    // ===== Routing =====
    function routeToState() {
        if (uiState === "idle") {
            stack.replace(beginComp)
            setChecked("home")
            prevCheckedTarget = "home"
        } else if (uiState === "initializing") {
            stack.replace(loadingComp)
        } else if (uiState === "config") {
            stack.replace(configComp)
            setChecked("home")
            prevCheckedTarget = "home"
        } else if (uiState === "running" || uiState === "paused") {
            stack.replace(activeRunComp)
            setChecked("home")
            prevCheckedTarget = "home"
        }
    }

    Component.onCompleted: {
        uiState = "idle"
        routeToState()
    }

    onUiStateChanged: {
        if (uiState === "idle" ||
            uiState === "initializing" ||
            uiState === "config" ||
            uiState === "running" ||
            uiState === "paused") {
            routeToState()
        }
    }

    // ===== Nav helpers =====
    property string prevCheckedTarget: "home"
    property bool suppressNavCheck: false

    function setChecked(target) {
        suppressNavCheck = true
        homeButton.checked      = (target === "home")
        protocolsButton.checked = (target === "protocols")
        settingsButton.checked  = (target === "settings")
        historyButton.checked   = (target === "history")
        aboutButton.checked     = (target === "about")
        suppressNavCheck = false
    }

    function goTo(target) {
        if (suppressNavCheck) return

        // Only allow nav in safe states
        if (!(uiState === "idle" || uiState === "config" || uiState === "browse")) {
            console.log("Nav blocked in state:", uiState)
            setChecked(prevCheckedTarget)
            return
        }

        if (uiState === "config") {
            pendingNavTarget = target
            setChecked("home")
            prevCheckedTarget = "home"
            exitConfigDialog.open()
            return
        }

        performNav(target)
    }

    function performNav(target) {
        const t = target || "home"
        pendingNavTarget = ""

        if (t === "home") {
            uiState = "idle"
            routeToState()
            return
        }

        uiState = "browse"

        if (t === "protocols") {
            protocolsMode = "prepAndRun"
            stack.replace(protocolsComp)
        } else if (t === "settings") stack.replace(settingsComp)
        else if (t === "history") stack.replace(historyComp)
        else if (t === "about") stack.replace(aboutComp)

        setChecked(t)
        prevCheckedTarget = t
    }

    function cancelExitConfirm() {
        pendingNavTarget = ""
        exitConfigDialog.close()
    }

    function clearConfigSelection() {
        machineState.selectedProtocol = null
        protocolsMode = "prepAndRun"
        // also clear active protocol preview if you want:
        // activeProtocol = null
    }

    // ===== Exit confirm dialog =====
    Dialog {
        id: exitConfigDialog
        modal: true
        dim: true
        focus: true

        x: Math.round((parent.width  - width)  / 2)
        y: Math.round((parent.height - height) / 2)
        width: 420
        implicitHeight: contentItem.implicitHeight + 40
        title: ""

        onOpened: setChecked("home")

        onClosed: {
            setChecked("home")
            prevCheckedTarget = "home"
        }

        background: Rectangle {
            radius: 16
            color: Constants.bgCard
            border.color: Constants.borderDefault
            border.width: 1
        }

        Overlay.modal: Rectangle {
            color: "transparent"
            TapHandler { onTapped: cancelExitConfirm() }
        }

        contentItem: Column {
            spacing: 20
            padding: 24

            Text {
                text: "Exit configuration?"
                font.pixelSize: 22
                font.bold: true
                color: Constants.textPrimary
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            Text {
                text: "Leaving configuration will discard your current setup."
                font.pixelSize: 15
                color: Constants.textSecondary
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            Row {
                spacing: 12
                anchors.horizontalCenter: parent.horizontalCenter

                Button {
                    text: "Cancel"
                    width: 140
                    height: 44
                    background: Rectangle {
                        radius: 10
                        color: Constants.bgSurface
                        border.color: Constants.borderDefault
                        border.width: 1
                    }
                    contentItem: Text {
                        text: "Cancel"
                        color: Constants.textPrimary
                        font.pixelSize: 15
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: cancelExitConfirm()
                }

                Button {
                    text: "Exit"
                    width: 140
                    height: 44
                    background: Rectangle { radius: 10; color: Constants.accentPrimary }
                    contentItem: Text {
                        text: "Exit"
                        color: "white"
                        font.pixelSize: 15
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        const t = pendingNavTarget
                        pendingNavTarget = ""
                        clearConfigSelection()
                        exitConfigDialog.close()
                        performNav(t)
                    }
                }
            }
        }
    }

    // Sidebar handlers
    homeButton.onClicked:      goTo("home")
    protocolsButton.onClicked: goTo("protocols")
    settingsButton.onClicked:  goTo("settings")
    historyButton.onClicked:   goTo("history")
    aboutButton.onClicked:     goTo("about")

    // ===== ESP32 messages =====
    Connections {
        target: shell.serialController ? shell.serialController : null

        function onLineReceived(line) {
            const msg = ("" + line).trim()
            console.log("PI ⬅️ ESP32:", msg)

            if (shell.uiState === "initializing") {
                if (msg === "PREP_COMPLETE") {
                    shell.initStatusText = "Prep complete"

                    // ✅ If a run was queued during prep, start it now
                    if (shell._pendingRunProtocol) {
                        const p = shell._pendingRunProtocol
                        shell._pendingRunProtocol = null
                        shell.startRunWithProtocol(p)
                        return
                    }

                    shell.uiState = "config"
                    return
                } else if (msg.startsWith("INIT_ERROR")) {
                    shell.initStatusText = msg
                    shell._pendingRunProtocol = null
                    shell.uiState = "idle"
                    return
                }
            }

            // Later: running stream updates, run complete, faults, etc.
        }
    }
}
