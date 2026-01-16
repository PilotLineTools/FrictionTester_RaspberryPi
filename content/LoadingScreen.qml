import QtQuick
import QtQuick.Controls
import QtQml
import PilotLine_FrictionTester

LoadingScreenForm {
    id: view

    width: Constants.width
    height: Constants.height

    // passed in from NavShell
    property string statusText: "Initializing…"

    // push down into the Form
    statusText: view.statusText

    Component.onCompleted: {
        console.log("✅ LoadingScreen LOADED:", statusText)
    }
}
