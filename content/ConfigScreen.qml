import QtQuick
import QtQuick.Controls
import QtQml
import PilotLine_FrictionTester

ConfigScreenForm {
    id: view

    width: Constants.width
    height: Constants.height

    // passed in from NavShell
    property QtObject appMachine
    property var serialController
    
    // ✅ push wrapper prop down into the Form instance
    serialController: view.serialController


    Component.onCompleted: {
        console.log("✅ HomeScreen WRAPPER LOADED", appMachine)

        if (serialController) {
            console.log("✅ SerialController is available via property")
            console.log("Serial connected:", serialController.connected)
        } else {
            console.error("❌ SerialController is NOT available")
        }
    }

    // show values
    positionText.text: appMachine
        ? qsTr("Position: %1mm").arg(appMachine.position)
        : qsTr("Position: -- (NO MACHINE)")

    speedText.text: qsTr("Speed: %1").arg(speedSlider.value.toFixed(0))

    // keep jogSpeed synced to slider
    speedSlider.onValueChanged: {
        if (!appMachine) return
        appMachine.jogSpeed = Math.round(speedSlider.value)
    }

    function handleJogUp() {
        if (!appMachine) return
        if (appMachine.isHomed && appMachine.status !== "Fault") {
            appMachine.position = Math.min(appMachine.position + appMachine.jogSpeed, 200)
        }
    }

    function handleJogDown() {
        if (!appMachine) return
        if (appMachine.isHomed && appMachine.status !== "Fault") {
            appMachine.position = Math.max(appMachine.position - appMachine.jogSpeed, 0)
        }
    }

    function handleReset() {
        if (!appMachine) return
        appMachine.position = 0
    }

    jogUpButton.onClicked: handleJogUp()
    jogDownButton.onClicked: handleJogDown()
    resetButton.onClicked: handleReset()

    motorToggleButton.checked: appMachine ? appMachine.motorEnabled : false

    motorToggleButton.onClicked: {
        if (!appMachine) return

        if (motorToggleButton.checked) {
            appMachine.motorOn()
            motorToggleButton.text = qsTr("MOTOR: ON")
        } else {
            appMachine.motorOff()
            motorToggleButton.text = qsTr("MOTOR: OFF")
        }
    }

    // PING button handler
    pingButton.onClicked: {
        console.log("PING button clicked")

        if (!serialController) {
            console.error("serialController is null")
            pingStatusBox.color = Constants.accentWarning
            pingResetTimer.restart()
            return
        }

        if (!serialController.connected) {
            console.warn("Not connected. Attempting connect...")
            const ok = serialController.connectPort()
            if (!ok) {
                pingStatusBox.color = Constants.accentWarning
                pingResetTimer.restart()
                return
            }
        }

        console.log("Sending PING...")
        serialController.sendPing() // sends "PING\r\n" from C++
        pingStatusBox.color = Constants.accentSky // "sent"
        pingResetTimer.restart()
    }

    // ✅ Optional but recommended: react to responses/errors
    Connections {
        target: view.serialController ? view.serialController : null

        function onLineReceived(line) {
            console.log("RX:", line)
            if (line.trim() === "PONG") {
                // if you have a success color token; otherwise keep accentSky
                pingStatusBox.color = Constants.accentSuccess !== undefined
                    ? Constants.accentSuccess
                    : Constants.accentSky
                pingResetTimer.restart()
            }
        }

        function onError(message) {
            console.error("Serial error:", message)
            pingStatusBox.color = Constants.accentWarning
            pingResetTimer.restart()
        }
    }

    // Timer to reset the status box color
    Timer {
        id: pingResetTimer
        interval: 500
        onTriggered: pingStatusBox.color = Constants.bgSurface
    }
}
