import QtQuick
import QtQuick.Controls
import PilotLine_FrictionTester

// ================================================
//  Content Area - Main View
// ================================================
Rectangle {
    id: overall_content_view
    width: Constants.width
    height: Constants.height
    color: Constants.backgroundColor

    // 1) Group for mutual exclusivity
    ButtonGroup {
        id: navGroup
        exclusive: true
    }

    // 2) NAV BUTTONS

    // ================================================
    //  Button - Home
    // ================================================
    Button {
        id: button_home
        width: 233
        height: 185
        text: qsTr("Home")
        checkable: true
        checked: true
        ButtonGroup.group: navGroup

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: -820
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -428
    }

    // ================================================
    //  Button - Protocol
    // ================================================
    Button {
        id: button_protocols
        width: 233
        height: 185
        text: qsTr("Protocols")
        checkable: true
        ButtonGroup.group: navGroup

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: -820
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -211
    }

    // ================================================
    //  Button- Settings
    // ================================================
    Button {
        id: button_settings
        width: 233
        height: 185
        text: qsTr("Settings")
        checkable: true
        ButtonGroup.group: navGroup

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: -820
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 3
    }

    // ================================================
    //  Button- Calibration
    // ================================================
    Button {
        id: button_calibration
        width: 233
        height: 185
        text: qsTr("Calibration")
        checkable: true
        ButtonGroup.group: navGroup

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: -820
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 213
    }

    // ================================================
    //  Button- About
    // ================================================
    Button {
        id: button_about
        width: 233
        height: 185
        text: qsTr("About")
        checkable: true
        ButtonGroup.group: navGroup

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: -820
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 429
    }

    // 3) CONTENT VIEWS (one per button)

    // ================================================
    //  Content Area - Home View
    // ================================================
    Rectangle {
        id: home_content_view
        x: 262
        y: 19
        width: 1639
        height: 1042
        color: "#ffffff"
        visible: button_home.checked

        property real position_value: 0.0
        property real pull_value: 0.0
        property real clamp_value: 0.0
        property real watertemp_value: 0.0

        // ================================================
        //  Content Area - Jog Control
        // ================================================
        Rectangle {
            id: jog_control_content
            x: 71
            y: 66
            width: 943
            height: 329
            color: "#000000"

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

            Slider {
                id: slider_jogcontrol_speed
                x: 485
                y: 139
                width: 350
                height: 93
                from: 1
                to: 50
                value: 1
            }

            Text {
                x: 543
                y: 93
                width: 235
                text: qsTr(
                          "Speed:  ") + slider_jogcontrol_speed.value.toFixed(0)
                height: 70
                font.pixelSize: 45
                color: "#F3F4F6"
            }

            Row {
                id: posittion_control_row
                x: 48
                y: 127

                spacing: 40

                Button {
                    id: button_positionup

                    width: 156
                    height: 75
                    text: qsTr("↑ UP")
                    font.pixelSize: 25
                    onClicked: home_content_view.position_value += 1
                }

                Button {
                    id: button_positiondown

                    width: 156
                    height: 75
                    text: qsTr("↓ DOWN")
                    font.pixelSize: 25
                    onClicked: home_content_view.position_value -= 1
                }
            }

            Button {
                id: button_resetposition
                x: 48
                y: 232
                width: 372
                height: 75
                text: qsTr("Reset Position")
                font.pixelSize: 25
                onClicked: home_content_view.position_value = 0
            }

            Button {
                id: button_padcontrol
                x: 493
                y: 232
                width: 372
                height: 75
                text: qsTr("Button")
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
            color: "#000000"

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
                    id: live_position

                    width: 519
                    height: 42
                    color: "#f3f4f6"
                    text: qsTr("Position:  ") + home_content_view.position_value + qsTr(
                              "mm")
                    font.pixelSize: 30
                }
                Text {
                    id: live_pullforce

                    width: 519
                    height: 42
                    color: "#f3f4f6"

                    text: qsTr("Pull Force:  ") + home_content_view.pull_value + qsTr(
                              "N")
                    font.pixelSize: 30
                }
                Text {
                    id: live_clampforce

                    width: 519
                    height: 42
                    color: "#f3f4f6"

                    text: qsTr("Clamp Force:  ") + home_content_view.clamp_value + qsTr(
                              "N")
                    font.pixelSize: 30
                }
                Text {
                    id: live_watertemp

                    width: 519
                    height: 42
                    color: "#f3f4f6"

                    text: qsTr("Watter Temp:  ") + home_content_view.watertemp_value + qsTr(
                              "°C")
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
            color: "#000000"
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
            color: "#000000"
        }
    }

    // ================================================
    //  Content Area - Protocols View
    // ================================================
    Rectangle {
        id: protocols_content_view
        x: 262
        y: 19
        width: 1639
        height: 1042
        color: "#F3F4F6"
        visible: button_protocols.checked

        ScrollView {
            id: scrollView
            x: 41
            y: 834
            width: 200
            height: 200
        }
    }

    // ================================================
    //  Content Area - Settings View
    // ================================================
    Rectangle {
        id: settings_content_view
        x: 262
        y: 19
        width: 1639
        height: 1042
        color: "#E5E7EB"
        visible: button_settings.checked
    }

    // ================================================
    //  Content Area - Calibration View
    // ================================================
    Rectangle {
        id: calibration_content_view
        x: 262
        y: 19
        width: 1639
        height: 1042
        color: "#D1D5DB"
        visible: button_calibration.checked
    }

    // ================================================
    //  Content Area - About View
    // ================================================
    Rectangle {
        id: about_content_view
        x: 262
        y: 19
        width: 1639
        height: 1042
        color: "#CBD5E1"
        visible: button_about.checked
    }
}
