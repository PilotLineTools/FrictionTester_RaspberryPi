import QtQuick
import QtQuick.Controls
import QtQml
import PilotLine_FrictionTester

NavShellForm {
    id: shell

    width: Constants.width
    height: Constants.height

    property var serialController: null

    // "idle" | "initializing" | "config" | "running" | "paused"
    property string uiState: "idle"
    property string initStatusText: "Initializing system…"

    // Leaving-config confirmation support
    property string pendingNavTarget: ""   // "home" | "protocols" | "settings" | "calibration" | "about"

    // Sidebar enabled only when safe (idle/config)
    navEnabled: (uiState === "idle" || uiState === "config")

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

    // Home "Begin" -> show loading -> wait for INIT_COMPLETE -> config
    function beginInit() {
        if (uiState === "initializing") return

        uiState = "initializing"
        initStatusText = "Prepping for test…"

        serialController.prep_test_run()

    }

    function hideKeyboard() { Qt.inputMethod.hide() }
    function showKeyboard() { Qt.inputMethod.show() }

    QtObject {
        id: machineState
        property bool isHomed: true
        property string status: "Ready"
        property int position: 0
        property int jogSpeed: 1

        property bool motorEnabled: false

        function motorOn() {
            motorEnabled = true
            console.log("➡️ Send to ESP32: MOTOR_ON")
            shell.ensureConnectedAndSend("MOTOR_ON")
        }

        function motorOff() {
            motorEnabled = false
            console.log("➡️ Send to ESP32: MOTOR_OFF")
            shell.ensureConnectedAndSend("MOTOR_OFF")
        }
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
        LoadingScreen {
            statusMessage: shell.initStatusText
        }
    }

    Component {
        id: configComp
        ConfigScreen {
            appMachine: machineState
            serialController: shell.serialController
            backend: pythonBackend
        }
    }


    Component { id: protocolsComp; ProtocolsScreen { appMachine: machineState; serialController: shell.serialController; backend: pythonBackend } }
    Component { id: settingsComp; SettingsScreen { appMachine: machineState } }
    Component { id: historyComp; TempScreen { appMachine: machineState } }
    Component { id: aboutComp; TempScreen { appMachine: machineState } }

    // Central screen router for state-driven screens
    function routeToState() {
        if (uiState === "idle") {
            stack.replace(beginComp)
            // Keep Home button selected
            homeButton.checked = true
        } else if (uiState === "initializing") {
            stack.replace(loadingComp)
        } else if (uiState === "config") {
            stack.replace(configComp)
            // You can choose what nav button is "selected" during config; Home is fine
            homeButton.checked = true
        }
        // running/paused will be added later
    }

    Component.onCompleted: {
        console.log("NavShell loaded, serialController:", serialController,
                    "connected:", serialController ? serialController.connected : "null")
        uiState = "idle"
        routeToState()
    }

    onUiStateChanged: routeToState()

    // ===== Nav logic (enforces confirm + locks) =====

    function goTo(target) {
        // Block navigation in unsafe states even if a click slips through
        if (!(uiState === "idle" || uiState === "config")) {
            console.log("Nav blocked in state:", uiState)
            return
        }

        // Config requires confirm when leaving to OTHER screens
        if (uiState === "config" && target !== "home") {
            pendingNavTarget = target
            exitConfigDialog.open()
            return
        }

        performNav(target)
    }

    function performNav(target) {
        pendingNavTarget = ""

        if (target === "home") {
            uiState = "idle"
            stack.replace(beginComp)
        }

        if (target === "protocols") stack.replace(protocolsComp)
        else if (target === "settings") stack.replace(settingsComp)
        else if (target === "history") stack.replace(historyComp)
        else if (target === "about") stack.replace(aboutComp)
    }

    Dialog {
        id: exitConfigDialog
        modal: true
        title: "Exit configuration?"
        standardButtons: Dialog.Yes | Dialog.No

        contentItem: Text {
            text: "Leaving configuration will exit setup. Continue?"
            wrapMode: Text.WordWrap
            color: Constants.textPrimary
            padding: 16
        }

        onAccepted: performNav(pendingNavTarget)
        onRejected: pendingNavTarget = ""
    }

    // Sidebar button handlers (all go through goTo)
    homeButton.onClicked:        goTo("home")
    protocolsButton.onClicked:   goTo("protocols")
    settingsButton.onClicked:    goTo("settings")
    historyButton.onClicked: goTo("history")
    aboutButton.onClicked:       goTo("about")

    // ===== ESP32 init completion =====

    Connections {
        target: shell.serialController ? shell.serialController : null

        function onLineReceived(line) {
            const msg = ("" + line).trim()
            console.log("⬅️ ESP32:", msg)

            if (shell.uiState === "initializing") {
                if (msg === "INIT_COMPLETE") {
                    shell.initStatusText = "Init complete"
                    shell.uiState = "config"
                    return
                }
                if (msg.startsWith("INIT_ERROR")) {
                    shell.initStatusText = msg
                    shell.uiState = "idle"
                    return
                }
            }

            // TODO later: DATA streaming, faults, run complete, etc.
        }
    }

    onSerialControllerChanged: console.log("NavShell serialController CHANGED:", serialController)
}
