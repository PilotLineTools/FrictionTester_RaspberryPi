// App.qml
import QtQuick
import QtQuick.Controls
import QtQuick.VirtualKeyboard
import PilotLine_FrictionTester

Window {
    width: Constants.width
    height: Constants.height
    visible: true
    title: "PilotLine_FrictionTester"

    // Prefer the context property "serialController" (recommended),
    // fall back to "SerialController" if that's what your C++ uses.
    property var serial: (typeof serialController !== "undefined")
                         ? serialController
                         : ((typeof SerialController !== "undefined") ? SerialController : null)

    Component.onCompleted: {
        console.log("App.qml loaded")

        if (serial) {
            console.log("✅ Serial controller is available in App.qml")
            console.log("Serial object:", serial)
            console.log("connected:", serial.connected)
            // Optional: auto-connect at launch
            serial.connectPort()
            
        } else {
            console.error("❌ Serial controller is NOT available in App.qml")
            console.log("If you're using qmlscene, context properties from your C++ app won't exist.")
            console.log("Run the compiled binary that registers the SerialController context property.")
        }

        console.log("serial property:", serial)
    }

    NavShell {
        anchors.fill: parent
        // Update NavShell to accept `serialController` (or `serial`) instead of `uartClient`
        serialController: serial
    }

    InputPanel {
        id: inputPanel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: Qt.inputMethod.visible
        z: 9999
    }
}
