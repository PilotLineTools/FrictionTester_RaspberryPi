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

    // Start-position telemetry + fixed-start gating (set by ConfigScreen.qml)
    property real currentPositionMm: 0.0
    property bool fixedStartEnabled: false
    property real fixedStartMm: 0.0
    property bool atFixedStart: true

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
    property alias currentTempText: currentTempText
    property alias tempStatusText: tempStatusText
    property alias preheatButton: preheatButton

    property alias jogUpButton: jogUpButton
    property alias jogDownButton: jogDownButton
    property alias zPositionField: zPositionField

    property alias runTestButton: runTestButton

    // Optional message area hooks (wrapper can set visible/text)
    property alias messageBanner: messageBanner
    property alias messageText: messageText

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
        // 2) PROTOCOL SUMMARY
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
                        Text { text: qsTr("Stroke"); color: Constants.textMuted; font.pixelSize: 13 }
                        Item { Layout.fillWidth: true }
                        Text { id: strokeValueText; text: qsTr("-"); color: Constants.textPrimary; font.pixelSize: 13; font.bold: true }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: parent.width / 2 - 11
                        Text { text: qsTr("Clamp Force"); color: Constants.textMuted; font.pixelSize: 13 }
                        Item { Layout.fillWidth: true }
                        Text { id: clampForceValueText; text: qsTr("-"); color: Constants.textPrimary; font.pixelSize: 13; font.bold: true }
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
        // 3) MACHINE CONTROLLER
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
                            spacing: 10

                            Text {
                                text: qsTr("Temperature")
                                color: Constants.textSecondary
                                font.pixelSize: 13
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                            }

                            Item { Layout.fillHeight: true }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 28

                                ColumnLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 6

                                    Text {
                                        text: qsTr("Current Temp.")
                                        color: Constants.textSecondary
                                        font.pixelSize: 13
                                        font.bold: true
                                        Layout.alignment: Qt.AlignHCenter
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    Text {
                                        id: currentTempText
                                        text: qsTr("-- °C")
                                        color: Constants.textPrimary
                                        font.pixelSize: 36
                                        font.bold: true
                                        Layout.alignment: Qt.AlignHCenter
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }

                                ColumnLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 6

                                    Text {
                                        text: qsTr("Test Target Temp.")
                                        color: Constants.textSecondary
                                        font.pixelSize: 13
                                        font.bold: true
                                        Layout.alignment: Qt.AlignHCenter
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    Text {
                                        id: tempStatusText
                                        text: root.protocolSelected ? (waterTempValueText.text + " °C") : qsTr("-- °C")
                                        color: Constants.textPrimary
                                        font.pixelSize: 36
                                        font.bold: true
                                        Layout.alignment: Qt.AlignHCenter
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }

                            Text {
                                text: root.protocolSelected ? qsTr("Preheating is recommended before running the test.") : ""
                                visible: root.protocolSelected
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignHCenter
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                color: Constants.textMuted
                                font.pixelSize: 12
                            }

                            Button {
                                id: preheatButton
                                Layout.preferredWidth: 260
                                Layout.preferredHeight: 100
                                Layout.alignment: Qt.AlignHCenter
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
                    // COL 2: START POSITION CARD (2 columns)
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
                                Layout.alignment: Qt.AlignHCenter
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 12

                                // LEFT: Jog controls
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: 1
                                    spacing: 12

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
                                        text: Number(root.currentPositionMm).toFixed(2)

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

                                // RIGHT: Status / Target / Guidance
                                Rectangle {
                                    id: startStatusCard
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: 1
                                    radius: 12
                                    color: Constants.bgPrimary
                                    border.color: Constants.borderDefault
                                    border.width: 1
                                    opacity: root.lockedOpacity()

                                    property bool hasTarget: root.fixedStartEnabled
                                    property real targetMm: Number(root.fixedStartMm || 0)
                                    property bool atTarget: root.atFixedStart

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 10

                                        Text {
                                            text: qsTr("Status")
                                            color: Constants.textSecondary
                                            font.pixelSize: 11
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 34
                                            radius: 10
                                            color: startStatusCard.hasTarget
                                                ? (startStatusCard.atTarget
                                                    ? Qt.rgba(0.16, 0.75, 0.35, 0.25)   // green-ish
                                                    : Qt.rgba(0.98, 0.70, 0.17, 0.25))  // amber-ish
                                                : Qt.rgba(0.56, 0.56, 0.56, 0.18)      // gray-ish
                                            border.color: Constants.borderDefault
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: !startStatusCard.hasTarget
                                                    ? qsTr("NO TARGET")
                                                    : (startStatusCard.atTarget ? qsTr("READY") : qsTr("NOT READY"))
                                                color: Constants.textPrimary
                                                font.pixelSize: 13
                                                font.bold: true
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 4

                                            Text {
                                                text: qsTr("Target Z")
                                                color: Constants.textSecondary
                                                font.pixelSize: 11
                                            }

                                            Text {
                                                text: startStatusCard.hasTarget
                                                    ? (Math.round(startStatusCard.targetMm * 100) / 100).toFixed(2) + qsTr(" mm")
                                                    : qsTr("—")
                                                color: Constants.accentSky
                                                font.pixelSize: 22
                                                font.bold: true
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            wrapMode: Text.WordWrap
                                            color: Constants.textMuted
                                            font.pixelSize: 12
                                            text: (!startStatusCard.hasTarget || startStatusCard.atTarget)
                                                ? qsTr("")
                                                : qsTr("Move to %1 mm to start.")
                                                    .arg((Math.round(startStatusCard.targetMm * 100) / 100).toFixed(2))
                                            visible: startStatusCard.hasTarget && !startStatusCard.atTarget
                                        }

                                        Item { Layout.fillHeight: true }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }

                    // COL 3: (Clamp card removed/commented in your original)
                }
            }
        }

        // ==================================
        // 4) MESSAGE BANNER (wrapper controls visible/text)
        // ==================================
        Rectangle {
            id: messageBanner
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            radius: 12
            color: "#FEF3C7"        // yellow-100
            border.color: "#F59E0B" // yellow-500
            border.width: 1
            visible: false

            Text {
                id: messageText
                anchors.fill: parent
                anchors.margins: 12
                text: qsTr("")
                color: "#92400E"     // yellow-800
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
        }

        // ==================================
        // 5) RUN TEST (locked until protocol chosen + (optional) fixed-start satisfied)
        // ==================================
        Button {
            id: runTestButton
            Layout.fillWidth: true
            Layout.preferredHeight: 72
            text: qsTr("▶  RUN TEST")

            enabled: root.protocolSelected && (!root.fixedStartEnabled || root.atFixedStart)
            opacity: enabled ? 1.0 : 0.4

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
