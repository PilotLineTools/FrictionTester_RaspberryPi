
/*
  Qt Design Studio UI file (.ui.qml)
  Keep this declarative (layout + styling). Put logic in HomeScreen.qml.
*/
import QtQuick 6.5
import QtQuick.Controls 6.5
import PilotLine_FrictionTester

Rectangle {
    id: root
    width: Constants.width - 260
    height: Constants.height
    color: Constants.bgPrimary

    Text {
        id: title
        x: 0
        y: 0

        width: 154
        height: 42
        color: "#f3f4f6"

        text: qsTr("Settings")
        font.pixelSize: 30
    }
}
