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

    property alias chooseProtocolButton: chooseProtocolButton
    property alias liveTempButton: liveTempButton

    property alias jogUpButton: jogUpButton
    property alias jogDownButton: jogDownButton
    property alias clampToggleButton: clampToggleButton
    property alias runTestButton: runTestButton

    // Z Position input/display
    property alias zPositionField: zPositionField

    // Protocol summary / receipt values
    property alias speedValueText: speedValueText
    property alias clampValueText: clampValueText
    property alias strokeValueText: strokeValueText
    property alias tempValueText: tempValueText
    property alias cyclesValueText: cyclesValueText

    // Page padding
    readonly property int pad: 16
    readonly property int gap: 14

    // =========================
    // MAIN LAYOUT
    // =========================
    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: root.gap

        // =========================
        // Controls row: Left (Protocol) + Right (Controller)
        // =========================
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.gap

            // =========================
            // LEFT COLUMN: Protocol header + Summary/Receipt
            // =========================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: root.gap

                // Top: Protocol Title + Choose
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

                // Protocol summary / receipt
                Rectangle {
                    id: protocolSummaryCard
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 14
                    color: Constants.bgCard
                    border.color: Constants.borderDefault
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10

                        Text {
                            text: qsTr("Protocol Summary")
                            color: Constants.textSecondary
                            font.pixelSize: 14
                            font.bold: true
                        }

                        // Receipt rows
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: qsTr("Speed"); color: Constants.textMuted; font.pixelSize: 13 }
                                Item { Layout.fillWidth: true }
                                Text {
                                    id: speedValueText
                                    text: qsTr("-")
                                    color: Constants.textPrimary
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: qsTr("Clamp Force"); color: Constants.textMuted; font.pixelSize: 13 }
                                Item { Layout.fillWidth: true }
                                Text {
                                    id: clampValueText
                                    text: qsTr("-")
                                    color: Constants.textPrimary
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: qsTr("Stroke"); color: Constants.textMuted; font.pixelSize: 13 }
                                Item { Layout.fillWidth: true }
                                Text {
                                    id: strokeValueText
                                    text: qsTr("-")
                                    color: Constants.textPrimary
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: qsTr("Water Temp"); color: Constants.textMuted; font.pixelSize: 13 }
                                Item { Layout.fillWidth: true }
                                Text {
                                    id: tempValueText
                                    text: qsTr("-")
                                    color: Constants.textPrimary
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: qsTr("Cycles"); color: Constants.textMuted; font.pixelSize: 13 }
                                Item { Layout.fillWidth: true }
                                Text {
                                    id: cyclesValueText
                                    text: qsTr("-")
                                    color: Constants.textPrimary
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }

            // =========================
            // RIGHT CARD: Controller + Jog + Clamp
            // =========================
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
                        text: qsTr("Controller")
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

                        // Z Position display/edit
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Text {
                                text: qsTr("Z Position (mm)")
                                color: Constants.textSecondary
                                font.pixelSize: 14
                                font.bold: true
                            }

                            Item { Layout.fillWidth: true }

                            TextField {
                                id: zPositionField
                                Layout.preferredWidth: 170
                                text: qsTr("0.00")
                                inputMethodHints: Qt.ImhFormattedNumbersOnly
                                validator: DoubleValidator { bottom: -9999; top: 9999; decimals: 2 }

                                background: Rectangle {
                                    radius: 10
                                    color: Constants.bgSurface
                                    border.color: Constants.borderDefault
                                    border.width: 1
                                }

                                color: Constants.textPrimary
                                font.pixelSize: 16
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
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

    // =========================
    // TOP-RIGHT: Live Temp Button overlay
    // =========================
    Button {
        id: liveTempButton
        text: qsTr("Temp")
        width: 140
        height: 44
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: root.pad
        anchors.rightMargin: root.pad
        z: 10

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
}
