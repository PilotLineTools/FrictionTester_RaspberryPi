/*
This is a UI file (.ui.qml) intended to be edited in Qt Design Studio.
*/
import QtQuick 6.5
import QtQuick.Controls 6.5
import PilotLine_FrictionTester

Rectangle {
    id: root
    width: Constants.width
    height: Constants.height
    color: Constants.bgPrimary

    // Expose label text to wrapper
    property alias statusText: statusTextItem.text

    Column {
        anchors.centerIn: parent
        spacing: 18

        BusyIndicator {
            id: spinner
            running: true
            width: 72
            height: 72
        }

        Text {
            id: statusTextItem
            text: "Initializing…"
            color: Constants.textPrimary
            font.pixelSize: 20
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "Please wait"
            color: Constants.textSecondary
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
