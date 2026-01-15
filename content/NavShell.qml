import QtQuick
import QtQuick.Controls
import QtQml
import PilotLine_FrictionTester

NavShellForm {
    id: shell

    width: Constants.width
    height: Constants.height

    // ✅ NEW: replace uartClient with SerialController
    property var serialController: null

    

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

        // Same Pi backend
        property string apiBase: "http://127.0.0.1:8080"

        function request(method, path, body, cb) {
            var xhr = new XMLHttpRequest()
            xhr.open(method, apiBase + path)
            xhr.setRequestHeader("Content-Type", "application/json")

            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    var ok = (xhr.status >= 200 && xhr.status < 300)
                    var data = null
                    try { data = xhr.responseText ? JSON.parse(xhr.responseText) : null } catch(e) {}
                    if (cb) cb(ok, xhr.status, data)
                }
            }

            xhr.send(body ? JSON.stringify(body) : null)
        }
    }

    // ✅ Pass SerialController down instead of uartClient
    Component { id: homeComp; HomeScreen { appMachine: machineState; serialController: shell.serialController } }
    Component { id: protocolsComp; ProtocolsScreen { ppMachine: machineState; serialController: shell.serialController; backend: pythonBackend } }
    Component { id: settingsComp; SettingsScreen { appMachine: machineState } }
    Component { id: calibrationComp; TempScreen { appMachine: machineState } }
    Component { id: aboutComp; TempScreen { appMachine: machineState } }

    Component.onCompleted: {
        console.log("NavShell loaded, serialController:", serialController,
                    "connected:", serialController ? serialController.connected : "null")
        stack.replace(homeComp)
    }

    homeButton.onClicked:        stack.replace(homeComp)
    protocolsButton.onClicked:   stack.replace(protocolsComp)
    settingsButton.onClicked:    stack.replace(settingsComp)
    calibrationButton.onClicked: stack.replace(calibrationComp)
    aboutButton.onClicked:       stack.replace(aboutComp)

    onSerialControllerChanged: console.log("NavShell serialController CHANGED:", serialController)

}
