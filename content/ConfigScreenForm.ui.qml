
/*
  Qt Design Studio UI file (.ui.qml)
  Keep this declarative (layout + styling). Put logic in HomeScreen.qml.
*/
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PilotLine_FrictionTester

Rectangle {
    id: root
    width: Constants.width
    height: Constants.height
    color: Constants.bgPrimary
    radius: 0

    // ✅ EXPOSE UI ELEMENTS
    property alias positionText: positionText
    property alias speedText: speedText
    property alias jogUpButton: jogUpButton
    property alias jogDownButton: jogDownButton
    property alias resetButton: resetButton
    property alias speedSlider: speedSlider
    property alias motorToggleButton: motorToggleButton
    property alias pingButton: pingButton
    property alias pingStatusBox: pingStatusBox
    property alias protocolNameText: protocolNameText
    property alias chooseProtocolButton: chooseProtocolButton

    
    // Property to receive SerialController from parent
    property var serialController: null


    // Page padding
    readonly property int pad: 12
    readonly property int gap: 12

    GridLayout {
        id: grid
        anchors.fill: parent
        anchors.margins: root.pad
        rowSpacing: root.gap
        columnSpacing: root.gap
        columns: 2

        // Make left column wider than right
        //columnStretchFactor: [3, 2]

        // =========================
        // Jog Control (top-left)
        // =========================
        Rectangle {
            id: jog_control_content
            color: Constants.bgCard
            radius: 12

            Layout.fillWidth: true
            Layout.fillHeight: true

            // Give this row more height than bottom row
            Layout.preferredHeight: 230

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        id: jog_control_title
                        text: qsTr("Jog Control")
                        color: "#F3F4F6"
                        font.pixelSize: 22
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        id: speedText
                        text: qsTr("Speed: --")
                        color: "#F3F4F6"
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignRight
                        Layout.preferredWidth: 160
                    }
                }

                Slider {
                    id: speedSlider
                    from: 1
                    to: 50
                    value: 1
                    Layout.fillWidth: true
                }

                RowLayout {
                    id: posittion_control_row
                    Layout.fillWidth: true
                    spacing: 10

                    Button {
                        id: jogUpButton
                        text: qsTr("↑ UP")
                        font.pixelSize: 16
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                    }

                    Button {
                        id: jogDownButton
                        text: qsTr("↓ DOWN")
                        font.pixelSize: 16
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                    }
                }

                Button {
                    id: resetButton
                    text: qsTr("Reset Position")
                    font.pixelSize: 16
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    rotation: 0
                }
            }
        }

        // =========================
        // Live Readings (top-right)
        // =========================
        Rectangle {
            id: live_readings_content
            color: Constants.bgCard
            radius: 12

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 230

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Text {
                    id: live_readings_title
                    text: qsTr("Live Readings")
                    color: "#F3F4F6"
                    font.pixelSize: 22
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                ColumnLayout {
                    id: readout
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        id: positionText
                        text: qsTr("Position: --")
                        color: "#F3F4F6"
                        font.pixelSize: 16
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        id: live_pullforce
                        text: qsTr("Pull Force: --")
                        color: "#F3F4F6"
                        font.pixelSize: 16
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        id: live_clampforce
                        text: qsTr("Clamp Force: --")
                        color: "#F3F4F6"
                        font.pixelSize: 16
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        id: live_watertemp
                        text: qsTr("Water Temp: --")
                        color: "#F3F4F6"
                        font.pixelSize: 16
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                Item {
                    Layout.fillHeight: true
                } // spacer
            }
        }

        // =========================
        // Water Bath (bottom-left)
        // =========================
        Rectangle {
            id: water_bath_content
            color: Constants.bgCard
            radius: 12

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 200

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Text {
                    text: qsTr("Water Bath")
                    color: "#F3F4F6"
                    font.pixelSize: 22
                    Layout.fillWidth: true
                }

                Item {
                    Layout.fillHeight: true
                }

                Button {
                    id: motorToggleButton
                    text: qsTr("Motor: OFF")
                    checkable: true
                    font.pixelSize: 16
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                }
            }
        }

        // =========================
        // Test Protocol (bottom-right)
        // =========================
        Rectangle {
            id: test_protocol_content
            color: Constants.bgCard
            radius: 12

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 200

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Text {
                    text: qsTr("Test Protocol")
                    color: "#F3F4F6"
                    font.pixelSize: 22
                    Layout.fillWidth: true
                }

                // Selected Protocol
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: qsTr("Selected Protocol")
                            color: "#9CA3AF"
                            font.pixelSize: 12
                        }

                        Text {
                            id: protocolNameText
                            text: qsTr("No protocol selected")
                            color: "#F3F4F6"
                            font.pixelSize: 16
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Button {
                        id: chooseProtocolButton
                        text: qsTr("Choose")
                        font.pixelSize: 14
                        Layout.preferredWidth: 110
                        Layout.preferredHeight: 40
                    }
                }


                // ESP32 PING Section
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        id: pingStatusBox
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: 8
                        color: Constants.bgSurface
                        border.color: Constants.borderDefault
                        border.width: 2
                    }

                    Button {
                        id: pingButton
                        text: qsTr("PING ESP32")
                        font.pixelSize: 16
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }
    }
}
