import QtQuick
import QtQuick.Controls
import QtQml
import PilotLine_FrictionTester

HomeScreenForm {
    id: view

    width: Constants.width
    height: Constants.height

    // passed in from NavShell (keep if you want, but Home no longer needs them)
    property QtObject appMachine
    property var serialController

    // Let NavShell handle init + loading + serial responses
    signal beginPressed()

    Component.onCompleted: {
        console.log("✅ HomeScreen (Begin) LOADED")
    }

    beginButton.onClicked: {
        console.log("Begin pressed (UI)")
        view.beginPressed()
    }
}
