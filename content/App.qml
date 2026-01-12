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

    Component.onCompleted: {
        console.log("App.qml loaded")
        if (typeof Uart !== "undefined") {
            console.log("✅ Uart context property is available in App.qml")
            console.log("Uart object:", Uart)
        } else {
            console.error("❌ Uart context property is NOT available in App.qml")
            console.log("This usually means the C++ application is not running.")
            console.log("Use the compiled binary instead of qmlscene.")
        }
        console.log("uartClient property:", uartClient)
    }

    NavShell {
        anchors.fill: parent
        uartClient: parent.uartClient
    }
}
