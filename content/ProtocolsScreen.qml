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

    // "prepAndRun" (browse) | "selectOnly" (from Config)
    property string mode: "prepAndRun"

    // parent (NavShell) decides what to do after selection
    signal protocolChosen(var protocolObj)

    // UI state
    property bool editorOpen: false
    property bool editingExisting: false
    property int selectedIndex: -1
    property int editingIndex: -1

    // Holds the protocol being edited (object)
    property var editingProtocol: ({})
    property bool busy: false
    property string loadError: ""

    ListModel { id: protocolsModel }

    // ---------------------------
    // Helpers
    // ---------------------------
    function _safe(v, fallback) { return (v === undefined || v === null) ? fallback : v }

    function _toEditorShape(p) {
        return {
            id: _safe(p.id, null),
            name: _safe(p.name, "New Protocol"),
            speed: Number(_safe(p.speed, 1.0)),              // cm/s
            strokeLength: Number(_safe(p.strokeLength, 50)), // mm
            clampForce: Number(_safe(p.clampForce, 100)),    // g (or your unit)
            waterTemp: Number(_safe(p.waterTemp, 37)),       // °C
            cycles: Number(_safe(p.cycles, 1)),
            lastModified: _safe(p.lastModified, ""),
            factory: !!_safe(p.factory, false)
        }
    }

    function _fromEditorShape(p) {
        // what we send back to backend
        return {
            id: p.id,
            name: p.name,
            speed: Number(p.speed),
            strokeLength: Number(p.strokeLength),
            clampForce: Number(p.clampForce),
            waterTemp: Number(p.waterTemp),
            cycles: Number(p.cycles),
            factory: !!p.factory
        }
    }

    // ---------------------------
    // Backend load
    // ---------------------------
    function loadProtocols() {
        if (!backend) {
            console.warn("ProtocolsScreen: backend is null")
            return
        }

        busy = true
        loadError = ""

        // ✅ CHANGE THIS PATH if yours differs
        backend.request("GET", "/protocols", null, function(ok, status, data) {
            busy = false
            protocolsModel.clear()

            if (!ok || !data) {
                loadError = "Failed to load protocols"
                console.error("GET /protocols failed:", status, data)
                return
            }

            // If backend returns {protocols:[...]} support that too
            var arr = Array.isArray(data) ? data : (data.protocols || [])
            for (var i = 0; i < arr.length; i++) {
                var p = _toEditorShape(arr[i])
                protocolsModel.append(p)
            }

            // default selection
            selectedIndex = (protocolsModel.count > 0) ? 0 : -1
        })
    }

    Component.onCompleted: loadProtocols()

    // ---------------------------
    // Add / Edit / Save / Delete
    // ---------------------------
    function openNewProtocol() {
        editingExisting = false
        editingIndex = -1
        editingProtocol = {
            id: null,
            name: "New Protocol",
            speed: 1.0,
            strokeLength: 50,
            clampForce: 100,
            waterTemp: 37,
            cycles: 1,
            lastModified: "",
            factory: false
        }
        editorOpen = true
    }

    function openEditProtocol(idx) {
        if (idx < 0 || idx >= protocolsModel.count) return
        var p = protocolsModel.get(idx)

        editingExisting = true
        editingIndex = idx
        editingProtocol = _toEditorShape(p)
        editorOpen = true
    }

    function updateField(key, value) {
        // called by UI controls
        var p = editingProtocol
        if (!p) return
        p[key] = value
        editingProtocol = p // force notify
    }

    function saveProtocol() {
        if (!backend) return
        if (!editingProtocol || !editingProtocol.name || editingProtocol.name.trim().length === 0) return
        if (editingProtocol.factory === true) return // can't edit factory

        busy = true
        var payload = _fromEditorShape(editingProtocol)

        if (editingExisting && editingProtocol.id) {
            // ✅ CHANGE THIS PATH if yours differs
            backend.request("PUT", "/protocols/" + editingProtocol.id, payload, function(ok, status, data) {
                busy = false
                if (!ok) {
                    console.error("PUT failed:", status, data)
                    return
                }

                // update local model
                protocolsModel.set(editingIndex, _toEditorShape(payload))
                selectedIndex = editingIndex
                editorOpen = false

                // reload if you want server-calculated fields like lastModified
                loadProtocols()
            })
        } else {
            // ✅ CHANGE THIS PATH if yours differs
            backend.request("POST", "/protocols", payload, function(ok, status, data) {
                busy = false
                if (!ok) {
                    console.error("POST failed:", status, data)
                    return
                }
                editorOpen = false
                loadProtocols()
            })
        }
    }

    function deleteProtocol(idx) {
        if (!backend) return
        if (idx < 0 || idx >= protocolsModel.count) return

        var p = protocolsModel.get(idx)
        if (p.factory === true) return
        if (!p.id) return

        busy = true
        // ✅ CHANGE THIS PATH if yours differs
        backend.request("DELETE", "/protocols/" + p.id, null, function(ok, status, data) {
            busy = false
            if (!ok) {
                console.error("DELETE failed:", status, data)
                return
            }
            editorOpen = false
            loadProtocols()
        })
    }

    function duplicateProtocol(idx) {
        if (!backend) return
        if (idx < 0 || idx >= protocolsModel.count) return

        var p = protocolsModel.get(idx)
        // easiest: create with "Copy" locally, then POST
        var payload = _fromEditorShape(_toEditorShape(p))
        payload.id = null
        payload.factory = false
        payload.name = payload.name + " Copy"

        busy = true
        backend.request("POST", "/protocols", payload, function(ok, status, data) {
            busy = false
            if (!ok) {
                console.error("DUPLICATE POST failed:", status, data)
                return
            }
            loadProtocols()
        })
    }

    // ---------------------------
    // Top bar
    // ---------------------------
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
                }
                background: Rectangle { radius: 10; color: "transparent" }
                contentItem: Text { text: parent.text; color: Constants.textPrimary; font.pixelSize: 16 }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: editorOpen ? (editingExisting ? "Edit Protocol" : "New Protocol") : "Select Test Protocol"
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
                enabled: !busy
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
                enabled: !busy && editingProtocol && editingProtocol.factory !== true
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

    // ---------------------------
    // Body: list or editor
    // ---------------------------
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

            Column {
                anchors.centerIn: parent
                spacing: 10
                visible: !busy && protocolsModel.count === 0 && loadError === ""

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

            Column {
                anchors.centerIn: parent
                spacing: 10
                visible: loadError !== ""

                Text { text: loadError; color: Constants.accentWarning; font.pixelSize: 16 }
                Button {
                    text: "Retry"
                    onClicked: loadProtocols()
                }
            }

            BusyIndicator {
                anchors.centerIn: parent
                running: busy
                visible: busy
            }

            ListView {
                id: list
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14
                clip: true
                model: protocolsModel
                visible: !busy && protocolsModel.count > 0

                delegate: Rectangle {
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
                                Text { text: speed + " cm/s"; color: Constants.textPrimary; font.pixelSize: 16 }
                            }
                            ColumnLayout {
                                Text { text: "Clamp:"; color: Constants.textSecondary; font.pixelSize: 12 }
                                Text { text: clampForce + " g"; color: Constants.textPrimary; font.pixelSize: 16 }
                            }
                            ColumnLayout {
                                Text { text: "Cycles:"; color: Constants.textSecondary; font.pixelSize: 12 }
                                Text { text: cycles; color: Constants.textPrimary; font.pixelSize: 16 }
                            }
                            ColumnLayout {
                                Text { text: "Stroke:"; color: Constants.textSecondary; font.pixelSize: 12 }
                                Text { text: strokeLength + " mm"; color: Constants.textPrimary; font.pixelSize: 16 }
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
                                enabled: !busy
                                onClicked: root.duplicateProtocol(index)
                                background: Rectangle { radius: 10; color: Constants.bgSurface }
                                contentItem: Text { text: "Duplicate"; color: Constants.textPrimary; font.pixelSize: 14 }
                            }
                        }
                    }
                }
            }
        }

        // EDITOR VIEW (your old right-side style)
        Flickable {
            anchors.fill: parent
            visible: editorOpen
            clip: true
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: width
            contentHeight: editorContent.implicitHeight + 24

            ColumnLayout {
                id: editorContent
                width: Math.min(parent.width, 760)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.margins: 28
                spacing: 18

                // Title field (like old right panel)
                Item {
                    Layout.fillWidth: true
                    height: 52

                    TextField {
                        id: titleField
                        anchors.fill: parent
                        placeholderText: qsTr("Protocol Name")
                        text: editingProtocol ? editingProtocol.name : ""
                        font.pixelSize: 28
                        font.bold: true
                        color: Constants.textPrimary
                        background: Rectangle { color: "transparent" }

                        onTextEdited: updateField("name", text)
                        enabled: editingProtocol && editingProtocol.factory !== true
                    }
                }

                // 2x2 grid (same as old right side)
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 16
                    columnSpacing: 16

                    ParamCard {
                        title: qsTr("Test Speed")
                        valueText: editingProtocol ? editingProtocol.speed.toFixed(1) : "0.0"
                        unitText: qsTr("cm/s")
                        accent: Constants.accentSky
                        from: 0.1
                        to: 2.5
                        step: 0.1
                        sliderValue: editingProtocol ? editingProtocol.speed : 0
                        minLabel: qsTr("0.1 cm/s")
                        maxLabel: qsTr("2.5 cm/s")
                        onValueEdited: (v) => updateField("speed", Math.round(v * 10) / 10)
                        enabled: editingProtocol && editingProtocol.factory !== true
                    }

                    ParamCard {
                        title: qsTr("Stroke Length")
                        valueText: editingProtocol ? String(editingProtocol.strokeLength) : "0"
                        unitText: qsTr("mm")
                        accent: "#4ADE80"
                        from: 10
                        to: 150
                        step: 1
                        sliderValue: editingProtocol ? editingProtocol.strokeLength : 0
                        minLabel: qsTr("10 mm")
                        maxLabel: qsTr("150 mm")
                        onValueEdited: (v) => updateField("strokeLength", Math.round(v))
                        enabled: editingProtocol && editingProtocol.factory !== true
                    }

                    ParamCard {
                        title: qsTr("Clamp Force")
                        valueText: editingProtocol ? String(editingProtocol.clampForce) : "0"
                        unitText: qsTr("g")
                        accent: "#FBBF24"
                        from: 50
                        to: 500
                        step: 10
                        sliderValue: editingProtocol ? editingProtocol.clampForce : 0
                        minLabel: qsTr("50 g")
                        maxLabel: qsTr("500 g")
                        onValueEdited: (v) => updateField("clampForce", Math.round(v/10)*10)
                        enabled: editingProtocol && editingProtocol.factory !== true
                    }

                    ParamCard {
                        title: qsTr("Water Temperature")
                        valueText: editingProtocol ? String(editingProtocol.waterTemp) : "0"
                        unitText: qsTr("°C")
                        accent: "#60A5FA"
                        from: 15
                        to: 50
                        step: 1
                        sliderValue: editingProtocol ? editingProtocol.waterTemp : 0
                        minLabel: qsTr("15 °C")
                        maxLabel: qsTr("50 °C")
                        onValueEdited: (v) => updateField("waterTemp", Math.round(v))
                        enabled: editingProtocol && editingProtocol.factory !== true
                    }
                }

                ParamCardWide {
                    Layout.fillWidth: true
                    title: qsTr("Number of Cycles")
                    valueText: editingProtocol ? String(editingProtocol.cycles) : "1"
                    unitText: qsTr("cycles")
                    accent: "#A78BFA"
                    from: 1
                    to: 20
                    step: 1
                    sliderValue: editingProtocol ? editingProtocol.cycles : 1
                    leftLabel: qsTr("1")
                    mid1Label: qsTr("5")
                    mid2Label: qsTr("10")
                    mid3Label: qsTr("15")
                    rightLabel: qsTr("20")
                    onValueEdited: (v) => updateField("cycles", Math.round(v))
                    enabled: editingProtocol && editingProtocol.factory !== true
                }

                // Actions in editor
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Button {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 58
                        text: qsTr("▶  RUN PROTOCOL")
                        enabled: !busy && editingProtocol
                        background: Rectangle { radius: 12; color: parent.pressed ? "#059669" : "#10B981" }
                        onClicked: {
                            // treat like bottom CTA: choose this protocol and let NavShell decide
                            protocolChosen(_fromEditorShape(editingProtocol))
                            editorOpen = false
                        }
                    }

                    Button {
                        Layout.preferredWidth: 120
                        Layout.preferredHeight: 58
                        text: qsTr("SAVE")
                        enabled: !busy && editingProtocol && editingProtocol.factory !== true
                        background: Rectangle { radius: 12; color: parent.pressed ? Constants.accentPrimary : Constants.accentSky }
                        onClicked: saveProtocol()
                    }

                    Button {
                        Layout.preferredWidth: 140
                        Layout.preferredHeight: 58
                        text: qsTr("DUPLICATE")
                        enabled: !busy && editingProtocol
                        background: Rectangle { radius: 12; color: parent.pressed ? "#374151" : "#4B5563" }
                        onClicked: {
                            // duplicate current editor protocol by POST
                            var idx = editingIndex >= 0 ? editingIndex : selectedIndex
                            duplicateProtocol(idx)
                        }
                    }

                    Button {
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 58
                        text: "🗑"
                        enabled: !busy && editingExisting && editingProtocol && editingProtocol.factory !== true
                        background: Rectangle {
                            radius: 12
                            color: parent.pressed ? Qt.rgba(0.87, 0.13, 0.13, 0.45) : Qt.rgba(0.87, 0.13, 0.13, 0.30)
                            border.color: "#DC2626"
                            border.width: 1
                        }
                        onClicked: deleteProtocol(editingIndex)
                    }
                }

                Item { Layout.preferredHeight: 12 }
            }
        }
    }

    // ---------------------------
    // Bottom CTA (List screen)
    // ---------------------------
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
            color: (root.selectedIndex >= 0 && !editorOpen && !busy) ? Constants.accentPrimary : Constants.bgSurface
            border.color: Constants.borderDefault
            border.width: 1

            MouseArea {
                anchors.fill: parent
                enabled: (root.selectedIndex >= 0 && !editorOpen && !busy)
                onClicked: {
                    var proto = protocolsModel.get(root.selectedIndex)
                    root.protocolChosen(_fromEditorShape(proto))
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    text: "▶"
                    color: (root.selectedIndex >= 0 && !editorOpen && !busy) ? "white" : Constants.textSecondary
                    font.pixelSize: 18
                }

                Text {
                    text: (root.mode === "selectOnly") ? "Use Protocol" : "Select & Run"
                    color: (root.selectedIndex >= 0 && !editorOpen && !busy) ? "white" : Constants.textSecondary
                    font.pixelSize: 18
                    font.bold: true
                }
            }
        }
    }

    // ---------------------------
    // Reusable components (your originals, kept)
    // ---------------------------
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
        property bool enabled: true
        signal valueEdited(real v)

        Layout.fillWidth: true
        Layout.preferredHeight: 150
        radius: 14
        color: Constants.bgCard
        border.color: Constants.borderDefault
        border.width: 1
        opacity: enabled ? 1 : 0.5

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
                Layout.fillWidth: true
                from: parent.parent.from
                to: parent.parent.to
                stepSize: parent.parent.step
                value: parent.parent.sliderValue
                enabled: parent.parent.enabled
                onMoved: if (pressed) valueEdited(value)
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
        property bool enabled: true
        signal valueEdited(real v)

        radius: 14
        color: Constants.bgCard
        border.color: Constants.borderDefault
        border.width: 1
        Layout.preferredHeight: 160
        opacity: enabled ? 1 : 0.5

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
                Layout.fillWidth: true
                from: parent.parent.from
                to: parent.parent.to
                stepSize: parent.parent.step
                value: parent.parent.sliderValue
                enabled: parent.parent.enabled
                onMoved: if (pressed) valueEdited(value)
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
