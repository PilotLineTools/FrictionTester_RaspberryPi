import QtQuick
import QtQuick.Controls
import QtQml
import PilotLine_FrictionTester

NavShellForm {
    id: shell

    width: Constants.width
    height: Constants.height


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
        }

        function motorOff() {
            motorEnabled = false
            console.log("➡️ Send to ESP32: MOTOR_OFF")
        }

    }

    Component { id: homeComp; HomeScreen { appMachine: machineState } }
    Component { id: protocolsComp; TempScreen { appMachine: machineState  } }
    Component { id: settingsComp; SettingsScreen { appMachine: machineState  } }
    Component { id: calibrationComp; TempScreen { appMachine: machineState  } }
    Component { id: aboutComp; TempScreen { appMachine: machineState  } }

    Component.onCompleted: stack.replace(homeComp)

    homeButton.onClicked:        stack.replace(homeComp)
    protocolsButton.onClicked:   stack.replace(protocolsComp)
    settingsButton.onClicked:    stack.replace(settingsComp)
    calibrationButton.onClicked: stack.replace(calibrationComp)
    aboutButton.onClicked:       stack.replace(aboutComp)
}
