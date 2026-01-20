/*
  Qt Design Studio UI file (.ui.qml)
  Keep declarative. Put logic in ActiveRunScreen.qml.
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

    // ===== EXPOSE UI ELEMENTS (to wrapper) =====
    property alias protocolTitleText: protocolTitleText
    property alias statusBadgeText: statusBadgeText

    property alias speedValueText: speedValueText
    property alias clampValueText: clampValueText
    property alias strokeValueText: strokeValueText
    property alias tempValueText: tempValueText

    // show current/total cycles in the 5th card
    property alias cycleText: cycleText

    property alias elapsedText: elapsedText
    property alias pauseResumeButton: pauseResumeButton
    property alias abortButton: abortButton

    // Optional (if you wire a progress bar later)
    // property alias progressBar: progressBar

    readonly property int pad: 16
    readonly property int gap: 14

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: root.gap

        // =========================
        // TOP: Protocol Title + Status Badge
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
                        text: qsTr("Live Test")
                        color: Constants.textSecondary
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        id: protocolTitleText
                        text: qsTr("Protocol")
                        color: Constants.textPrimary
                        font.pixelSize: 24
                        font.bold: true
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                Item { Layout.fillWidth: true }

                // Status badge (RUNNING/PAUSED)
                Rectangle {
                    radius: 12
                    implicitWidth: 140
                    implicitHeight: 44
                    color: Constants.bgSurface
                    border.color: Constants.borderDefault
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Rectangle {
                            width: 10
                            height: 10
                            radius: 5
                            color: (statusBadgeText.text === "PAUSED") ? "#F59E0B" : "#22C55E"
                        }

                        Text {
                            id: statusBadgeText
                            text: qsTr("RUNNING")
                            color: Constants.textPrimary
                            font.pixelSize: 14
                            font.bold: true
                        }
                    }
                }
            }
        }

        // =========================
        // Metric cards row
        // =========================
        GridLayout {
            id: metricsGrid
            Layout.fillWidth: true
            columns: 5
            rowSpacing: root.gap
            columnSpacing: root.gap

            // This width is what we want the right-side control card to match.
            readonly property real metricW: (width - (columnSpacing * (columns - 1))) / columns

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
                    Text { id: speedValueText; text: qsTr("-"); color: Constants.accentSky; font.pixelSize: 26; font.bold: true }
                    Text { text: qsTr("cm/s"); color: Constants.textMuted; font.pixelSize: 11 }
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
                    Text { text: qsTr("Clamp"); color: Constants.textSecondary; font.pixelSize: 11 }
                    Text { id: clampValueText; text: qsTr("-"); color: "#FBBF24"; font.pixelSize: 26; font.bold: true }
                    Text { text: qsTr("g"); color: Constants.textMuted; font.pixelSize: 11 }
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
                    Text { text: qsTr("Stroke"); color: Constants.textSecondary; font.pixelSize: 11 }
                    Text { id: strokeValueText; text: qsTr("-"); color: Constants.textPrimary; font.pixelSize: 26; font.bold: true }
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
                    Text { text: qsTr("Temp"); color: Constants.textSecondary; font.pixelSize: 11 }
                    Text { id: tempValueText; text: qsTr("-"); color: "#60A5FA"; font.pixelSize: 26; font.bold: true }
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
                    Text { id: cycleText; text: qsTr("- / -"); color: "#A78BFA"; font.pixelSize: 26; font.bold: true }
                    Text { text: qsTr("current/total"); color: Constants.textMuted; font.pixelSize: 11 }
                }
            }
        }

        // =========================
        // MAIN: Graph (left) + Right Control Card (width matches 1 metric card)
        // =========================
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.gap

            // Graph panel (takes remaining space)
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
                    spacing: 10

                    Text {
                        text: qsTr("Force vs Position")
                        color: Constants.textPrimary
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 12
                        color: Constants.bgSurface
                        border.color: Constants.borderDefault
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: qsTr("LIVE GRAPH AREA")
                            color: Constants.textSecondary
                            font.pixelSize: 14
                        }
                    }
                }
            }

            // Right-side control card (aligned to far-right metric card)
            Rectangle {
                Layout.preferredWidth: metricsGrid.metricW
                Layout.fillHeight: true
                radius: 14
                color: Constants.bgCard
                border.color: Constants.borderDefault
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    // Elapsed time
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: qsTr("Elapsed Time")
                            color: Constants.textSecondary
                            font.pixelSize: 12
                        }

                        Text {
                            id: elapsedText
                            text: qsTr("00:00")
                            color: "#22C55E"
                            font.pixelSize: 34
                            font.bold: true
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Pause / Resume
                    Button {
                        id: pauseResumeButton
                        Layout.fillWidth: true
                        Layout.preferredHeight: 84
                        text: qsTr("⏸  PAUSE TEST")

                        // wrapper will override this
                        property color backgroundColor: "#F59E0B"

                        background: Rectangle {
                            radius: 16
                            color: pauseResumeButton.pressed
                                   ? Qt.darker(pauseResumeButton.backgroundColor, 1.15)
                                   : pauseResumeButton.backgroundColor
                        }

                        contentItem: Text {
                            text: pauseResumeButton.text
                            color: "white"
                            font.pixelSize: 20
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    // Abort
                    Button {
                        id: abortButton
                        Layout.fillWidth: true
                        Layout.preferredHeight: 84
                        text: qsTr("⨯  ABORT TEST")

                        background: Rectangle {
                            radius: 16
                            color: abortButton.pressed ? "#B91C1C" : "#DC2626"
                        }

                        contentItem: Text {
                            text: abortButton.text
                            color: "white"
                            font.pixelSize: 20
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
