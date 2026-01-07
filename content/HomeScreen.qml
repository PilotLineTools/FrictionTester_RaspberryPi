import QtQuick
import QtQuick.Controls
import QtQml
import PilotLine_FrictionTester

HomeScreenForm {
    id: view

    // passed in from NavShell
    property QtObject appMachine

    Component.onCompleted: {
        console.log("✅ HomeScreen WRAPPER LOADED", appMachine)
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

}
