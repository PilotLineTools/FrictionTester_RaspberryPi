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
    navEnabled: (uiState === "idle" || uiState === "config") && !exitConfigDialog.visible

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
        initStatusText = "Prepping for test"
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
    // This is mainly for routing to screens based on uiState (not nav buttons)
    function routeToState() {
        if (uiState === "idle") {
            stack.replace(beginComp)
            // Keep Home button selected
            homeButton.checked = true
        } else if (uiState === "initializing") {
            stack.replace(loadingComp)
        } else if (uiState === "config") {
            stack.replace(configComp)
            setChecked("home")
            prevCheckedTarget = "home"

        }
        // running/paused will be added later
    }

    Component.onCompleted: {
        console.log("NavShell loaded, serialController:", serialController,
                    "connected:", serialController ? serialController.connected : "null")
        uiState = "idle"
        routeToState()
    }

    onUiStateChanged: {
        // Only auto-route for core machine states
        if (uiState === "idle" ||
            uiState === "initializing" ||
            uiState === "config") {
            routeToState()
        }
    }


    // ===== Nav logic (enforces confirm + locks) =====

    property string prevCheckedTarget: "home"
    property bool suppressNavCheck: false

    function setChecked(target) {
        // Prevent recursion/flicker if needed
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

        // Block navigation in unsafe states
        if (!(uiState === "idle" || uiState === "config")) {
            console.log("Nav blocked in state:", uiState)
            return
        }

        // If we are in config, require confirmation before leaving config
        if (uiState === "config") {
            // If they tapped Home, you can decide:
            // - Either confirm (exit config) OR
            // - Just treat as "exit to home" with confirm
            // We'll keep your confirm behavior.

            pendingNavTarget = target

            // Remember what was selected BEFORE they tapped
            prevCheckedTarget = "home"   // because in config you keep Home checked
            // If you ever choose to highlight something else in config, store that instead.

            exitConfigDialog.open()
            return
        }

        // Idle state: navigate immediately
        performNav(target)
    }


    function performNav(target) {
        pendingNavTarget = ""
        uiState = "idle"

        if (target === "home") stack.replace(beginComp)
        else if (target === "protocols") stack.replace(protocolsComp)
        else if (target === "settings") stack.replace(settingsComp)
        else if (target === "history") stack.replace(historyComp)
        else if (target === "about") stack.replace(aboutComp)
    }

    function performNav(target) {
        const t = target || "home"
        pendingNavTarget = ""

        if (t === "home") {
            uiState = "idle"
            routeToState()
            setChecked("home")
            return
        }

        uiState = "browse"
        
        if (t === "protocols") stack.replace(protocolsComp)
        else if (t === "settings") stack.replace(settingsComp)
        else if (t === "history") stack.replace(historyComp)
        else if (t === "about") stack.replace(aboutComp)

        setChecked(t)
    }


    Dialog {
        id: exitConfigDialog

        modal: true
        dim: true
        focus: true

        // ✅ Explicit centering
        x: Math.round((parent.width  - width)  / 2)
        y: Math.round((parent.height - height) / 2)

        // Prevent default platform sizing weirdness
        width: 420
        implicitHeight: contentItem.implicitHeight + 40

        // Remove native title bar look
        title: ""

        background: Rectangle {
            radius: 16
            color: Constants.bgCard
            border.color: Constants.borderDefault
            border.width: 1
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

                    onClicked: {
                        pendingNavTarget = ""
                        exitConfigDialog.close()
                        setChecked("home")
                    }

                }

                Button {
                    text: "Exit"
                    width: 140
                    height: 44

                    background: Rectangle {
                        radius: 10
                        color: Constants.accentPrimary
                    }

                    contentItem: Text {
                        text: "Exit"
                        color: "white"
                        font.pixelSize: 15
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        exitConfigDialog.close()

                        // ✅ Navigate to what they chose
                        performNav(pendingNavTarget)

                        // ✅ Update selection visually
                        setChecked(pendingNavTarget === "" ? "home" : pendingNavTarget)
                    }

                }
            }
        }
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
            console.log("PI ⬅️ ESP32:", msg)

            if (shell.uiState === "initializing") {
                if (msg === "PREP_COMPLETE") {
                    shell.initStatusText = "Prep complete"
                    shell.uiState = "config"
                    return
                }
                else if (msg.startsWith("INIT_ERROR")) {
                    shell.initStatusText = msg
                    shell.uiState = "idle"
                    return
                }
                else {
                    console.warn("Unexpected message during initialization:", msg)
                }   
            }

            // TODO later: DATA streaming, faults, run complete, etc.
        }
    }

    onSerialControllerChanged: console.log("NavShell serialController CHANGED:", serialController)
}
