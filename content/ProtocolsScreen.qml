import QtQuick
import QtQuick.Controls
import PilotLine_FrictionTester

Item {
    id: root
    width: Constants.width
    height: Constants.height

    property QtObject appMachine
    property var serialController
    property var backend

    // Track which protocol is selected
    property int selectedIndex: 0
    property int selectedProtocolId: -1

    Component.onCompleted: {
        console.log("✅ ProtocolsScreen WRAPPER LOADED", appMachine)
        backend.request("GET", "/health", null, function(ok, status, data) {
            console.log("HEALTH:", ok, status, JSON.stringify(data))
        })

        loadProtocols()
    }

    // Real model (now includes id)
    ListModel { id: protocolsModel }

    // Snapshot used by UI for editing
    property var editedProtocol: ({
        id: -1,
        name: "",
        speed: 1.0,
        strokeLength: 80,
        clampForce: 200,
        waterTemp: 37,
        cycles: 10,
        lastModified: ""
    })

    function _fmtLastModified(iso) {
        // backend sends ISO "2026-01-15T...Z"
        // keep simple for now
        return iso ? iso.replace("T", " ").replace("Z", "") : ""
    }

    function loadProtocols() {
        if (!backend) {
            console.log("❌ backend not provided to ProtocolsScreen")
            return
        }

        backend.request("GET", "/protocols", null, function(ok, status, data) {
            if (!ok) {
                console.log("GET /protocols failed", status)
                return
            }

            protocolsModel.clear()

            for (var i = 0; i < data.length; i++) {
                var p = data[i]
                protocolsModel.append({
                    id: p.id,
                    name: p.name,
                    speed: p.speed,
                    strokeLength: p.stroke_length_mm,
                    clampForce: p.clamp_force_g,
                    waterTemp: p.water_temp_c,
                    cycles: p.cycles,
                    lastModified: _fmtLastModified(p.updated_at)
                })
            }

            if (protocolsModel.count > 0) {
                // keep selection if possible
                var idx = Math.min(selectedIndex, protocolsModel.count - 1)
                selectProtocol(idx)
            } else {
                // no protocols yet → set edited defaults
                selectedIndex = 0
                selectedProtocolId = -1
                editedProtocol = ({
                    id: -1,
                    name: "New Protocol",
                    speed: 1.0,
                    strokeLength: 80,
                    clampForce: 200,
                    waterTemp: 37,
                    cycles: 10,
                    lastModified: ""
                })
            }
        })
    }

    function selectProtocol(index) {
        if (index < 0 || index >= protocolsModel.count) return

        selectedIndex = index
        var m = protocolsModel.get(index)

        selectedProtocolId = m.id

        editedProtocol = ({
            id: m.id,
            name: m.name,
            speed: m.speed,
            strokeLength: m.strokeLength,
            clampForce: m.clampForce,
            waterTemp: m.waterTemp,
            cycles: m.cycles,
            lastModified: m.lastModified
        })
    }

    function updateField(field, value) {
        var p = editedProtocol
        p[field] = value
        editedProtocol = p
    }

    function saveProtocol() {
        if (!backend) return
        if (selectedProtocolId < 0) {
            console.log("saveProtocol: no selectedProtocolId")
            return
        }

        var payload = {
            name: editedProtocol.name,
            speed: editedProtocol.speed,
            stroke_length_mm: editedProtocol.strokeLength,
            clamp_force_g: editedProtocol.clampForce,
            water_temp_c: editedProtocol.waterTemp,
            cycles: editedProtocol.cycles
        }

        backend.request("PUT", "/protocols/" + selectedProtocolId, payload, function(ok, status, data) {
            if (!ok) {
                console.log("PUT /protocols failed", status)
                return
            }
            // Refresh from DB so lastModified matches DB updated_at
            loadProtocols()
        })
    }

    function addProtocol() {
        if (!backend) return

        var payload = {
            name: "New Protocol",
            speed: 1.0,
            stroke_length_mm: 80,
            clamp_force_g: 200,
            water_temp_c: 37,
            cycles: 10
        }

        backend.request("POST", "/protocols", payload, function(ok, status, data) {
            if (!ok) {
                console.log("POST /protocols failed", status)
                return
            }
            // reload and select newly created protocol
            loadProtocols()
        })
    }

    function duplicateProtocol() {
        if (!backend) return

        var payload = {
            name: editedProtocol.name + " (Copy)",
            speed: editedProtocol.speed,
            stroke_length_mm: editedProtocol.strokeLength,
            clamp_force_g: editedProtocol.clampForce,
            water_temp_c: editedProtocol.waterTemp,
            cycles: editedProtocol.cycles
        }

        backend.request("POST", "/protocols", payload, function(ok, status, data) {
            if (!ok) {
                console.log("POST /protocols (duplicate) failed", status)
                return
            }
            loadProtocols()
        })
    }

    function deleteProtocol() {
        if (!backend) return
        if (selectedProtocolId < 0) return

        backend.request("DELETE", "/protocols/" + selectedProtocolId, null, function(ok, status, data) {
            if (!ok) {
                console.log("DELETE /protocols failed", status)
                return
            }
            // after delete, reload and select nearest
            var newIndex = Math.max(0, selectedIndex - 1)
            selectedIndex = newIndex
            loadProtocols()
        })
    }

    function runProtocol() {
        if (!backend) return
        if (selectedProtocolId < 0) return

        console.log("RUN PROTOCOL:", JSON.stringify(editedProtocol))

        backend.request("POST", "/runs", { protocol_id: selectedProtocolId, notes: "" }, function(ok, status, data) {
            if (!ok) {
                console.log("POST /runs failed", status)
                return
            }
            console.log("✅ Run created, id:", data.run_id)

            // Next step: tell ESP32 to start job + stream
            serialController.start_job("protocol_" + selectedProtocolId)


            // serialController.start_stream(10)
        })
    }

    function calculateDistanceMeters() : real {
        return (editedProtocol.cycles * 2.0 * editedProtocol.strokeLength) / 1000.0
    }

    function calculateDurationMinutes() : int {
        var v = editedProtocol.speed / 100.0
        if (v <= 0) return 0
        var s = calculateDistanceMeters() / v
        return Math.max(0, Math.round(s / 60.0))
    }

    ProtocolsScreenForm {
        anchors.fill: parent
        protocolsModel: protocolsModel
        editedProtocol: root.editedProtocol
    }
}
