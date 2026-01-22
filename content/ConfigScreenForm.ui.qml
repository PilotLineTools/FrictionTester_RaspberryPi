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

    // ===== STATE (set by ConfigScreen.qml) =====
    property bool protocolSelected: false

    // ===== EXPOSE UI ELEMENTS (to ConfigScreen.qml wrapper) =====
    property alias protocolTitleText: protocolTitleText
    property alias chooseProtocolButton: chooseProtocolButton

    // Protocol summary values
    property alias speedValueText: speedValueText
    property alias clampForceValueText: clampForceValueText
    property alias strokeValueText: strokeValueText
    property alias waterTempValueText: waterTempValueText
    property alias cyclesValueText: cyclesValueText

    // Controller elements
    property alias clampToggleButton: clampToggleButton
    property alias currentTempText: currentTempText
    property alias tempStatusText: tempStatusText
    property alias preheatButton: preheatButton

    property alias jogUpButton: jogUpButton
    property alias jogDownButton: jogDownButton
    property alias zPositionField: zPositionField

    property alias runTestButton: runTestButton

    readonly property int pad: 16
    readonly property int gap: 14

    function lockedOpacity() { return root.protocolSelected ? 1.0 : 0.35 }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: root.gap

        // ==================================
        // 1) SELECT PROTOCOL
        // ==================================
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

        // ==================================
        // 2) PROTOCOL SUMMARY (two columns, full width)
        // ==================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 180
            radius: 14
            color: Constants.bgCard
            border.color: Constants.borderDefault
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Text {
                    text: qsTr("Protocol Summary")
                    color: Constants.textSecondary
                    font.pixelSize: 14
                    font.bold: true
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 22
                    

                    // Left column
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: parent.width / 2 - 11
                        Text { text: qsTr("Speed"); color: Constants.textMuted; font.pixelSize: 13 }
                        Item { Layout.fillWidth: true }
                        Text { id: speedValueText; text: qsTr("-"); color: Constants.textPrimary; font.pixelSize: 13; font.bold: true }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: parent.width / 2 - 11
                        Text { text: qsTr("Clamp Force"); color: Constants.textMuted; font.pixelSize: 13 }
                        Item { Layout.fillWidth: true }
                        Text { id: clampForceValueText; text: qsTr("-"); color: Constants.textPrimary; font.pixelSize: 13; font.bold: true }
                    }

                    // Right column
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: parent.width / 2 - 11
                        Text { text: qsTr("Stroke"); color: Constants.textMuted; font.pixelSize: 13 }
                        Item { Layout.fillWidth: true }
                        Text { id: strokeValueText; text: qsTr("-"); color: Constants.textPrimary; font.pixelSize: 13; font.bold: true }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: parent.width / 2 - 11
                        Text { text: qsTr("Water Temp"); color: Constants.textMuted; font.pixelSize: 13 }
                        Item { Layout.fillWidth: true }
                        Text { id: waterTempValueText; text: qsTr("-"); color: Constants.textPrimary; font.pixelSize: 13; font.bold: true }
                    }

                    
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: parent.width / 2 - 11
                        Text { text: qsTr("Cycles"); color: Constants.textMuted; font.pixelSize: 13 }
                        Item { Layout.fillWidth: true }
                        Text { id: cyclesValueText; text: qsTr("-"); color: Constants.textPrimary; font.pixelSize: 13; font.bold: true }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        // ==================================
        // 3) MACHINE CONTROLLER (3 columns as 3 rectangles)
        // ==================================
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
                    text: qsTr("Machine Controller")
                    color: Constants.textSecondary
                    font.pixelSize: 14
                    font.bold: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    // -----------------------------
                    // COL 1: TEMP CARD
                    // -----------------------------
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        radius: 14
                        color: Constants.bgSurface
                        border.color: Constants.borderDefault
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 8

                            Text {
                                text: qsTr("Temperature")
                                color: Constants.textSecondary
                                font.pixelSize: 13
                                font.bold: true
                            }

                            Item { Layout.fillHeight: true }

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: qsTr("Current Temp.")
                                    color: Constants.textSecondary
                                    font.pixelSize: 13
                                    font.bold: true
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: qsTr("Test Temp. Target")
                                    color: Constants.textSecondary
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    id: currentTempText
                                    text: qsTr("-- °C")
                                    color: Constants.textPrimary
                                    font.pixelSize: 36
                                    font.bold: true
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    id: tempStatusText
                                    text: root.protocolSelected ? (waterTempValueText.text + " °C") : qsTr("-- °C")
                                    color: Constants.textPrimary
                                    font.pixelSize: 36
                                    font.bold: true
                                }
                            }

                            Item { Layout.fillHeight: true }

                            Button {
                                id: preheatButton
                                Layout.fillWidth: true
                                Layout.preferredHeight: 100
                                text: qsTr("Preheat")

                                enabled: root.protocolSelected
                                opacity: root.lockedOpacity()

                                background: Rectangle {
                                    radius: 14
                                    color: parent.enabled
                                           ? (parent.pressed ? Constants.accentSky : Constants.accentPrimary)
                                           : Constants.bgPrimary
                                    border.color: Constants.borderDefault
                                    border.width: 1
                                }

                                contentItem: Text {
                                    text: qsTr("PREHEAT")
                                    color: Constants.textPrimary
                                    font.pixelSize: 22
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }

                    // -----------------------------
                    // COL 2: JOG CARD (stacked)
                    // -----------------------------
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        radius: 14
                        color: Constants.bgSurface
                        border.color: Constants.borderDefault
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 12

                            Text {
                                text: qsTr("Start Position")
                                color: Constants.textSecondary
                                font.pixelSize: 13
                                font.bold: true
                            }

                            Button {
                                id: jogUpButton
                                Layout.fillWidth: true
                                Layout.preferredHeight: 100
                                text: qsTr("▲  UP")

                                enabled: root.protocolSelected
                                opacity: root.lockedOpacity()

                                background: Rectangle {
                                    radius: 14
                                    color: parent.enabled
                                           ? (parent.pressed ? Constants.accentSky : Constants.accentPrimary)
                                           : Constants.bgPrimary
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

                            TextField {
                                id: zPositionField
                                Layout.fillWidth: true
                                Layout.preferredHeight: 52
                                text: qsTr("0.00")

                                enabled: root.protocolSelected
                                opacity: root.lockedOpacity()

                                inputMethodHints: Qt.ImhFormattedNumbersOnly
                                validator: DoubleValidator { bottom: -9999; top: 9999; decimals: 2 }

                                background: Rectangle {
                                    radius: 12
                                    color: Constants.bgSurface
                                    border.color: Constants.borderDefault
                                    border.width: 1
                                }

                                color: Constants.textPrimary
                                font.pixelSize: 18
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            Button {
                                id: jogDownButton
                                Layout.fillWidth: true
                                Layout.preferredHeight: 100
                                text: qsTr("▼  DOWN")

                                enabled: root.protocolSelected
                                opacity: root.lockedOpacity()

                                background: Rectangle {
                                    radius: 14
                                    color: parent.enabled
                                           ? (parent.pressed ? Constants.accentSky : Constants.accentPrimary)
                                           : Constants.bgPrimary
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

                            Item { Layout.fillHeight: true }
                        }
                    }

                    // -----------------------------
                    // COL 3: CLAMP CARD
                    // -----------------------------
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        radius: 14
                        color: Constants.bgSurface
                        border.color: Constants.borderDefault
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 12

                            Text {
                                text: qsTr("Clamp")
                                color: Constants.textSecondary
                                font.pixelSize: 13
                                font.bold: true
                            }

                            Button {
                                id: clampToggleButton
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                text: qsTr("OPEN CLAMP")

                                enabled: root.protocolSelected
                                opacity: root.lockedOpacity()

                                background: Rectangle {
                                    radius: 14
                                    color: parent.enabled
                                           ? (parent.pressed ? Constants.accentSky : Constants.accentPrimary)
                                           : Constants.bgPrimary
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
                    }
                }
            }
        }

        // ==================================
        // 4) Fine print MESSAGE AREA (info/warning) that only is visible when there is a message to show
        // ==================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            radius: 12
            color: "#FEF3C7"   // yellow-100
            border.color: "#F59E0B"  // yellow-500
            border.width: 1
            visible: false   // set to true by ConfigScreen.qml when there is a message to show

            Text {
                id: messageText
                anchors.fill: parent
                anchors.margins: 12
                text: qsTr("This is a warning or info message.")
                color: "#92400E"  // yellow-800
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
        }

        // ==================================
        // 5) RUN TEST (locked until protocol chosen)
        // ==================================
        Button {
            id: runTestButton
            Layout.fillWidth: true
            Layout.preferredHeight: 72
            text: qsTr("▶  RUN TEST")

            enabled: root.protocolSelected
            opacity: root.protocolSelected ? 1.0 : 0.4

            background: Rectangle {
                radius: 16
                color: parent.enabled
                       ? (parent.pressed ? "#059669" : "#10B981")
                       : "#064E3B"
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
