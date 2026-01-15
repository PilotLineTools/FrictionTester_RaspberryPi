/*
  Qt Design Studio UI file (.ui.qml)
  Keep declarative. Put logic in ProtocolsScreen.qml.
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

    property var protocolsModel: null
    property var editedProtocol: null
    property bool syncing: false


    function callParent(fnName, a, b) {
        if (!parent || typeof parent[fnName] !== "function") return
        if (a === undefined) parent[fnName]()
        else if (b === undefined) parent[fnName](a)
        else parent[fnName](a, b)
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // =========================
        // Left Sidebar (Protocols)
        // =========================
        Rectangle {
            id: sidebar
            Layout.preferredWidth: 270
            Layout.fillHeight: true
            color: Constants.bgCard
            border.color: Constants.borderDefault
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    // Header
                    Text {
                        text: qsTr("Protocols")
                        color: Constants.textPrimary
                        font.pixelSize: 18
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    // Add Protocol Button
                    Button {
                        id: addBtn
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        text: "+"
                        font.pixelSize: 20
                        font.bold: true
                        background: Rectangle {
                            radius: 10
                            color: parent.pressed ? Constants.accentSky : Constants.accentPrimary
                        }
                        onClicked: root.callParent("addProtocol") 
                    }
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ListView {
                        id: list
                        width: parent.width
                        height: parent.height
                        model: root.protocolsModel
                        spacing: 10
                        currentIndex: (root.parent && root.parent.selectedIndex !== undefined) ? root.parent.selectedIndex : 0


                        delegate: Rectangle {
                            width: list.width
                            height: 96
                            radius: 12
                            color: ListView.isCurrentItem ? Qt.rgba(0.36, 0.84, 0.95, 0.18) : Constants.bgSurface
                            border.color: ListView.isCurrentItem ? Constants.accentSky : Constants.borderDefault
                            border.width: 1

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    list.currentIndex = index
                                    root.callParent("selectProtocol", index)
                                }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 6

                                Text {
                                    text: model.name
                                    color: Constants.textPrimary
                                    font.pixelSize: 14
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: qsTr("%1 cycles • %2°C").arg(model.cycles).arg(model.waterTemp)
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

        // =========================
        // Right Editor Area
        // =========================
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            // vertical only
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds

            // ✅ prevent horizontal scroll and keep content aligned to viewport
            contentWidth: width
            contentHeight: editor.implicitHeight

            ColumnLayout {
                id: editor
                width: Math.min(parent.width, 760)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 18
                anchors.margins: 28

                // Title
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    content: Component {
                        Item {
                            anchors.fill: parent

                            TextField {
                                id: nameField2
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: 16
                                height: 44
                                color: Constants.textPrimary
                                font.pixelSize: 28
                                font.bold: true
                                Layout.fillWidth: true
                                background: Rectangle {
                                    color: Constants.bgSurface
                                    radius: 10
                                    border.color: Constants.borderDefault
                                    border.width: 1
                                }
                                Component.onCompleted: {
                                    root.syncing = true
                                    text = root.editedProtocol ? root.editedProtocol.name : ""
                                    root.syncing = false
                                }
                                Connections {
                                    target: root
                                    function onEditedProtocolChanged() {
                                        root.syncing = true
                                        nameField2.text = root.editedProtocol ? root.editedProtocol.name : ""
                                        root.syncing = false
                                    }
                                }
                                onTextEdited: {  
                                    if (root.syncing) return
                                    root.callParent("updateField", "name", text)
                                }
                                
                            }
                        }
                    }

                    Text {
                        text: root.editedProtocol ? root.editedProtocol.name : qsTr("No Protocol Selected")
                        color: Constants.textPrimary
                        font.pixelSize: 28
                        font.bold: true
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: qsTr("Configure test parameters")
                        color: Constants.textSecondary
                        font.pixelSize: 13
                        Layout.fillWidth: true
                    }
                }

                // Protocol Name card
                Card {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 92
                    title: qsTr("Protocol Name")

                    content: Component {
                        Item {
                            anchors.fill: parent

                            TextField {
                                id: nameField
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: 16
                                height: 44
                                color: Constants.textPrimary
                                background: Rectangle {
                                    color: Constants.bgSurface
                                    radius: 10
                                    border.color: Constants.borderDefault
                                    border.width: 1
                                }
                                Component.onCompleted: {
                                    root.syncing = true
                                    text = root.editedProtocol ? root.editedProtocol.name : ""
                                    root.syncing = false
                                }
                                Connections {
                                    target: root
                                    function onEditedProtocolChanged() {
                                        root.syncing = true
                                        nameField.text = root.editedProtocol ? root.editedProtocol.name : ""
                                        root.syncing = false
                                    }
                                }
                                onTextEdited: {  
                                    if (root.syncing) return
                                    root.callParent("updateField", "name", text)
                                }
                                
                            }
                        }
                    }

                }

                // 2x2 parameter grid
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 16
                    columnSpacing: 16

                    ParamCard {
                        title: qsTr("Test Speed")
                        valueText: root.editedProtocol ? root.editedProtocol.speed.toFixed(1) : "0.0"
                        unitText: qsTr("cm/s")
                        accent: Constants.accentSky
                        from: 0.1
                        to: 2.5
                        step: 0.1
                        sliderValue: root.editedProtocol ? root.editedProtocol.speed : 0
                        minLabel: qsTr("0.1 cm/s")
                        maxLabel: qsTr("2.5 cm/s")
                        onValueEdited: (v) => root.callParent("updateField", "speed", Math.round(v * 10) / 10)


                    }

                    ParamCard {
                        title: qsTr("Stroke Length")
                        valueText: root.editedProtocol ? String(root.editedProtocol.strokeLength) : "0"
                        unitText: qsTr("mm")
                        accent: "#4ADE80"
                        from: 10
                        to: 150
                        step: 1
                        sliderValue: root.editedProtocol ? root.editedProtocol.strokeLength : 0
                        minLabel: qsTr("10 mm")
                        maxLabel: qsTr("150 mm")
                        onValueEdited: (v) => root.callParent("updateField", "strokeLength", Math.round(v))
                    }

                    ParamCard {
                        title: qsTr("Clamp Force")
                        valueText: root.editedProtocol ? String(root.editedProtocol.clampForce) : "0"
                        unitText: qsTr("g")
                        accent: "#FBBF24"
                        from: 50
                        to: 500
                        step: 10
                        sliderValue: root.editedProtocol ? root.editedProtocol.clampForce : 0
                        minLabel: qsTr("50 g")
                        maxLabel: qsTr("500 g")
                        onValueEdited: (v) => root.callParent("updateField", "clampForce", Math.round(v/10)*10)
                    }

                    ParamCard {
                        title: qsTr("Water Temperature")
                        valueText: root.editedProtocol ? String(root.editedProtocol.waterTemp) : "0"
                        unitText: qsTr("°C")
                        accent: "#60A5FA"
                        from: 15
                        to: 50
                        step: 1
                        sliderValue: root.editedProtocol ? root.editedProtocol.waterTemp : 0
                        minLabel: qsTr("15 °C")
                        maxLabel: qsTr("50 °C")
                        onValueEdited: (v) => root.callParent("updateField", "waterTemp", Math.round(v))
                    }
                }

                // Cycles (full width)
                ParamCardWide {
                    Layout.fillWidth: true
                    title: qsTr("Number of Cycles")
                    valueText: root.editedProtocol ? String(root.editedProtocol.cycles) : "1"
                    unitText: qsTr("cycles")
                    accent: "#A78BFA"

                    from: 1
                    to: 20
                    step: 1
                    sliderValue: root.editedProtocol ? root.editedProtocol.cycles : 1

                    leftLabel: qsTr("1")
                    mid1Label: qsTr("5")
                    mid2Label: qsTr("10")
                    mid3Label: qsTr("15")
                    rightLabel: qsTr("20")

                    onValueEdited: (v) => root.callParent("updateField", "cycles", Math.round(v))          
                }


                // Estimate card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 88
                    radius: 12
                    color: Qt.rgba(0.06, 0.45, 0.55, 0.22)
                    border.color: Qt.rgba(0.36, 0.84, 0.95, 0.35)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Text { text: qsTr("Estimated Duration"); color: Constants.accentSky; font.pixelSize: 11; font.bold: true }
                            Text {
                                text: (root.parent ? (root.parent.calculateDurationMinutes() + " min") : "0 min")
                                color: Constants.accentSky
                                font.pixelSize: 22
                                font.bold: true
                            }
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignRight
                            spacing: 4
                            Text { text: qsTr("Total Distance"); color: Constants.textSecondary; font.pixelSize: 11 }
                            Text {
                                text: (root.parent ? (root.parent.calculateDistanceMeters().toFixed(1) + " m") : "0.0 m")
                                color: Constants.textPrimary
                                font.pixelSize: 18
                                font.bold: true
                            }
                        }
                    }
                }

                // Action buttons row (like screenshot)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Button {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 58
                        text: qsTr("▶  RUN PROTOCOL")
                        font.pixelSize: 14
                        font.bold: true
                        background: Rectangle {
                            radius: 12
                            color: parent.pressed ? "#059669" : "#10B981"
                        }
                        onClicked: root.callParent("runProtocol")
                    }

                    Button {
                        Layout.preferredWidth: 120
                        Layout.preferredHeight: 58
                        text: qsTr("SAVE")
                        font.pixelSize: 13
                        font.bold: true
                        background: Rectangle {
                            radius: 12
                            color: parent.pressed ? Constants.accentPrimary : Constants.accentSky
                        }
                        onClicked: root.callParent("saveProtocol")
                    }

                    Button {
                        Layout.preferredWidth: 140
                        Layout.preferredHeight: 58
                        text: qsTr("DUPLICATE")
                        font.pixelSize: 13
                        font.bold: true
                        background: Rectangle {
                            radius: 12
                            color: parent.pressed ? "#374151" : "#4B5563"
                        }
                        onClicked: root.callParent("duplicateProtocol")
                    }

                    Button {
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 58
                        text: "🗑"
                        font.pixelSize: 18
                        background: Rectangle {
                            radius: 12
                            color: parent.pressed ? Qt.rgba(0.87, 0.13, 0.13, 0.45) : Qt.rgba(0.87, 0.13, 0.13, 0.30)
                            border.color: "#DC2626"
                            border.width: 1
                        }
                        onClicked: root.callParent("deleteProtocol")
                    }
                }

                Item { Layout.preferredHeight: 12 }
            }
        }
    }

    // ============
    // Reusable pieces (safe signal names)
    // ============
    component Card: Rectangle {
        property string title: ""
        property Component content

        radius: 14
        color: Constants.bgCard
        border.color: Constants.borderDefault
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                color: "transparent"
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    Text { text: title; color: Constants.textSecondary; font.pixelSize: 11 }
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Constants.borderDefault; opacity: 0.6 }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Loader { anchors.fill: parent; sourceComponent: content }
            }
        }
    }

    component ParamCard: Rectangle {
        property string title: ""
        property string valueText: "0"
        property string unitText: ""
        property color accent: Constants.accentSky
        property real from: 0
        property real to: 100
        property real step: 1
        property real sliderValue: 0
        property string minLabel: ""
        property string maxLabel: ""
        signal valueEdited(real v) // safe (not *Changed)

        Layout.fillWidth: true
        Layout.preferredHeight: 150
        radius: 14
        color: Constants.bgCard
        border.color: Constants.borderDefault
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            Text { text: title; color: Constants.textSecondary; font.pixelSize: 11 }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text { text: valueText; color: accent; font.pixelSize: 28; font.bold: true }
                Text { text: unitText; color: Constants.textSecondary; font.pixelSize: 12 }
            }

            Slider {
                id: s
                Layout.fillWidth: true
                from: parent.parent.from
                to: parent.parent.to
                stepSize: parent.parent.step
                value: parent.parent.sliderValue

                onMoved: {
                    if (pressed) valueEdited(value)
                }

            }


            RowLayout {
                Layout.fillWidth: true
                Text { text: minLabel; color: Constants.textMuted; font.pixelSize: 10; Layout.fillWidth: true }
                Text { text: maxLabel; color: Constants.textMuted; font.pixelSize: 10 }
            }
        }
    }

    component ParamCardWide: Rectangle {
        property string title: ""
        property string valueText: "0"
        property string unitText: ""
        property color accent: Constants.accentSky
        property real from: 0
        property real to: 100
        property real step: 1
        property real sliderValue: 0
        property string leftLabel: ""
        property string mid1Label: ""
        property string mid2Label: ""
        property string mid3Label: ""
        property string rightLabel: ""
        signal valueEdited(real v) // safe

        radius: 14
        color: Constants.bgCard
        border.color: Constants.borderDefault
        border.width: 1
        Layout.preferredHeight: 160

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            Text { text: title; color: Constants.textSecondary; font.pixelSize: 11 }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text { text: valueText; color: accent; font.pixelSize: 30; font.bold: true }
                Text { text: unitText; color: Constants.textSecondary; font.pixelSize: 12 }
            }

            Slider {
                id: s
                Layout.fillWidth: true
                from: parent.parent.from
                to: parent.parent.to
                stepSize: parent.parent.step
                value: parent.parent.sliderValue

                onMoved: {
                    if (pressed) valueEdited(value)
                }


            }

            RowLayout {
                Layout.fillWidth: true
                Text { text: leftLabel; color: Constants.textMuted; font.pixelSize: 10; Layout.fillWidth: true }
                Text { text: mid1Label; color: Constants.textMuted; font.pixelSize: 10; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                Text { text: mid2Label; color: Constants.textMuted; font.pixelSize: 10; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                Text { text: mid3Label; color: Constants.textMuted; font.pixelSize: 10; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                Text { text: rightLabel; color: Constants.textMuted; font.pixelSize: 10; horizontalAlignment: Text.AlignRight }
            }
        }
    }
}
