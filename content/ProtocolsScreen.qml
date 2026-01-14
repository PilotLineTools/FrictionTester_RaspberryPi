/*
  Qt Design Studio UI file (.ui.qml)
  Layout + styling only. Put logic in ProtocolsScreen.qml.
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

    // Data from ProtocolsScreen.qml
    property var protocolsModel: null
    property var editedProtocol: null

    // Access parent functions safely (ProtocolsScreen.qml is the parent)
    function callParent(fnName, arg) {
        if (!parent || typeof parent[fnName] !== "function") return
        if (arg === undefined) parent[fnName]()
        else parent[fnName](arg)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        // Header (like screenshot)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: qsTr("Protocols")
                color: Constants.textPrimary
                font.pixelSize: 26
                font.bold: true
            }

            Text {
                text: qsTr("Configure & manage test recipes")
                color: Constants.textSecondary
                font.pixelSize: 13
            }
        }

        // Banner (like screenshot)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            radius: 10
            color: Qt.rgba(0.96, 0.62, 0.13, 0.10)      // amber tint
            border.color: Qt.rgba(0.96, 0.62, 0.13, 0.35)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Rectangle {
                    width: 18; height: 18; radius: 9
                    color: Qt.rgba(0.96, 0.62, 0.13, 0.9)
                    Text { anchors.centerIn: parent; text: "!"; color: "black"; font.pixelSize: 12; font.bold: true }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: qsTr("Editing Mode")
                        color: Qt.rgba(0.96, 0.62, 0.13, 0.95)
                        font.pixelSize: 12
                        font.bold: true
                    }
                    Text {
                        text: qsTr("Changes affect saved recipes. Confirm before running.")
                        color: Constants.textSecondary
                        font.pixelSize: 11
                    }
                }
            }
        }

        // 2x2 Card Grid
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            columnSpacing: 16
            rowSpacing: 16

            // --- Card: Protocol List ---
            Card {
                id: listCard
                Layout.fillWidth: true
                Layout.fillHeight: true
                title: qsTr("Protocol Library")
                subtitle: qsTr("Select a recipe to edit")

                content: Item {
                    anchors.fill: parent

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            TextField {
                                id: searchInput
                                Layout.fillWidth: true
                                placeholderText: qsTr("Search protocols…")
                                color: Constants.textPrimary
                                background: Rectangle {
                                    color: Constants.bgSurface
                                    radius: 10
                                    border.color: Constants.borderDefault
                                    border.width: 1
                                }
                            }

                            Button {
                                Layout.preferredWidth: 44
                                Layout.preferredHeight: 40
                                text: "+"
                                font.pixelSize: 20
                                font.bold: true
                                background: Rectangle {
                                    radius: 10
                                    color: parent.pressed ? Constants.accentSky : Constants.accentPrimary
                                }
                                onClicked: root.callParent("duplicateProtocol") // quick add-copy; replace with “newProtocol”
                            }
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            ListView {
                                id: protocolsList
                                width: parent.width
                                height: parent.height
                                spacing: 10
                                model: root.protocolsModel
                                currentIndex: 0

                                delegate: Rectangle {
                                    width: protocolsList.width
                                    height: 78
                                    radius: 12
                                    color: ListView.isCurrentItem ? Qt.rgba(0.36, 0.84, 0.95, 0.18) : Constants.bgSurface
                                    border.color: ListView.isCurrentItem ? Constants.accentSky : Constants.borderDefault
                                    border.width: 1

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            protocolsList.currentIndex = index
                                            root.callParent("selectProtocol", index)
                                        }
                                    }

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 4

                                        Text {
                                            text: model.name
                                            color: Constants.textPrimary
                                            font.pixelSize: 15
                                            font.bold: true
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            text: qsTr("%1 cycles • %2°C • %3 cm/s")
                                                .arg(model.cycles).arg(model.waterTemp).arg(model.speed.toFixed(1))
                                            color: Constants.textSecondary
                                            font.pixelSize: 11
                                        }
                                        Text {
                                            text: model.lastModified
                                            color: Constants.textMuted
                                            font.pixelSize: 10
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // --- Card: Parameters (big readout + sliders) ---
            Card {
                id: paramsCard
                Layout.fillWidth: true
                Layout.fillHeight: true
                title: qsTr("Protocol Parameters")
                subtitle: qsTr("Edit recipe fields")

                content: Item {
                    anchors.fill: parent

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 14

                        // Big Readout (like screenshot)
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 86
                            radius: 12
                            color: Constants.bgSurface
                            border.color: Constants.borderDefault
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 4

                                Text {
                                    text: qsTr("Selected Protocol")
                                    color: Constants.textSecondary
                                    font.pixelSize: 11
                                }

                                Text {
                                    text: root.editedProtocol ? root.editedProtocol.name : qsTr("None")
                                    color: Constants.accentSky
                                    font.pixelSize: 26
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        // Name field
                        LabeledField {
                            label: qsTr("Name")
                            placeholder: qsTr("Protocol name")
                            textValue: root.editedProtocol ? root.editedProtocol.name : ""
                            onTextEdited: (t) => root.callParent("updateField", ["name", t])
                        }

                        // Sliders
                        LabeledSlider {
                            label: qsTr("Speed (cm/s)")
                            min: 0.1
                            max: 2.5
                            step: 0.1
                            value: root.editedProtocol ? root.editedProtocol.speed : 0
                            valueText: root.editedProtocol ? root.editedProtocol.speed.toFixed(1) : "0.0"
                            onValueEdited: (v) => root.callParent("updateField", ["speed", v])
                        }

                        LabeledSlider {
                            label: qsTr("Stroke Length (mm)")
                            min: 10
                            max: 150
                            step: 1
                            value: root.editedProtocol ? root.editedProtocol.strokeLength : 0
                            valueText: root.editedProtocol ? root.editedProtocol.strokeLength.toFixed(0) : "0"
                            onValueEdited: (v) => root.callParent("updateField", ["strokeLength", Math.round(v)])
                        }

                        LabeledSlider {
                            label: qsTr("Clamp Force (g)")
                            min: 50
                            max: 500
                            step: 10
                            value: root.editedProtocol ? root.editedProtocol.clampForce : 0
                            valueText: root.editedProtocol ? root.editedProtocol.clampForce.toFixed(0) : "0"
                            onValueEdited: (v) => root.callParent("updateField", ["clampForce", Math.round(v/10)*10])
                        }

                        LabeledSlider {
                            label: qsTr("Water Temp (°C)")
                            min: 15
                            max: 50
                            step: 1
                            value: root.editedProtocol ? root.editedProtocol.waterTemp : 0
                            valueText: root.editedProtocol ? root.editedProtocol.waterTemp.toFixed(0) : "0"
                            onValueEdited: (v) => root.callParent("updateField", ["waterTemp", Math.round(v)])
                        }

                        LabeledSlider {
                            label: qsTr("Cycles")
                            min: 1
                            max: 2000
                            step: 10
                            value: root.editedProtocol ? root.editedProtocol.cycles : 0
                            valueText: root.editedProtocol ? root.editedProtocol.cycles.toFixed(0) : "0"
                            onValueEdited: (v) => root.callParent("updateField", ["cycles", Math.round(v/10)*10])
                        }
                    }
                }
            }

            // --- Card: Summary / Estimates ---
            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                title: qsTr("Summary")
                subtitle: qsTr("Estimated run stats")

                content: Item {
                    anchors.fill: parent

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 14

                        SummaryTile {
                            label: qsTr("Estimated Duration")
                            value: parent && root.parent ? (root.parent.estimateDurationMin() + " min") : "0 min"
                            accent: Constants.accentSky
                        }

                        SummaryTile {
                            label: qsTr("Clamp Setpoint")
                            value: root.editedProtocol ? (root.editedProtocol.clampForce + " g") : "0 g"
                            accent: "#FBBF24"
                        }

                        SummaryTile {
                            label: qsTr("Water Setpoint")
                            value: root.editedProtocol ? (root.editedProtocol.waterTemp + " °C") : "0 °C"
                            accent: "#60A5FA"
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 56
                            radius: 12
                            color: Qt.rgba(0.36, 0.84, 0.95, 0.12)
                            border.color: Qt.rgba(0.36, 0.84, 0.95, 0.35)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10
                                Text {
                                    text: qsTr("Last Modified")
                                    color: Constants.textSecondary
                                    font.pixelSize: 12
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: root.editedProtocol ? root.editedProtocol.lastModified : "-"
                                    color: Constants.textPrimary
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }
                        }
                    }
                }
            }

            // --- Card: Actions ---
            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                title: qsTr("Actions")
                subtitle: qsTr("Save, duplicate, delete")

                content: Item {
                    anchors.fill: parent

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        Button {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 54
                            text: qsTr("SAVE PROTOCOL")
                            font.pixelSize: 14
                            font.bold: true
                            background: Rectangle {
                                radius: 12
                                color: parent.pressed ? Constants.accentPrimary : Constants.accentSky
                            }
                            onClicked: root.callParent("saveProtocol")
                        }

                        Button {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 54
                            text: qsTr("DUPLICATE")
                            font.pixelSize: 14
                            font.bold: true
                            background: Rectangle {
                                radius: 12
                                color: parent.pressed ? "#4B5563" : "#6B7280"
                            }
                            onClicked: root.callParent("duplicateProtocol")
                        }

                        Button {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 54
                            text: qsTr("DELETE")
                            font.pixelSize: 14
                            font.bold: true
                            background: Rectangle {
                                radius: 12
                                color: parent.pressed ? Qt.rgba(0.87, 0.13, 0.13, 0.45) : Qt.rgba(0.87, 0.13, 0.13, 0.30)
                                border.color: "#DC2626"
                                border.width: 1
                            }
                            onClicked: root.callParent("deleteProtocol")
                        }

                        Item { Layout.fillHeight: true }

                        Button {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 62
                            text: qsTr("▶ RUN PROTOCOL")
                            font.pixelSize: 16
                            font.bold: true
                            background: Rectangle {
                                radius: 12
                                color: parent.pressed ? "#059669" : "#10B981"
                            }
                            onClicked: root.callParent("runProtocol")
                        }
                    }
                }
            }
        }
    }

    // ----------------
    // Reusable building blocks (declarative only)
    // ----------------

    component Card: Rectangle {
        property string title: ""
        property string subtitle: ""
        property Item content

        radius: 14
        color: Constants.bgCard
        border.color: Constants.borderDefault
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Card header
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                radius: 14
                color: Qt.rgba(0, 0, 0, 0) // transparent
                border.width: 0

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 2

                    Text { text: title; color: Constants.textPrimary; font.pixelSize: 14; font.bold: true }
                    Text { text: subtitle; color: Constants.textMuted; font.pixelSize: 11 }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Constants.borderDefault
                opacity: 0.6
            }

            // Body
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Loader {
                    anchors.fill: parent
                    sourceComponent: content
                }
            }
        }
    }

    component SummaryTile: Rectangle {
        property string label: ""
        property string value: ""
        property color accent: Constants.accentSky

        Layout.fillWidth: true
        Layout.preferredHeight: 72
        radius: 12
        color: Constants.bgSurface
        border.color: Constants.borderDefault
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Text { text: label; color: Constants.textSecondary; font.pixelSize: 11 }
                Text { text: value; color: accent; font.pixelSize: 22; font.bold: true }
            }
        }
    }

    component LabeledField: Item {
        property string label: ""
        property string placeholder: ""
        property string textValue: ""
        signal textEdited(string t)   // safe name (not *Changed)

        Layout.fillWidth: true
        height: 64

        ColumnLayout {
            anchors.fill: parent
            spacing: 6

            Text { text: label; color: Constants.textSecondary; font.pixelSize: 11 }

            TextField {
                Layout.fillWidth: true
                text: textValue
                placeholderText: placeholder
                color: Constants.textPrimary
                background: Rectangle {
                    color: Constants.bgSurface
                    radius: 12
                    border.color: Constants.borderDefault
                    border.width: 1
                }
                onTextChanged: textEdited(text)
            }
        }
    }

    component LabeledSlider: Item {
        property string label: ""
        property real min: 0
        property real max: 100
        property real step: 1
        property real value: 0
        property string valueText: ""
        signal valueEdited(real v)    // safe name (not *Changed)

        Layout.fillWidth: true
        height: 74

        ColumnLayout {
            anchors.fill: parent
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Text { text: label; color: Constants.textSecondary; font.pixelSize: 11; Layout.fillWidth: true }
                Text { text: valueText; color: Constants.textPrimary; font.pixelSize: 11; font.bold: true }
            }

            Slider {
                Layout.fillWidth: true
                from: min
                to: max
                stepSize: step
                value: value
                onValueChanged: valueEdited(value)
            }
        }
    }
}
