// App.qml
import QtQuick
import QtQuick.Controls
import PilotLine_FrictionTester

Window {
    width: Constants.width
    height: Constants.height
    visible: true
    title: "PilotLine_FrictionTester"

    // Get Uart from context property and pass it down
    property var uartClient: (typeof Uart !== "undefined") ? Uart : null

    NavShell {
        anchors.fill: parent
        uartClient: parent.uartClient
    }
}
