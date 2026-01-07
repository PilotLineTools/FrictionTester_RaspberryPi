import QtQuick 6.5
import QtQuick.Controls 6.5
import QtQml
import PilotLine_FrictionTester

TempScreenForm {
    id: view

    width: Constants.width - 260
    height: Constants.height

    // passed in from NavShell
    property QtObject appMachine

    Component.onCompleted: {
        console.log("✅ TempScreen WRAPPER LOADED", appMachine)
    }

}
