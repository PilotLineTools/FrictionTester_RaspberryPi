/*
  Qt Design Studio UI file (.ui.qml)
  Keep this declarative (layout + styling). Put logic in ProtocolsScreen.qml.
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

    // Access parent ProtocolsScreen properties
    property var protocolsModel: parent ? parent.protocolsModel : null
    property var editedProtocol: parent ? parent.editedProtocol : null

    // Expose UI elements for access from ProtocolsScreen.qml
    property alias protocolsListView: protocolsListView
    property alias protocolNameInput: protocolNameInput
    property alias speedSlider: speedSlider
    property alias strokeLengthSlider: strokeLengthSlider
    property alias clampForceSlider: clampForceSlider
    property alias waterTempSlider: waterTempSlider
    property alias cyclesSlider: cyclesSlider
    property alias runButton: runButton
    property alias saveButton: saveButton
    property alias duplicateButton: duplicateButton
    property alias deleteButton: deleteButton
    property alias addButton: addButton

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Protocol List Sidebar
        Rectangle {
            id: protocolListSidebar
            Layout.preferredWidth: 320
            Layout.fillHeight: true
            color: Constants.bgCard
            border.color: Constants.borderDefault
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 24

                // Header with title and add button
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: qsTr("Protocols")
                        color: Constants.textPrimary
                        font.pixelSize: 22
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    Button {
                        id: addButton
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        text: "+"
                        font.pixelSize: 24
                        font.bold: true
                        background: Rectangle {
                            color: parent.pressed ? Constants.accentSky : Constants.accentPrimary
                            radius: 8
                        }
                    }
                }

                // Protocol list
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ListView {
                        id: protocolsListView
                        model: root.protocolsModel
                        spacing: 8
                        currentIndex: 0

                        delegate: Rectangle {
                            width: protocolsListView.width
                            height: 100
                            color: ListView.isCurrentItem ? 
                                   Qt.rgba(0.36, 0.84, 0.95, 0.4) : Constants.bgSurface
                            border.color: ListView.isCurrentItem ? 
                                         Constants.accentSky : Constants.borderDefault
                            border.width: 1
                            radius: 8

                                MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    protocolsListView.currentIndex = index
                                    if (root.parent) {
                                        root.parent.selectProtocol(index)
                                    }
                                }
                            }

                            Column {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 16
                                spacing: 4

                                Text {
                                    text: model.name
                                    color: Constants.textPrimary
                                    font.pixelSize: 16
                                    font.bold: true
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                Text {
                                    text: qsTr("%1 cycles • %2°C").arg(model.cycles).arg(model.waterTemp)
                                    color: Constants.textSecondary
                                    font.pixelSize: 12
                                }
                                Text {
                                    text: model.lastModified
                                    color: Constants.textMuted
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }
                }
            }
        }

        // Protocol Editor Area
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: Math.max(root.width - protocolListSidebar.width, 600)
                spacing: 24
                anchors.margins: 32

                // Title section
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        id: protocolTitle
                        text: root.editedProtocol ? root.editedProtocol.name : qsTr("No Protocol Selected")
                        color: Constants.textPrimary
                        font.pixelSize: 32
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: qsTr("Configure test parameters")
                        color: Constants.textSecondary
                        font.pixelSize: 16
                        Layout.fillWidth: true
                    }
                }

                // Protocol Name Input
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    color: Constants.bgCard
                    border.color: Constants.borderDefault
                    border.width: 1
                    radius: 12

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 8

                        Text {
                            text: qsTr("Protocol Name")
                            color: Constants.textSecondary
                            font.pixelSize: 14
                        }
                        TextField {
                            id: protocolNameInput
                            Layout.fillWidth: true
                            text: root.editedProtocol ? root.editedProtocol.name : ""
                            color: Constants.textPrimary
                            font.pixelSize: 18
                            background: Rectangle {
                                color: Constants.bgSurface
                                border.color: Constants.borderDefault
                                border.width: 1
                                radius: 8
                            }
                            onTextChanged: {
                                if (root.editedProtocol && root.parent) {
                                    root.parent.updateField("name", text)
                                }
                            }
                        }
                    }
                }

                // Test Parameters Grid
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 24
                    columnSpacing: 24

                    // Speed
                    ParameterCard {
                        id: speedCard
                        Layout.fillWidth: true
                        title: qsTr("Test Speed")
                        value: root.editedProtocol ? root.editedProtocol.speed.toFixed(1) : "0.0"
                        unit: qsTr("cm/s")
                        valueColor: Constants.accentSky
                        slider: speedSlider
                        minValue: 0.1
                        maxValue: 2.5
                        step: 0.1
                        sliderValue: root.editedProtocol ? root.editedProtocol.speed * 10 : 15
                        onSliderValueChanged: {
                            if (root.editedProtocol && root.parent) {
                                root.parent.updateField("speed", value / 10)
                            }
                        }
                    }

                    // Stroke Length
                    ParameterCard {
                        id: strokeCard
                        Layout.fillWidth: true
                        title: qsTr("Stroke Length")
                        value: root.editedProtocol ? root.editedProtocol.strokeLength : 0
                        unit: qsTr("mm")
                        valueColor: "#4ADE80" // green-400
                        slider: strokeLengthSlider
                        minValue: 10
                        maxValue: 150
                        step: 1
                        sliderValue: root.editedProtocol ? root.editedProtocol.strokeLength : 80
                        onSliderValueChanged: {
                            if (root.editedProtocol && root.parent) {
                                root.parent.updateField("strokeLength", value)
                            }
                        }
                    }

                    // Clamp Force
                    ParameterCard {
                        id: clampCard
                        Layout.fillWidth: true
                        title: qsTr("Clamp Force")
                        value: root.editedProtocol ? root.editedProtocol.clampForce : 0
                        unit: qsTr("g")
                        valueColor: "#FBBF24" // amber-400
                        slider: clampForceSlider
                        minValue: 50
                        maxValue: 500
                        step: 10
                        sliderValue: root.editedProtocol ? root.editedProtocol.clampForce : 250
                        onSliderValueChanged: {
                            if (root.editedProtocol && root.parent) {
                                root.parent.updateField("clampForce", value)
                            }
                        }
                    }

                    // Water Temperature
                    ParameterCard {
                        id: tempCard
                        Layout.fillWidth: true
                        title: qsTr("Water Temperature")
                        value: root.editedProtocol ? root.editedProtocol.waterTemp : 0
                        unit: qsTr("°C")
                        valueColor: "#60A5FA" // blue-400
                        slider: waterTempSlider
                        minValue: 15
                        maxValue: 50
                        step: 1
                        sliderValue: root.editedProtocol ? root.editedProtocol.waterTemp : 37
                        onSliderValueChanged: {
                            if (root.editedProtocol && root.parent) {
                                root.parent.updateField("waterTemp", value)
                            }
                        }
                    }
                }

                // Number of Cycles
                ParameterCard {
                    id: cyclesCard
                    Layout.fillWidth: true
                    title: qsTr("Number of Cycles")
                    value: root.editedProtocol ? root.editedProtocol.cycles : 0
                    unit: qsTr("cycles")
                    valueColor: "#A78BFA" // purple-400
                    slider: cyclesSlider
                    minValue: 1
                    maxValue: 2000
                    step: 10
                    sliderValue: root.editedProtocol ? root.editedProtocol.cycles : 100
                    onSliderValueChanged: {
                        if (root.editedProtocol && root.parent) {
                            root.parent.updateField("cycles", value)
                        }
                    }
                }

                // Estimated Duration Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 100
                    color: Qt.rgba(0.36, 0.84, 0.95, 0.2) // cyan-900/20
                    border.color: Qt.rgba(0.36, 0.84, 0.95, 0.5) // cyan-700/50
                    border.width: 1
                    radius: 12

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 24

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: qsTr("Estimated Duration")
                                color: Constants.accentSky
                                font.pixelSize: 14
                            }
                            Text {
                                text: root.parent ? qsTr("%1 min").arg(root.parent.calculateDuration()) : "0 min"
                                color: Constants.accentSky
                                font.pixelSize: 24
                                font.bold: true
                            }
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignRight
                            spacing: 4

                            Text {
                                text: qsTr("Total Distance")
                                color: Constants.textSecondary
                                font.pixelSize: 14
                            }
                            Text {
                                text: root.parent ? qsTr("%1 m").arg(root.parent.calculateDistance()) : "0 m"
                                color: Constants.textPrimary
                                font.pixelSize: 20
                                font.bold: true
                            }
                        }
                    }
                }

                // Action Buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Button {
                        id: runButton
                        Layout.fillWidth: true
                        Layout.preferredHeight: 64
                        text: qsTr("▶ RUN PROTOCOL")
                        font.pixelSize: 18
                        font.bold: true
                        background: Rectangle {
                            color: parent.pressed ? "#059669" : "#10B981" // green-600/700
                            radius: 8
                        }
                        onClicked: {
                            if (root.parent) {
                                root.parent.runProtocol()
                            }
                        }
                    }

                    Button {
                        id: saveButton
                        Layout.preferredWidth: 120
                        Layout.preferredHeight: 64
                        text: qsTr("SAVE")
                        font.pixelSize: 16
                        font.bold: true
                        background: Rectangle {
                            color: parent.pressed ? Constants.accentPrimary : Constants.accentSky
                            radius: 8
                        }
                    }

                    Button {
                        id: duplicateButton
                        Layout.preferredWidth: 140
                        Layout.preferredHeight: 64
                        text: qsTr("DUPLICATE")
                        font.pixelSize: 16
                        font.bold: true
                        background: Rectangle {
                            color: parent.pressed ? "#4B5563" : "#6B7280" // gray-600/700
                            radius: 8
                        }
                    }

                    Button {
                        id: deleteButton
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 64
                        text: "🗑"
                        font.pixelSize: 20
                        background: Rectangle {
                            color: parent.pressed ? Qt.rgba(0.87, 0.13, 0.13, 0.5) : Qt.rgba(0.87, 0.13, 0.13, 0.3)
                            border.color: "#DC2626" // red-700
                            border.width: 1
                            radius: 8
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }
    }

    // Reusable Parameter Card Component
    component ParameterCard: Rectangle {
        property alias slider: paramSlider
        property string title: ""
        property string value: "0"
        property string unit: ""
        property color valueColor: Constants.textPrimary
        property real minValue: 0
        property real maxValue: 100
        property real step: 1
        property real sliderValue: 0
        signal sliderValueEdited(real value)


        Layout.fillWidth: true
        Layout.preferredHeight: 140
        color: Constants.bgCard
        border.color: Constants.borderDefault
        border.width: 1
        radius: 12

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 12

            Text {
                text: title
                color: Constants.textSecondary
                font.pixelSize: 14
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: value
                    color: valueColor
                    font.pixelSize: 36
                    font.bold: true
                }
                Text {
                    text: unit
                    color: Constants.textSecondary
                    font.pixelSize: 16
                }
            }

            Slider {
                id: paramSlider
                Layout.fillWidth: true
                from: minValue
                to: maxValue
                stepSize: step
                value: sliderValue
                onValueChanged: sliderValueEdited(value)
            }
        }
    }

    // Slider components (referenced by ParameterCard)
    Slider {
        id: speedSlider
        visible: false
    }
    Slider {
        id: strokeLengthSlider
        visible: false
    }
    Slider {
        id: clampForceSlider
        visible: false
    }
    Slider {
        id: waterTempSlider
        visible: false
    }
    Slider {
        id: cyclesSlider
        visible: false
    }
}
