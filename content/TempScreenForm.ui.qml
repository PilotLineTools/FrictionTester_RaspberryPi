
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
        id: temp
        x: 656
        y: 487

        width: 348
        height: 106
        color: "#f3f4f6"

        text: qsTr("Temp Screen")
        font.pixelSize: 60
    }
}
