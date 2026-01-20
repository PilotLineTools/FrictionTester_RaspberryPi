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

    // Sidebar enabled only when safe (idle/config/browse) and dialog not visible
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

    // Home "Begin" -> show loading -> wait for PREP_COMPLETE -> config
    function beginInit() {
        if (uiState === "initializing") return
        uiState = "initializing"
        initStatusText = "Prepping for test"
        serialController.prep_test_run()
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
                // open protocols in select-only mode (no prep)
                shell.protocolsMode = "selectOnly"
                shell.uiState = "browse"
                stack.replace(protocolsComp)
                setChecked("protocols")
                prevCheckedTarget = "protocols"
            }

            // ✅ Decide run behavior here
            onRunTestRequested: {
                if (!machineState.selectedProtocol) {
                    console.warn("Run requested but no protocol selected")
                    return
                }

                // If already in config (meaning prep already done), go to running next (later)
                // For now, keep a placeholder transition:
                // shell.uiState = "running"

                // If user somehow is here without prep (rare), prep now:
                if (shell.uiState === "browse") {
                    shell.beginInit()
                } else {
                    console.log("Run requested from config (prep already complete)")
                    // TODO: transition to running screen when ready
                }
            }
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
                    // just return to config, no prep
                    shell.uiState = "config"
                    setChecked("home")
                    prevCheckedTarget = "home"
                    return
                }

                // prepAndRun mode: select + prep, then PREP_COMPLETE will route to config
                shell.uiState = "initializing"
                shell.initStatusText = "Prepping for test"
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
            // keep whatever was previously checked
        } else if (uiState === "config") {
            stack.replace(configComp)
            setChecked("home")
            prevCheckedTarget = "home"
        }
    }

    Component.onCompleted: {
        uiState = "idle"
        routeToState()
    }

    onUiStateChanged: {
        if (uiState === "idle" || uiState === "initializing" || uiState === "config") {
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

        if (!(uiState === "idle" || uiState === "config" || uiState === "browse")) {
            console.log("Nav blocked in state:", uiState)
            // restore highlight
            setChecked(prevCheckedTarget)
            return
        }

        // In config: confirmation before leaving
        if (uiState === "config") {
            pendingNavTarget = target

            // ✅ immediately force highlight back to Home while dialog is open
            setChecked("home")
            prevCheckedTarget = "home"

            exitConfigDialog.open()
            return
        }

        // Idle/browse: navigate immediately
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

        // ✅ IMPORTANT: set protocolsMode depending on where user came from
        if (t === "protocols") {
            // Normal sidebar visit should prep+run behavior
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

        onOpened: {
            // ensure home is highlighted while modal is visible
            setChecked("home")
        }

        onClosed: {
            // If user canceled by tapping outside / Cancel, keep them in config visually as Home
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

                        // ✅ confirmed leaving config → clear selected protocol
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
                } else if (msg.startsWith("INIT_ERROR")) {
                    shell.initStatusText = msg
                    shell.uiState = "idle"
                    return
                }
            }
        }
    }
}
