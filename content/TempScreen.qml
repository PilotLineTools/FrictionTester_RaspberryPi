import QtQuick
import QtQuick.Controls
import QtQml
import PilotLine_FrictionTester

TempScreenForm {
    id: view

    width: Constants.width
    height: Constants.height

    // passed in from NavShell
    property QtObject appMachine

    Component.onCompleted: {
        console.log("✅ TempScreen WRAPPER LOADED", appMachine)
    }

}
