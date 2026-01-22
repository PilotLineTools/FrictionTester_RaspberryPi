/*
  Qt Design Studio UI file (.ui.qml)
  Keep declarative. Put logic in ConfigScreen.qml.
*/
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PilotLine_FrictionTester

Rectangle {
    id: root
    anchors.fill: parent
    color: Constants.bgPrimary
    radius: 0

    // ===== EXPOSE UI ELEMENTS (to ConfigScreen.qml wrapper) =====
    property alias protocolTitleText: protocolTitleText
    //property alias speedValueText: speedValueText
    //property alias clampValueText: clampValueText
    //property alias strokeValueText: strokeValueText
    //property alias tempValueText: tempValueText
    //property alias cyclesValueText: cyclesValueText

    property alias clampToggleButton: clampToggleButton
    property alias jogUpButton: jogUpButton
    property alias jogDownButton: jogDownButton
    property alias runTestButton: runTestButton
    property alias chooseProtocolButton: chooseProtocolButton

    // Page padding
    readonly property int pad: 16
    readonly property int gap: 14

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: root.gap

        // =========================
        // TOP: Protocol Title + Choose
        // =========================
        /*
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 84
            radius: 14
            color: Constants.bgCard
            border.color: Constants.borderDefault
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Item { Layout.fillWidth: true }

                ColumnLayout {
                    spacing: 4
                    Layout.alignment: Qt.AlignHCenter

                    Text {
                        text: qsTr("Selected Protocol")
                        color: Constants.textSecondary
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        id: protocolTitleText
                        text: qsTr("No protocol selected")
                        color: Constants.textPrimary
                        font.pixelSize: 24
                        font.bold: true
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                Item { Layout.fillWidth: true }

                Button {
                    id: chooseProtocolButton
                    text: qsTr("Choose")
                    Layout.preferredWidth: 140
                    Layout.preferredHeight: 44

                    background: Rectangle {
                        radius: 12
                        color: parent.pressed ? Constants.accentSky : Constants.accentPrimary
                    }
                    contentItem: Text {
                        text: qsTr("Choose")
                        color: "white"
                        font.pixelSize: 15
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
        */
        Item { Layout.fillWidth: true }
        // Live Temperature Button (for testing) 
        Button {
            id: liveTemp
            text: qsTr("Temp")
            Layout.preferredWidth: 140
            Layout.preferredHeight: 44

            background: Rectangle {
                radius: 12
                color: parent.pressed ? Constants.accentSky : Constants.bgSurface
            }
            contentItem: Text {
                text: qsTr("Temp")
                color: "white"
                font.pixelSize: 15
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        // =========================
        // Metric cards row
        // =========================
        /*
        GridLayout {
            Layout.fillWidth: true
            columns: 5
            rowSpacing: root.gap
            columnSpacing: root.gap

            // Card helper
            function metricCard(title, valueId) {  }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 112
                radius: 14
                color: Constants.bgCard
                border.color: Constants.borderDefault
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 6

                    Text { text: qsTr("Speed"); color: Constants.textSecondary; font.pixelSize: 11 }
                    Text {
                        id: speedValueText
                        text: qsTr("-")
                        color: Constants.accentSky
                        font.pixelSize: 26
                        font.bold: true
                    }
                    Text { text: qsTr("mm/s"); color: Constants.textMuted; font.pixelSize: 11 }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 112
                radius: 14
                color: Constants.bgCard
                border.color: Constants.borderDefault
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 6

                    Text { text: qsTr("Clamp Force"); color: Constants.textSecondary; font.pixelSize: 11 }
                    Text {
                        id: clampValueText
                        text: qsTr("-")
                        color: "#FBBF24"
                        font.pixelSize: 26
                        font.bold: true
                    }
                    Text { text: qsTr("N"); color: Constants.textMuted; font.pixelSize: 11 }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 112
                radius: 14
                color: Constants.bgCard
                border.color: Constants.borderDefault
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 6

                    Text { text: qsTr("Stroke Length"); color: Constants.textSecondary; font.pixelSize: 11 }
                    Text {
                        id: strokeValueText
                        text: qsTr("-")
                        color: Constants.textPrimary
                        font.pixelSize: 26
                        font.bold: true
                    }
                    Text { text: qsTr("mm"); color: Constants.textMuted; font.pixelSize: 11 }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 112
                radius: 14
                color: Constants.bgCard
                border.color: Constants.borderDefault
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 6

                    Text { text: qsTr("Water Temp"); color: Constants.textSecondary; font.pixelSize: 11 }
                    Text {
                        id: tempValueText
                        text: qsTr("-")
                        color: "#60A5FA"
                        font.pixelSize: 26
                        font.bold: true
                    }
                    Text { text: qsTr("°C"); color: Constants.textMuted; font.pixelSize: 11 }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 112
                radius: 14
                color: Constants.bgCard
                border.color: Constants.borderDefault
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 6

                    Text { text: qsTr("Cycles"); color: Constants.textSecondary; font.pixelSize: 11 }
                    Text {
                        id: cyclesValueText
                        text: qsTr("-")
                        color: "#A78BFA"
                        font.pixelSize: 26
                        font.bold: true
                    }
                    Text { text: qsTr("count"); color: Constants.textMuted; font.pixelSize: 11 }
                }
            }
        } 
        */
        

        // =========================
        // Controls row: Protocol + Controller
        // =========================
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.gap

            // Protocol card
            /*
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 14
                color: Constants.bgCard
                border.color: Constants.borderDefault
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    
                    Text {
                        text: qsTr("Clamp")
                        color: Constants.textSecondary
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Item { Layout.fillHeight: true }
                    
                    Button {
                        id: clampToggleButton
                        Layout.fillWidth: true
                        Layout.preferredHeight: 140
                        text: qsTr("OPEN CLAMP")

                        background: Rectangle {
                            radius: 14
                            color: parent.pressed ? Constants.accentSky : Constants.bgSurface
                            border.color: Constants.borderDefault
                            border.width: 1
                        }

                        contentItem: Text {
                            text: clampToggleButton.text
                            color: Constants.textPrimary
                            font.pixelSize: 22
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                    
                    Item { Layout.fillHeight: true }
                }
            }
            */

            // =========================
            // TOP: Protocol Title + Choose
            // =========================
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 84
                radius: 14
                color: Constants.bgCard
                border.color: Constants.borderDefault
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Item { Layout.fillWidth: true }

                    ColumnLayout {
                        spacing: 4
                        Layout.alignment: Qt.AlignHCenter

                        Text {
                            text: qsTr("Selected Protocol")
                            color: Constants.textSecondary
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            id: protocolTitleText
                            text: qsTr("No protocol selected")
                            color: Constants.textPrimary
                            font.pixelSize: 24
                            font.bold: true
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        id: chooseProtocolButton
                        text: qsTr("Choose")
                        Layout.preferredWidth: 140
                        Layout.preferredHeight: 44

                        background: Rectangle {
                            radius: 12
                            color: parent.pressed ? Constants.accentSky : Constants.accentPrimary
                        }
                        contentItem: Text {
                            text: qsTr("Choose")
                            color: "white"
                            font.pixelSize: 15
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            // Jog card
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 14
                color: Constants.bgCard
                border.color: Constants.borderDefault
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Text {
                        text: qsTr("Contoller")
                        color: Constants.textSecondary
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Item { Layout.fillHeight: true }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Button {
                            id: jogUpButton
                            Layout.fillWidth: true
                            Layout.preferredHeight: 120
                            text: qsTr("▲  UP")

                            background: Rectangle {
                                radius: 14
                                color: parent.pressed ? Constants.accentSky : Constants.bgSurface
                                border.color: Constants.borderDefault
                                border.width: 1
                            }

                            contentItem: Text {
                                text: qsTr("▲  UP")
                                color: Constants.textPrimary
                                font.pixelSize: 22
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Text {
                            text: qsTr("Z Position Value")
                            color: Constants.textSecondary
                            font.pixelSize: 14
                            font.bold: true
                        }

                        Button {
                            id: jogDownButton
                            Layout.fillWidth: true
                            Layout.preferredHeight: 120
                            text: qsTr("▼  DOWN")

                            background: Rectangle {
                                radius: 14
                                color: parent.pressed ? Constants.accentSky : Constants.bgSurface
                                border.color: Constants.borderDefault
                                border.width: 1
                            }

                            contentItem: Text {
                                text: qsTr("▼  DOWN")
                                color: Constants.textPrimary
                                font.pixelSize: 22
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                        

                        // Clamp Toggle Button
                        Button {
                            id: clampToggleButton
                            Layout.fillWidth: true
                            Layout.preferredHeight: 140
                            text: qsTr("OPEN CLAMP")

                            background: Rectangle {
                                radius: 14
                                color: parent.pressed ? Constants.accentSky : Constants.bgSurface
                                border.color: Constants.borderDefault
                                border.width: 1
                            }

                            contentItem: Text {
                                text: clampToggleButton.text
                                color: Constants.textPrimary
                                font.pixelSize: 22
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }

        // =========================
        // Bottom: Run Test (full width)
        // =========================
        Button {
            id: runTestButton
            Layout.fillWidth: true
            Layout.preferredHeight: 72
            text: qsTr("▶  RUN TEST")

            background: Rectangle {
                radius: 16
                color: parent.pressed ? "#059669" : "#10B981"
            }

            contentItem: Text {
                text: qsTr("▶  RUN TEST")
                color: "white"
                font.pixelSize: 22
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
