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

    // =========================
    // Engineer Lock / Code Gate
    // =========================
    // TODO: replace with your real code source (settings/backend/secure store)
    readonly property string engineerCode: "1234"

    // editor lock state (per editor session)
    property bool editorUnlocked: false
    property bool pendingLockValue: false
    property string pendingAction: ""     // "toggleLock" | "unlockEditor" | "delete"
    property int pendingDeleteIndex: -1

    function isLockedProtocol(p) {
        return !!(p && p.engineerLock)
    }

    function canEditProtocolNow() {
        return !!editingProtocol && (!isLockedProtocol(editingProtocol) || editorUnlocked)
    }

    // UI state
    property bool editorOpen: false
    property bool editingExisting: false
    property int selectedIndex: -1
    property int editingIndex: -1
    property var editingProtocol: ({})
    property bool busy: false
    property string loadError: ""

    ListModel { id: protocolsModel }

    // ---------------------------
    // Backend mapping (FastAPI fields)
    // ---------------------------
    function toUiShape(p) {
        return {
            id: p.id,
            name: p.name,
            speed: Number(p.speed),                       // cm/s
            strokeLength: Number(p.stroke_length_mm),     // mm
            clampForce: Number(p.clamp_force_g),          // g
            waterTemp: Number(p.water_temp_c),            // C
            cycles: Number(p.cycles),
            createdAt: p.created_at || "",
            updatedAt: p.updated_at || "",
            // NEW: engineer lock (backend field suggested: engineer_lock)
            engineerLock: !!p.engineer_lock
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
            engineer_lock: !!p.engineerLock
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
            engineerLock: false
        }
        editorUnlocked = true // new protocol is editable
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
            engineerLock: !!p.engineerLock
        }

        // If locked -> start read-only until code entered
        editorUnlocked = !editingProtocol.engineerLock
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
        if (!canEditProtocolNow()) return

        busy = true

        if (editingExisting && editingProtocol.id !== null) {
            var patch = {
                name: editingProtocol.name,
                speed: Number(editingProtocol.speed),
                stroke_length_mm: Number(editingProtocol.strokeLength),
                clamp_force_g: Number(editingProtocol.clampForce),
                water_temp_c: Number(editingProtocol.waterTemp),
                cycles: Number(editingProtocol.cycles),
                engineer_lock: !!editingProtocol.engineerLock
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

        // If locked, require code
        if (p.engineerLock === true) {
            pendingAction = "delete"
            pendingDeleteIndex = idx
            engineerCodeDialog.open()
            return
        }

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
            cycles: Number(p.cycles),
            engineer_lock: !!p.engineerLock
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

    // =========================
    // Engineer code dialog
    // =========================
    Dialog {
        id: engineerCodeDialog
        modal: true
        dim: true
        title: qsTr("Engineer Code Required")
        standardButtons: Dialog.NoButton
        x: Math.round((root.width - width) / 2)
        y: Math.round((root.height - height) / 2)

        property string errorText: ""

        onOpened: {
            errorText = ""
            engineerCodeField.text = ""
            engineerCodeField.forceActiveFocus()
        }

        contentItem: ColumnLayout {
            width: 380
            spacing: 12

            Text {
                text: qsTr("Enter engineer code to continue.")
                color: Constants.textSecondary
                wrapMode: Text.WordWrap
            }

            TextField {
                id: engineerCodeField
                Layout.fillWidth: true
                placeholderText: qsTr("Numeric code")
                echoMode: TextInput.Password
                inputMethodHints: Qt.ImhDigitsOnly
                validator: RegularExpressionValidator { regularExpression: /^[0-9]{0,8}$/ }
            }

            Text {
                visible: engineerCodeDialog.errorText !== ""
                text: engineerCodeDialog.errorText
                color: "#F87171"
                font.pixelSize: 12
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item { Layout.fillWidth: true }

                Button {
                    text: qsTr("Cancel")
                    onClicked: engineerCodeDialog.close()
                    background: Rectangle { radius: 10; color: Constants.bgSurface }
                    contentItem: Text { text: qsTr("Cancel"); color: Constants.textPrimary; font.pixelSize: 14 }
                }

                Button {
                    text: qsTr("Confirm")
                    background: Rectangle { radius: 10; color: Constants.accentPrimary }
                    contentItem: Text {
                        text: qsTr("Confirm")
                        color: "white"
                        font.pixelSize: 14
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        if (engineerCodeField.text !== root.engineerCode) {
                            engineerCodeDialog.errorText = qsTr("Incorrect code.")
                            return
                        }

                        // success
                        engineerCodeDialog.close()

                        if (pendingAction === "toggleLock") {
                            // allow toggle + editing
                            editorUnlocked = true
                            updateField("engineerLock", pendingLockValue)
                        } else if (pendingAction === "unlockEditor") {
                            editorUnlocked = true
                        } else if (pendingAction === "delete") {
                            var idx = pendingDeleteIndex
                            pendingDeleteIndex = -1
                            pendingAction = ""
                            // proceed delete now that code is ok
                            var p = protocolsModel.get(idx)
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
                            return
                        }

                        pendingAction = ""
                    }
                }
            }
        }
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
                visible: (root.mode === "selectOnly") || editorOpen
                text: editorOpen ? "Cancel" : "Back"
                Layout.preferredWidth: 120
                onClicked: {
                    if (editorOpen) {
                        editorOpen = false
                    } else {
                        root.stack.pop()
                    }
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
                enabled: !busy && canEditProtocolNow()
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

            Column {
                anchors.centerIn: parent
                spacing: 10
                visible: !busy && loadError !== ""

                Text { text: loadError; color: Constants.accentWarning; font.pixelSize: 16 }
                Button { text: "Retry"; onClicked: loadProtocols() }
            }

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

                            // NEW: LOCKED badge
                            Rectangle {
                                visible: engineerLock === true
                                radius: 8
                                color: Constants.bgSurface
                                border.color: Constants.borderDefault
                                border.width: 1
                                implicitWidth: 84
                                implicitHeight: 28

                                Text {
                                    anchors.centerIn: parent
                                    text: "LOCKED"
                                    color: "#FBBF24"
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
                                enabled: !busy
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
                                enabled: !busy
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

        // EDITOR
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

                // -------------------------
                // Header row: Name + Engineer Lock
                // -------------------------
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    spacing: 12

                    TextField {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        placeholderText: qsTr("Protocol Name")
                        text: editingProtocol ? editingProtocol.name : ""
                        font.pixelSize: 28
                        font.bold: true
                        color: Constants.textPrimary
                        background: Rectangle { color: "transparent" }

                        enabled: canEditProtocolNow()
                        onTextEdited: updateField("name", text)
                    }

                    Rectangle {
                        Layout.preferredWidth: 220
                        Layout.fillHeight: true
                        radius: 12
                        color: Constants.bgCard
                        border.color: Constants.borderDefault
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Text {
                                text: "🔒"
                                font.pixelSize: 18
                                color: Constants.textSecondary
                            }

                            Text {
                                text: qsTr("Engineer Lock")
                                color: Constants.textPrimary
                                font.pixelSize: 14
                                font.bold: true
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Switch {
                                id: engineerLockSwitch
                                checked: editingProtocol ? !!editingProtocol.engineerLock : false
                                enabled: !busy && !!editingProtocol

                                onToggled: {
                                    // Don't allow silent toggle; require code.
                                    pendingLockValue = checked
                                    pendingAction = "toggleLock"

                                    // snap UI back until confirmed
                                    checked = editingProtocol ? !!editingProtocol.engineerLock : false

                                    engineerCodeDialog.open()
                                }
                            }
                        }
                    }
                }

                // If locked and not unlocked, show an unlock banner
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: (!canEditProtocolNow() && isLockedProtocol(editingProtocol)) ? 56 : 0
                    visible: (!canEditProtocolNow() && isLockedProtocol(editingProtocol))
                    radius: 12
                    color: Constants.bgSurface
                    border.color: Constants.borderDefault
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Text {
                            text: qsTr("This protocol is engineer locked.")
                            color: Constants.textSecondary
                            font.pixelSize: 14
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Button {
                            text: qsTr("Unlock")
                            enabled: !busy
                            onClicked: {
                                pendingAction = "unlockEditor"
                                engineerCodeDialog.open()
                            }
                            background: Rectangle { radius: 10; color: Constants.accentPrimary }
                            contentItem: Text {
                                text: qsTr("Unlock")
                                color: "white"
                                font.pixelSize: 14
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

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
                        enabled: canEditProtocolNow()
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
                        enabled: canEditProtocolNow()
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
                        enabled: canEditProtocolNow()
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
                        maxLabel: qsTr("50 °C")
                        enabled: canEditProtocolNow()
                        onValueEdited: (v) => updateField("waterTemp", Math.round(v))
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
                    enabled: canEditProtocolNow()
                    onValueEdited: (v) => updateField("cycles", Math.round(v))
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
                    protocolChosen({
                        id: p.id,
                        name: p.name,
                        speed: p.speed,
                        stroke_length_mm: p.strokeLength,
                        clamp_force_g: p.clampForce,
                        water_temp_c: p.waterTemp,
                        cycles: p.cycles,
                        engineer_lock: !!p.engineerLock
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
    // Reusable components (same)
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
