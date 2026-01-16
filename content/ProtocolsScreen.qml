import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PilotLine_FrictionTester

Rectangle {
    id: root
    width: Constants.width
    height: Constants.height
    color: Constants.bgPrimary

    // passed in from NavShell
    property QtObject appMachine
    property var serialController
    property var backend

    // ✅ NEW: context of this screen
    // "prepAndRun" = came here directly / browse mode
    // "selectOnly" = came here from Config to choose a protocol (no prep)
    property string mode: "prepAndRun"

    // ✅ parent (NavShell) decides what to do after selection
    signal protocolChosen(var protocolObj)

    // UI state
    property bool editorOpen: false
    property bool editingExisting: false
    property int selectedIndex: -1
    property int editingIndex: -1
    property var editingProtocol: ({})
    property bool suppressSelect: false

    ListModel { id: protocolsModel }

    // ----- demo seed (remove once backend load is wired) -----
    function seedIfEmptyForDev() {
        if (protocolsModel.count > 0) return
        protocolsModel.append({ name:"Standard Catheter Test", speed:100, clamp:5, cycles:10, distance:150, factory:true })
        protocolsModel.append({ name:"Coating Durability", speed:80, clamp:8, cycles:20, distance:100, factory:true })
    }

    Component.onCompleted: {
        seedIfEmptyForDev()
        // TODO: load from backend storage
        // backend.request("GET", "/protocols", null, function(ok, status, data){ ... })
    }

    function openNewProtocol() {
        editingExisting = false
        editingIndex = -1
        editingProtocol = {
            name: "New Protocol",
            speed: 80,
            clamp: 5,
            cycles: 10,
            distance: 100,
            factory: false,
            waterTemp: 37,
            pauseBefore: 5
        }
        editorOpen = true
    }

    function openEditProtocol(idx) {
        editingExisting = true
        editingIndex = idx
        const p = protocolsModel.get(idx)
        editingProtocol = {
            name: p.name,
            speed: p.speed,
            clamp: p.clamp,
            cycles: p.cycles,
            distance: p.distance,
            factory: !!p.factory,
            waterTemp: p.waterTemp !== undefined ? p.waterTemp : 37,
            pauseBefore: p.pauseBefore !== undefined ? p.pauseBefore : 5
        }
        editorOpen = true
    }

    function duplicateProtocol(idx) {
        const p = protocolsModel.get(idx)
        protocolsModel.append({
            name: p.name + " Copy",
            speed: p.speed,
            clamp: p.clamp,
            cycles: p.cycles,
            distance: p.distance,
            factory: false,
            waterTemp: p.waterTemp !== undefined ? p.waterTemp : 37,
            pauseBefore: p.pauseBefore !== undefined ? p.pauseBefore : 5
        })
    }

    function saveProtocol() {
        if (!editingProtocol.name || editingProtocol.name.trim().length === 0) return

        if (editingExisting && editingIndex >= 0) {
            protocolsModel.set(editingIndex, editingProtocol)
            selectedIndex = editingIndex
        } else {
            protocolsModel.append(editingProtocol)
            selectedIndex = protocolsModel.count - 1
        }

        editorOpen = false
        // TODO: persist to backend
    }

    // ===== TOP BAR =====
    Rectangle {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 64
        color: Constants.bgCard

        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Button {
                text: editorOpen ? "Cancel" : "Back"
                Layout.preferredWidth: 120
                onClicked: {
                    if (editorOpen) editorOpen = false
                    else {
                        // This screen usually lives inside your NavShell sidebar, so Back is optional.
                        // If you want, you can emit a signal later (backRequested()).
                    }
                }
                background: Rectangle { radius: 10; color: "transparent" }
                contentItem: Text { text: parent.text; color: Constants.textPrimary; font.pixelSize: 16 }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: editorOpen ? "Edit Protocol" : "Select Test Protocol"
                color: Constants.textPrimary
                font.pixelSize: 22
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            Item { Layout.fillWidth: true }

            Button {
                visible: !editorOpen
                text: "+  New"
                Layout.preferredWidth: 120
                onClicked: openNewProtocol()

                background: Rectangle { radius: 10; color: Constants.accentPrimary }
                contentItem: Text {
                    text: "+  New"
                    color: "white"
                    font.pixelSize: 16
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Button {
                visible: editorOpen
                text: "Save"
                Layout.preferredWidth: 120
                onClicked: saveProtocol()

                background: Rectangle { radius: 10; color: Constants.accentPrimary }
                contentItem: Text {
                    text: "Save"
                    color: "white"
                    font.pixelSize: 16
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    // ===== BODY =====
    Rectangle {
        id: body
        anchors.top: topBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bottomBar.top
        color: Constants.bgPrimary

        // LIST VIEW
        Item {
            anchors.fill: parent
            visible: !editorOpen

            // Empty state
            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: protocolsModel.count === 0

                Text {
                    text: "No protocols yet"
                    color: Constants.textPrimary
                    font.pixelSize: 22
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    text: "Tap + New to create your first protocol."
                    color: Constants.textSecondary
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            ListView {
                id: list
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14
                clip: true
                model: protocolsModel
                visible: protocolsModel.count > 0

                delegate: Rectangle {
                    id: card
                    width: list.width
                    height: 132
                    radius: 14
                    color: Constants.bgCard
                    border.width: (index === root.selectedIndex) ? 2 : 1
                    border.color: (index === root.selectedIndex) ? Constants.accentSky : Constants.borderDefault

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.selectedIndex = index
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: name
                                color: Constants.textPrimary
                                font.pixelSize: 18
                                font.bold: true
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                visible: factory === true
                                radius: 8
                                color: Constants.bgSurface
                                border.color: Constants.borderDefault
                                border.width: 1
                                implicitWidth: 84
                                implicitHeight: 28

                                Text {
                                    anchors.centerIn: parent
                                    text: "FACTORY"
                                    color: Constants.accentSky
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 22

                            ColumnLayout {
                                Text { text: "Speed:"; color: Constants.textSecondary; font.pixelSize: 12 }
                                Text { text: speed + " mm/s"; color: Constants.textPrimary; font.pixelSize: 16 }
                            }
                            ColumnLayout {
                                Text { text: "Clamp:"; color: Constants.textSecondary; font.pixelSize: 12 }
                                Text { text: clamp + " N"; color: Constants.textPrimary; font.pixelSize: 16 }
                            }
                            ColumnLayout {
                                Text { text: "Cycles:"; color: Constants.textSecondary; font.pixelSize: 12 }
                                Text { text: cycles; color: Constants.textPrimary; font.pixelSize: 16 }
                            }
                            ColumnLayout {
                                Text { text: "Distance:"; color: Constants.textSecondary; font.pixelSize: 12 }
                                Text { text: distance + " mm"; color: Constants.textPrimary; font.pixelSize: 16 }
                            }

                            Item { Layout.fillWidth: true }

                            Button {
                                text: "Edit"
                                enabled: factory !== true
                                onClicked: root.openEditProtocol(index)
                                background: Rectangle { radius: 10; color: Constants.bgSurface }
                                contentItem: Text {
                                    text: "Edit"
                                    color: enabled ? Constants.textPrimary : Constants.textSecondary
                                    font.pixelSize: 14
                                }
                            }

                            Button {
                                text: "Duplicate"
                                onClicked: root.duplicateProtocol(index)
                                background: Rectangle { radius: 10; color: Constants.bgSurface }
                                contentItem: Text { text: "Duplicate"; color: Constants.textPrimary; font.pixelSize: 14 }
                            }
                        }
                    }
                }
            }
        }

        // EDITOR VIEW (Add/Edit Protocol)
        Flickable {
            anchors.fill: parent
            visible: editorOpen
            contentWidth: width
            contentHeight: editorContent.implicitHeight + 24
            clip: true

            ColumnLayout {
                id: editorContent
                width: parent.width
                spacing: 14
                anchors.margins: 14

                Rectangle {
                    radius: 14
                    color: Constants.bgCard
                    border.color: Constants.borderDefault
                    border.width: 1
                    Layout.fillWidth: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10

                        Text { text: "Protocol Name"; color: Constants.accentSky; font.pixelSize: 18; font.bold: true }

                        TextField {
                            text: editingProtocol.name
                            placeholderText: "Name"
                            onTextChanged: editingProtocol.name = text
                            Layout.fillWidth: true
                        }
                    }
                }

                Rectangle {
                    radius: 14
                    color: Constants.bgCard
                    border.color: Constants.borderDefault
                    border.width: 1
                    Layout.fillWidth: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        Text { text: "Water & Preparation"; color: Constants.accentSky; font.pixelSize: 18; font.bold: true }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            ColumnLayout {
                                Layout.fillWidth: true
                                Text { text: "Water Temperature (°C)"; color: Constants.textSecondary; font.pixelSize: 12 }
                                TextField {
                                    text: "" + editingProtocol.waterTemp
                                    inputMethodHints: Qt.ImhDigitsOnly
                                    onTextChanged: editingProtocol.waterTemp = parseInt(text)
                                    Layout.fillWidth: true
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Text { text: "Pause Before Insertion (s)"; color: Constants.textSecondary; font.pixelSize: 12 }
                                TextField {
                                    text: "" + editingProtocol.pauseBefore
                                    inputMethodHints: Qt.ImhDigitsOnly
                                    onTextChanged: editingProtocol.pauseBefore = parseInt(text)
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ===== BOTTOM CTA =====
    Rectangle {
        id: bottomBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 78
        color: Constants.bgPrimary

        Rectangle {
            anchors.fill: parent
            anchors.margins: 14
            radius: 14
            color: (root.selectedIndex >= 0 && !editorOpen) ? Constants.accentPrimary : Constants.bgSurface
            border.color: Constants.borderDefault
            border.width: 1

            MouseArea {
                anchors.fill: parent
                enabled: (root.selectedIndex >= 0 && !editorOpen)
                onClicked: {
                    const proto = protocolsModel.get(root.selectedIndex)
                    root.protocolChosen(proto)
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    text: "▶"
                    color: (root.selectedIndex >= 0 && !editorOpen) ? "white" : Constants.textSecondary
                    font.pixelSize: 18
                }

                Text {
                    text: (root.mode === "selectOnly") ? "Use Protocol" : "Select & Run"
                    color: (root.selectedIndex >= 0 && !editorOpen) ? "white" : Constants.textSecondary
                    font.pixelSize: 18
                    font.bold: true
                }
            }
        }
    }
}
