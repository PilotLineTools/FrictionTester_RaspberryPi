
/*
  Qt Design Studio UI file (.ui.qml)
  Keep this declarative (layout + styling). Put logic in HomeScreen.qml.
*/
import QtQuick
import QtQuick.Controls
import PilotLine_FrictionTester

Rectangle {
    id: root
    width: Constants.width - 260
    height: Constants.height
    color: Constants.bgPrimary

    // ✅ EXPOSE UI ELEMENTS
    property alias positionText: positionText
    property alias speedText: speedText
    property alias jogUpButton: jogUpButton
    property alias jogDownButton: jogDownButton
    property alias resetButton: resetButton
    property alias speedSlider: speedSlider
    property alias motorToggleButton: motorToggleButton

    // ================================================
    //  Content Area - Jog Control
    // ================================================
    Rectangle {
        id: jog_control_content
        x: 71
        y: 66
        width: 943
        height: 329
        color: Constants.bgCard

        Text {
            id: jog_control_title
            x: 48
            y: 45
            width: 337
            height: 63
            text: qsTr("Jog Control")
            font.pixelSize: 45
            color: "#F3F4F6"
        }

        Text {
            id: speedText
            x: 543
            y: 93
            width: 235
            text: qsTr("Speed: --")
            height: 70
            font.pixelSize: 45
            color: "#F3F4F6"
        }

        Slider {
            id: speedSlider
            x: 485
            y: 139
            width: 350
            height: 93
            from: 1
            to: 50
            value: 1
        }

        Row {
            id: posittion_control_row
            x: 48
            y: 127

            spacing: 40

            Button {
                id: jogUpButton

                width: 156
                height: 75
                text: qsTr("↑ UP")
                font.pixelSize: 25
            }

            Button {
                id: jogDownButton

                width: 156
                height: 75
                text: qsTr("↓ DOWN")
                font.pixelSize: 25
            }
        }

        Button {
            id: resetButton
            x: 48
            y: 232
            width: 372
            height: 75
            text: qsTr("Reset Position")
            font.pixelSize: 25
        }
    }

    // ================================================
    //  Content Area - Live Readings
    // ================================================
    Rectangle {
        id: live_readings_content
        x: 1059
        y: 66
        width: 552
        height: 329
        color: Constants.bgCard

        Text {
            id: live_readings_title
            x: 25
            y: 40
            width: 337
            height: 63
            color: "#f3f4f6"
            text: qsTr("Live Readings")
            font.pixelSize: 45
        }

        Column {
            id: readout
            x: 25
            y: 109
            Text {
                id: positionText

                width: 519
                height: 42
                color: "#f3f4f6"
                text: qsTr("Position: --")
                font.pixelSize: 30
            }

            Text {
                id: live_pullforce

                width: 519
                height: 42
                color: "#f3f4f6"

                text: qsTr("Pull Force: --")
                font.pixelSize: 30
            }
            Text {
                id: live_clampforce

                width: 519
                height: 42
                color: "#f3f4f6"

                text: qsTr("Clamp Force: --")
                font.pixelSize: 30
            }
            Text {
                id: live_watertemp

                width: 519
                height: 42
                color: "#f3f4f6"

                text: qsTr("Water Temp: --")
                font.pixelSize: 30
            }
        }
    }

    // ================================================
    //  Content Area - Water Bath
    // ================================================
    Rectangle {
        id: water_bath_content
        x: 79
        y: 455
        width: 935
        height: 383
        color: Constants.bgCard

        Button {
            id: motorToggleButton
            x: 503
            y: 232
            width: 372
            height: 75
            font.pixelSize: 25
            text: qsTr("Motor: OFF")
            checkable: true
        }
    }

    // ================================================
    //  Content Area - Test Protocol
    // ================================================
    Rectangle {
        id: test_protocol_content
        x: 1059
        y: 482
        width: 552
        height: 329
        color: Constants.bgCard
    }
}
