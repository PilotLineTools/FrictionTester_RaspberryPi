import QtQuick 6.5
import QtQuick.Controls 6.5
import PilotLine_FrictionTester

Rectangle {
    id: root
    width: Constants.width
    height: Constants.height
    color: Constants.bgPrimary

    // Expose status text to wrapper (ONLY this; do not define another statusText property)
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
            text: "Initializing…"   // default, wrapper overwrites via alias
            color: Constants.textPrimary
            font.pixelSize: 20
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            text: "Please wait…"
            color: Constants.textSecondary
            alignment: Text.AlignHCenter
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
