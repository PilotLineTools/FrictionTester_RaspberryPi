import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PilotLine_FrictionTester

Rectangle {
    id: root
    width: Constants.width
    height: Constants.height
    color: Constants.bgPrimary

    readonly property int pad: 16
    readonly property int gap: 12
    readonly property int rowH: 56
    readonly property int radius: 14

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: root.gap

        // =========================
        // Header (Sketch B vibe)
        // =========================
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            spacing: 12

            ColumnLayout {
                spacing: 2
                Text {
                    text: qsTr("Settings")
                    color: Constants.textPrimary
                    font.pixelSize: 26
                    font.bold: true
                }
                Text {
                    text: qsTr("System & preferences")
                    color: Constants.textSecondary
                    font.pixelSize: 12
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                radius: 999
                color: Constants.bgSurface
                border.color: Constants.borderDefault
                border.width: 1
                implicitHeight: 36
                implicitWidth: 140

                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Rectangle { width: 10; height: 10; radius: 5; color: "#22C55E" }
                    Text {
                        text: qsTr("CONNECTED")
                        color: Constants.textPrimary
                        font.pixelSize: 12
                        font.bold: true
                    }
                }
            }
        }

        // =========================
        // Scroll content
        // =========================
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.availableWidth
                spacing: root.gap

                SettingsSectionCard {
                    title: qsTr("Operator")

                    SettingsRowButton {
                        title: qsTr("Profile")
                        subtitle: qsTr("Name, role, permissions")
                        rightText: qsTr("Mario")
                        onClicked: console.log("Profile")
                    }

                    SettingsRowButton {
                        title: qsTr("Engineer Mode")
                        subtitle: qsTr("Requires engineer code")
                        rightText: qsTr("Locked")
                        onClicked: console.log("Engineer Mode")
                    }
                }

                SettingsSectionCard {
                    title: qsTr("Display")

                    SettingsRowToggle {
                        title: qsTr("Dark Mode")
                        subtitle: qsTr("Reduce glare in low light")
                        checked: true
                        onToggled: (v) => console.log("Dark Mode:", v)
                    }

                    SettingsRowToggle {
                        title: qsTr("Large Text")
                        subtitle: qsTr("Improve readability")
                        checked: false
                        onToggled: (v) => console.log("Large Text:", v)
                    }
                }

                SettingsSectionCard {
                    title: qsTr("Machine")

                    SettingsRowButton {
                        title: qsTr("Calibration")
                        subtitle: qsTr("Clamp, axis, sensors")
                        onClicked: console.log("Calibration")
                    }

                    SettingsRowButton {
                        title: qsTr("I/O & Ports")
                        subtitle: qsTr("Serial, peripherals, USB")
                        onClicked: console.log("IO & Ports")
                    }

                    SettingsRowButton {
                        title: qsTr("Data & Export")
                        subtitle: qsTr("CSV export, storage")
                        onClicked: console.log("Data & Export")
                    }
                }

                SettingsSectionCard {
                    title: qsTr("System")

                    SettingsRowButton {
                        title: qsTr("Network")
                        subtitle: qsTr("Wi-Fi, IP address")
                        rightText: qsTr("Wi-Fi")
                        onClicked: console.log("Network")
                    }

                    SettingsRowButton {
                        title: qsTr("About")
                        subtitle: qsTr("Version, device info")
                        rightText: qsTr("v1.0.0")
                        onClicked: console.log("About")
                    }
                }

                Item { Layout.preferredHeight: 8 }
            }
        }
    }

    // =========================================================
    // Building blocks
    // =========================================================

    component SettingsSectionCard: Rectangle {
        id: sectionCard
        default property alias content: body.data
        property string title: ""

        Layout.fillWidth: true
        radius: root.radius
        color: Constants.bgCard
        border.color: Constants.borderDefault
        border.width: 1

        ColumnLayout {
            id: body
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Text {
                text: sectionCard.title
                color: Constants.textSecondary
                font.pixelSize: 12
                font.bold: true
            }
        }
    }

    component SettingsRowButton: Rectangle {
        id: rowBtn
        signal clicked()

        property string title: ""
        property string subtitle: ""
        property string rightText: ""

        Layout.fillWidth: true
        Layout.preferredHeight: root.rowH
        radius: 12
        color: Constants.bgSurface
        border.color: Constants.borderDefault
        border.width: 1

        MouseArea {
            anchors.fill: parent
            onClicked: rowBtn.clicked()
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true

                Text {
                    text: rowBtn.title
                    color: Constants.textPrimary
                    font.pixelSize: 15
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    visible: rowBtn.subtitle.length > 0
                    text: rowBtn.subtitle
                    color: Constants.textMuted
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }

            Text {
                visible: rowBtn.rightText.length > 0
                text: rowBtn.rightText
                color: Constants.textSecondary
                font.pixelSize: 13
                font.bold: true
            }

            Text {
                text: "›"
                color: Constants.textMuted
                font.pixelSize: 22
            }
        }
    }

    component SettingsRowToggle: Rectangle {
        id: rowTog
        property string title: ""
        property string subtitle: ""
        property bool checked: false
        signal toggled(bool checked)

        Layout.fillWidth: true
        Layout.preferredHeight: root.rowH
        radius: 12
        color: Constants.bgSurface
        border.color: Constants.borderDefault
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true

                Text {
                    text: rowTog.title
                    color: Constants.textPrimary
                    font.pixelSize: 15
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    visible: rowTog.subtitle.length > 0
                    text: rowTog.subtitle
                    color: Constants.textMuted
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }

            Switch {
                checked: rowTog.checked
                onToggled: {
                    rowTog.checked = checked
                    rowTog.toggled(checked)
                }
            }
        }
    }
}
