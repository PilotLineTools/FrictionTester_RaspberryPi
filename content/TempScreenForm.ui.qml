
/*
  Qt Design Studio UI file (.ui.qml)
  Keep this declarative (layout + styling). Put logic in HomeScreen.qml.
*/
import QtQuick
import QtQuick.Controls
import PilotLine_FrictionTester

Rectangle {
    id: root
    anchors.fill: parent
    color: Constants.bgPrimary

    Text {
        id: temp
        color: "#f3f4f6"

        text: qsTr("Temp Screen")
        font.pixelSize: 60
    }
}
