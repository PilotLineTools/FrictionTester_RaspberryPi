import QtQuick
import QtQuick.Controls
import QtQml
import PilotLine_FrictionTester

HomeScreenForm {
    id: view

    width: Constants.width
    height: Constants.height

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
