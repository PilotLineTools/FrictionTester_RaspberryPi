import QtQuick
import QtQuick.Controls
import PilotLine_FrictionTester

Rectangle {
    id: root
    width: Constants.width
    height: Constants.height
    color: Constants.bgPrimary

    Text {
        id: activeRun
        x: 656
        y: 487

        width: 348
        height: 106
        color: "#f3f4f6"

        text: qsTr("Active Screen")
        font.pixelSize: 60
    }
}
