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
    // Set true once a protocol is selected so motion controls can be enabled.
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

    // Page padding
    readonly property int pad: 16
    readonly property int gap: 14

    // Small helper for "locked" styling
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
            Layout.preferredHeight: 92
            radius: 14
            color: Constants.bgCard
            border.color: Constants.borderDefault
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: qsTr("Selected Protocol")
                        color: Constants.textSecondary
                        font.pixelSize: 12
                    }

                    Text {
                        id: protocolTitleText
                        text: qsTr("No protocol selected")
                        color: Constants.textPrimary
                        font.pixelSize: 24
                        font.bold: true
                        elide: Text.ElideRight
                    }
                }

                Button {
                    id: chooseProtocolButton
                    text: qsTr("Choose")
                    Layout.preferredWidth: 160
                    Layout.preferredHeight: 48

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
        // 2) PROTOCOL SUMMARY (two columns)
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
                        Text { text: qsTr("Speed"); color: Constants.textMuted; font.pixelSize: 13 }
                        Item { Layout.fillWidth: true }
                        Text { id: speedValueText; text: qsTr("-"); color: Constants.textPrimary; font.pixelSize: 13; font.bold: true }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: qsTr("Clamp Force"); color: Constants.textMuted; font.pixelSize: 13 }
                        Item { Layout.fillWidth: true }
                        Text { id: clampForceValueText; text: qsTr("-"); color: Constants.textPrimary; font.pixelSize: 13; font.bold: true }
                    }

                    // Right column
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: qsTr("Stroke"); color: Constants.textMuted; font.pixelSize: 13 }
                        Item { Layout.fillWidth: true }
                        Text { id: strokeValueText; text: qsTr("-"); color: Constants.textPrimary; font.pixelSize: 13; font.bold: true }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: qsTr("Water Temp"); color: Constants.textMuted; font.pixelSize: 13 }
                        Item { Layout.fillWidth: true }
                        Text { id: waterTempValueText; text: qsTr("-"); color: Constants.textPrimary; font.pixelSize: 13; font.bold: true }
                    }

                    // Full width row (spans 2 columns)
                    RowLayout {
                        Layout.fillWidth: true
                        //Layout.columnSpan: 2
                        Text { text: qsTr("Cycles"); color: Constants.textMuted; font.pixelSize: 13 }
                        Item { Layout.fillWidth: true }
                        Text { id: cyclesValueText; text: qsTr("-"); color: Constants.textPrimary; font.pixelSize: 13; font.bold: true }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        // ==================================
        // 3) CONTROLLER (two columns)
        //   Left column: Clamp first, then current temp + status + preheat
        //   Right column: Jog buttons stacked, z value next to them
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

                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 3
                    columnSpacing: 12
                    rowSpacing: 12

                    // -----------------------------
                    // LEFT COLUMN: Temp block
                    // -----------------------------
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 12

                        // Temp block
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 14
                            color: Constants.bgSurface
                            border.color: Constants.borderDefault
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: qsTr("Current Temp")
                                        color: Constants.textSecondary
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        id: tempStatusText
                                        text: qsTr("PREHEAT")
                                        color: Constants.textMuted
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                }

                                Text {
                                    id: currentTempText
                                    text: qsTr("-- °C")
                                    color: Constants.textPrimary
                                    font.pixelSize: 36
                                    font.bold: true
                                }

                                Item { Layout.fillHeight: true }

                                Button {
                                    id: preheatButton
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 44
                                    text: qsTr("Preheat")

                                    enabled: root.protocolSelected
                                    opacity: root.lockedOpacity()

                                    background: Rectangle {
                                        radius: 12
                                        color: parent.enabled
                                               ? (parent.pressed ? Constants.accentSky : Constants.accentPrimary)
                                               : Constants.bgPrimary
                                    }
                                    contentItem: Text {
                                        text: qsTr("Preheat")
                                        color: "white"
                                        font.pixelSize: 15
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }
                        }
                    }

                    // -----------------------------
                    // MIDDLE COLUMN: Jog stacked + Z value 
                    // -----------------------------
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 12

                        Text {
                            text: qsTr("Jog (Z)")
                            color: Constants.textSecondary
                            font.pixelSize: 13
                            font.bold: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 14

                            // Jog buttons stacked
                            ColumnLayout {
                                Layout.preferredWidth: 220
                                Layout.fillHeight: true
                                spacing: 12

                                Button {
                                    id: jogUpButton
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 110
                                    text: qsTr("▲  UP")

                                    enabled: root.protocolSelected
                                    opacity: root.lockedOpacity()

                                    background: Rectangle {
                                        radius: 14
                                        color: parent.enabled
                                               ? (parent.pressed ? Constants.accentSky : Constants.bgSurface)
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
                                    Layout.preferredHeight: 110
                                    text: qsTr("▼  DOWN")

                                    enabled: root.protocolSelected
                                    opacity: root.lockedOpacity()

                                    background: Rectangle {
                                        radius: 14
                                        color: parent.enabled
                                               ? (parent.pressed ? Constants.accentSky : Constants.bgSurface)
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
                            }
                        }
                    }

                    // -----------------------------
                    // RIGHT COLUMN: Clamp toggle
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
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
                            Layout.preferredHeight: 120
                            text: qsTr("OPEN CLAMP")

                            enabled: root.protocolSelected
                            opacity: root.lockedOpacity()

                            background: Rectangle {
                                radius: 14
                                color: parent.enabled
                                       ? (parent.pressed ? Constants.accentSky : Constants.bgSurface)
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

        // ==================================
        // 4) RUN TEST (locked until protocol chosen)
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
