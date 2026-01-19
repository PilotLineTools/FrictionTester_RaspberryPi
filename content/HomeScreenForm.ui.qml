/*
  Qt Design Studio UI file (.ui.qml)
  Keep this declarative (layout + styling). Put logic in HomeScreen.qml.
*/
import QtQuick 6.5
import QtQuick.Controls 6.5
import QtQuick.Layouts 6.5
import PilotLine_FrictionTester

Rectangle {
    id: root
    width: Constants.width - 117
    height: Constants.height
    color: Constants.bgPrimary
    radius: 0

    // Expose the button to the wrapper
    property alias beginButton: beginButton

    Button {
        id: beginButton
        text: qsTr("Begin")
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: 240
        height: 72

        font.pixelSize: 24

        // Optional: make it feel more “primary”
        background: Rectangle {
            radius: 14
            color: Constants.accentPrimary
        }

        contentItem: Text {
            text: beginButton.text
            color: "white"
            font.pixelSize: 24
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
