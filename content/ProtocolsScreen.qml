import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PilotLine_FrictionTester

Rectangle {
    id: root
    anchors.fill: parent
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
    property var editingProtocol: ({})
    property bool busy: false
    property string loadError: ""

    // crude factory rule (adjust/remove)
    property bool useFactoryTag: true

    // Replace "zPosMm" with whatever your appMachine exposes (or bind to serialController if that's where it lives)
    property real currentPositionMm: appMachine && appMachine.zPosMm !== undefined ? Number(appMachine.zPosMm) : 0


    // --- Z JOG CONFIG ---
    property real fixedJogStepMm: 1.0        // value change per tap
    property real zJogVelocity: 5.0          // mm/s for MOVE_VEL
    property real fixedStartMinMm: 0
    property real fixedStartMaxMm: 200

    function clamp(v, lo, hi) {
        return Math.max(lo, Math.min(hi, v))
    }

    function adjustFixedStart(deltaMm) {
        if (!editingProtocol) return
        var cur = Number(editingProtocol.fixedStartMm || 0)
        var next = clamp(cur + deltaMm, fixedStartMinMm, fixedStartMaxMm)
        updateField("fixedStartMm", Math.round(next * 10) / 10)
    }



    ListModel { id: protocolsModel }

    // ---------------------------
    // Backend mapping (FastAPI fields)
    // ---------------------------
    function toUiShape(p) {
        return {
            id: p.id,
            name: p.name,
            speed: Number(p.speed),
            strokeLength: Number(p.stroke_length_mm),
            clampForce: Number(p.clamp_force_g),
            waterTemp: Number(p.water_temp_c),
            cycles: Number(p.cycles),
            // NEW
            fixedStartEnabled: !!p.fixed_start_enabled,
            fixedStartMm: Number(p.fixed_start_mm || 0),

            createdAt: p.created_at || "",
            updatedAt: p.updated_at || "",
            factory: useFactoryTag ? (p.id <= 3) : false
        }
    }


    function toApiCreate(p) {
        return {
            name: p.name,
            speed: Number(p.speed),
            stroke_length_mm: Number(p.strokeLength),
            clamp_force_g: Number(p.clampForce),
            water_temp_c: Number(p.waterTemp),
            cycles: Number(p.cycles),

            // NEW
            fixed_start_enabled: !!p.fixedStartEnabled,
            fixed_start_mm: Number(p.fixedStartMm || 0)
        }
    }


    function loadProtocols() {
        if (!backend) {
            console.warn("ProtocolsScreen: backend is null")
            return
        }

        busy = true
        loadError = ""

        backend.request("GET", "/protocols", null, function(ok, status, data) {
            busy = false
            protocolsModel.clear()

            if (!ok || !data) {
                loadError = "Failed to load protocols"
                console.error("GET /protocols failed:", status, data)
                return
            }

            for (var i = 0; i < data.length; i++) {
                protocolsModel.append(toUiShape(data[i]))
            }

            selectedIndex = (protocolsModel.count > 0) ? 0 : -1
        })
    }

    Component.onCompleted: loadProtocols()

    // ---------------------------
    // Editor (Add/Edit)
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

            // NEW
            fixedStartEnabled: false,
            fixedStartMm: 0
        }
        editorOpen = true
    }

    function openEditProtocol(idx) {
        if (idx < 0 || idx >= protocolsModel.count) return
        var p = protocolsModel.get(idx)

        editingExisting = true
        editingIndex = idx
        editingProtocol = {
            id: p.id,
            name: p.name,
            speed: p.speed,
            strokeLength: p.strokeLength,
            clampForce: p.clampForce,
            waterTemp: p.waterTemp,
            cycles: p.cycles,

            // NEW
            fixedStartEnabled: !!p.fixedStartEnabled,
            fixedStartMm: Number(p.fixedStartMm || 0),

            factory: !!p.factory
        }
        editorOpen = true
    }


    function updateField(key, value) {
        var p = editingProtocol
        if (!p) return
        p[key] = value
        editingProtocol = p // force notify
    }

    function saveProtocol() {
        if (!backend) return
        if (!editingProtocol || !editingProtocol.name || editingProtocol.name.trim().length === 0) return
        if (editingProtocol.factory === true) return

        busy = true

        if (editingExisting && editingProtocol.id !== null) {
            // FastAPI update expects dict[str,Any] of fields to update
            // Send only the API field names
            var patch = {
                name: editingProtocol.name,
                speed: Number(editingProtocol.speed),
                stroke_length_mm: Number(editingProtocol.strokeLength),
                clamp_force_g: Number(editingProtocol.clampForce),
                water_temp_c: Number(editingProtocol.waterTemp),
                cycles: Number(editingProtocol.cycles),

                // NEW
                fixed_start_enabled: !!editingProtocol.fixedStartEnabled,
                fixed_start_mm: Number(editingProtocol.fixedStartMm || 0)
            }

            backend.request("PUT", "/protocols/" + editingProtocol.id, patch, function(ok, status, data) {
                busy = false
                if (!ok) {
                    console.error("PUT /protocols failed:", status, data)
                    return
                }
                editorOpen = false
                loadProtocols()
            })
        } else {
            var payload = toApiCreate(editingProtocol)
            backend.request("POST", "/protocols", payload, function(ok, status, data) {
                busy = false
                if (!ok) {
                    console.error("POST /protocols failed:", status, data)
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

        busy = true
        backend.request("DELETE", "/protocols/" + p.id, null, function(ok, status, data) {
            busy = false
            if (!ok) {
                console.error("DELETE /protocols failed:", status, data)
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
        var payload = {
            name: p.name + " Copy",
            speed: Number(p.speed),
            stroke_length_mm: Number(p.strokeLength),
            clamp_force_g: Number(p.clampForce),
            water_temp_c: Number(p.waterTemp),
            cycles: Number(p.cycles)
        }

        busy = true
        backend.request("POST", "/protocols", payload, function(ok, status, data) {
            busy = false
            if (!ok) {
                console.error("POST duplicate failed:", status, data)
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
                // Visible as "Back" in selectOnly mode, or "Cancel" when editing
                visible: (root.mode === "selectOnly") || editorOpen
                text: editorOpen ? "Cancel" : "Back"
                Layout.preferredWidth: 120
                onClicked: {
                    if (editorOpen) {
                        editorOpen = false
                    } else {
                        // go back to HomeScreen
                        root.stack.pop()
                    }
                }
                //onClicked: { if (editorOpen) editorOpen = false }
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
    // Body
    // ---------------------------
    Rectangle {
        id: body
        anchors.top: topBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bottomBar.top
        color: Constants.bgPrimary

        // LIST
        Item {
            anchors.fill: parent
            visible: !editorOpen

            BusyIndicator {
                anchors.centerIn: parent
                running: busy
                visible: busy
            }

            // Error state
            Column {
                anchors.centerIn: parent
                spacing: 10
                visible: !busy && loadError !== ""

                Text { text: loadError; color: Constants.accentWarning; font.pixelSize: 16 }
                Button { text: "Retry"; onClicked: loadProtocols() }
            }

            // Empty state (center of content area)
            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: !busy && loadError === "" && protocolsModel.count === 0

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
                visible: !busy && loadError === "" && protocolsModel.count > 0

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
                                enabled: factory !== true && !busy
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

                            Button {
                                text: "🗑"
                                enabled: factory !== true && !busy
                                onClicked: root.deleteProtocol(index)
                                background: Rectangle {
                                    radius: 10
                                    color: enabled ? Qt.rgba(0.87, 0.13, 0.13, 0.30) : Qt.rgba(0.87, 0.13, 0.13, 0.15)
                                    border.color: "#DC2626"
                                    border.width: 1
                                }
                                contentItem: Text {
                                    text: "🗑"
                                    color: enabled ? "#DC2626" : Constants.textSecondary
                                    font.pixelSize: 14
                                }
                            }
                        }
                    }
                }
            }
        }

        // EDITOR (old right-side look)
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
                width: Math.min(parent.width, 900)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.margins: 28
                spacing: 18

                Item {
                    Layout.fillWidth: true
                    height: 52

                    TextField {
                        anchors.fill: parent
                        placeholderText: qsTr("Protocol Name")
                        text: editingProtocol ? editingProtocol.name : ""
                        font.pixelSize: 28
                        font.bold: true
                        color: Constants.textPrimary
                        background: Rectangle { color: "transparent" }
                        enabled: editingProtocol && editingProtocol.factory !== true
                        onTextEdited: updateField("name", text)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    // -------------------------
                    // LEFT: Grid + Cycles stack
                    // -------------------------
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 3
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
                                enabled: editingProtocol && editingProtocol.factory !== true
                                onValueEdited: (v) => updateField("speed", Math.round(v * 10) / 10)
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
                                enabled: editingProtocol && editingProtocol.factory !== true
                                onValueEdited: (v) => updateField("strokeLength", Math.round(v))
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
                                enabled: editingProtocol && editingProtocol.factory !== true
                                onValueEdited: (v) => updateField("clampForce", Math.round(v/10)*10)
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
                                maxLabel: qsTr("40 °C")
                                enabled: editingProtocol && editingProtocol.factory !== true
                                onValueEdited: (v) => updateField("waterTemp", Math.round(v))
                            }

                            ParamCardWide {
                                Layout.fillWidth: true
                                Layout.columnSpan: 2
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
                                enabled: editingProtocol && editingProtocol.factory !== true
                                onValueEdited: (v) => updateField("cycles", Math.round(v))
                            }
                        }

                        //
                        Rectangle {
                            id: fixedStartWide
                            Layout.fillWidth: true
                            radius: 14
                            color: Constants.bgCard
                            border.color: Constants.borderDefault
                            border.width: 1
                            Layout.preferredHeight: 200
                            opacity: (editingProtocol && editingProtocol.factory !== true) ? 1.0 : 0.5

                            readonly property bool canEdit: editingProtocol && editingProtocol.factory !== true
                            readonly property bool fixedOn: editingProtocol ? !!editingProtocol.fixedStartEnabled : false

                            Timer {
                                id: fixedJogRepeat
                                interval: 120
                                repeat: true
                                property int dir: 0
                                onTriggered: adjustFixedStart(dir * fixedJogStepMm)
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 12

                                // Header row (like ParamCardWide style)
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Text {
                                        text: qsTr("Fixed Start Point")
                                        color: Constants.textSecondary
                                        font.pixelSize: 11
                                        Layout.fillWidth: true
                                    }

                                    Switch {
                                        id: fixedStartSwitch
                                        checked: fixedStartWide.fixedOn
                                        enabled: fixedStartWide.canEdit
                                        Layout.alignment: Qt.AlignVCenter

                                        onToggled: {
                                            updateField("fixedStartEnabled", checked)
                                            if (checked) {
                                                updateField("fixedStartMm", Math.round(currentPositionMm * 10) / 10)
                                            }
                                        }
                                    }
                                }

                                // Value row (big number + unit)
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        text: editingProtocol
                                            ? (Math.round((editingProtocol.fixedStartMm || 0) * 10) / 10).toFixed(1)
                                            : "0.0"
                                        color: Constants.accentSky
                                        font.pixelSize: 34
                                        font.bold: true
                                    }

                                    Text {
                                        text: qsTr("mm")
                                        color: Constants.textSecondary
                                        font.pixelSize: 12
                                        Layout.alignment: Qt.AlignBottom
                                    }

                                    Item { Layout.fillWidth: true }

                                    // show current position small on the right
                                    Text {
                                        text: qsTr("Current: %1 mm").arg((Math.round(currentPositionMm * 10) / 10).toFixed(1))
                                        color: Constants.textMuted
                                        font.pixelSize: 12
                                        Layout.alignment: Qt.AlignBottom
                                    }
                                }

                                // Controls (always visible; disabled/greyed when switch off)
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    opacity: fixedStartSwitch.checked ? 1.0 : 0.45

                                    Button {
                                        id: setCurBtn
                                        text: qsTr("Set to Current")
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 44
                                        enabled: fixedStartWide.canEdit && fixedStartSwitch.checked

                                        background: Rectangle {
                                            radius: 10
                                            color: Constants.bgSurface
                                            opacity: setCurBtn.enabled ? 1.0 : 0.35
                                        }
                                        contentItem: Text {
                                            text: setCurBtn.text
                                            color: Constants.textPrimary
                                            font.pixelSize: 14
                                            font.bold: true
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        onClicked: updateField("fixedStartMm", Math.round(currentPositionMm * 10) / 10)
                                    }

                                    Button {
                                        id: jogUpBtn
                                        text: qsTr("JOG UP")
                                        Layout.preferredWidth: 150
                                        Layout.preferredHeight: 44
                                        enabled: fixedStartWide.canEdit && fixedStartSwitch.checked

                                        background: Rectangle {
                                            radius: 10
                                            color: Constants.accentSky
                                            opacity: jogUpBtn.enabled ? 1.0 : 0.35
                                        }

                                        contentItem: Text {
                                            text: jogUpBtn.text
                                            color: "white"
                                            font.pixelSize: 14
                                            font.bold: true
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        TapHandler {
                                            onPressedChanged: {
                                                if (!jogUpBtn.enabled) return

                                                if (pressed) {
                                                    adjustFixedStart(+fixedJogStepMm)
                                                    fixedJogRepeat.dir = +1
                                                    fixedJogRepeat.start()
                                                    serialController.jog_up("Z")
                                                } else {
                                                    fixedJogRepeat.stop()
                                                    serialController.stop_jog("Z")
                                                }
                                            }
                                        }
                                    }


                                    Button {
                                        id: jogDownBtn
                                        text: qsTr("JOG DOWN")
                                        Layout.preferredWidth: 150
                                        Layout.preferredHeight: 44
                                        enabled: fixedStartWide.canEdit && fixedStartSwitch.checked

                                        background: Rectangle {
                                            radius: 10
                                            color: Constants.accentSky
                                            opacity: jogDownBtn.enabled ? 1.0 : 0.35
                                        }

                                        contentItem: Text {
                                            text: jogDownBtn.text
                                            color: "white"
                                            font.pixelSize: 14
                                            font.bold: true
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        TapHandler {
                                            onPressedChanged: {
                                                if (!jogDownBtn.enabled) return

                                                if (pressed) {
                                                    adjustFixedStart(-fixedJogStepMm)
                                                    fixedJogRepeat.dir = -1
                                                    fixedJogRepeat.start()
                                                    serialController.jog_down("Z")
                                                } else {
                                                    fixedJogRepeat.stop()
                                                    serialController.stop_jog("Z")
                                                }

                                            }
                                        }
                                    }

                                }

                                // Optional helper line
                                Text {
                                    Layout.fillWidth: true
                                    text: qsTr("When enabled, the run will move to this position before starting.")
                                    color: Constants.textMuted
                                    font.pixelSize: 11
                                    wrapMode: Text.WordWrap
                                    visible: true
                                }
                            }
                        }

                    }

                    
                }


                Item { Layout.preferredHeight: 12 }
            }
        }
    }

    // ---------------------------
    // Bottom CTA (list)
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
                    var p = protocolsModel.get(root.selectedIndex)
                    // emit protocol in API field names so NavShell can store directly
                    protocolChosen({
                        id: p.id,
                        name: p.name,
                        speed: p.speed,
                        stroke_length_mm: p.strokeLength,
                        clamp_force_g: p.clampForce,
                        water_temp_c: p.waterTemp,
                        cycles: p.cycles,

                        fixed_start_enabled: !!p.fixedStartEnabled,
                        fixed_start_mm: Number(p.fixedStartMm || 0)
                    })
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
    // Reusable components (unchanged)
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
                Text { text: mid3Label; color: Constants.textMuted; font.pixelSize: 10; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                Text { text: rightLabel; color: Constants.textMuted; font.pixelSize: 10; horizontalAlignment: Text.AlignRight }
            }
        }
    }
}
