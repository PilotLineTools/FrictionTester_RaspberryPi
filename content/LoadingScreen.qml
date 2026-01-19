import QtQuick
import QtQuick.Controls
import QtQml
import PilotLine_FrictionTester

LoadingScreenForm {
    id: view

    anchors.fill: parent

    // ✅ Rename to avoid clashing with LoadingScreenForm.statusText
    property string statusMessage: "Initializing…"

    // ✅ Drive the form’s alias property
    statusText: statusMessage

    Component.onCompleted: {
        console.log("✅ LoadingScreen LOADED:", statusMessage)
    }
}
