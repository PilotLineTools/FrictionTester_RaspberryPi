import QtQuick
import QtQuick.Controls
import PilotLine_FrictionTester

Item {
    id: root
    width: Constants.width
    height: Constants.height

    // Replace with your real storage later (JSON/DB/etc.)
    ListModel {
        id: protocolsModel
        ListElement { name: "Standard Catheter Test"; speed: 1.5; strokeLength: 80; clampForce: 250; waterTemp: 37; cycles: 10; lastModified: "2025-01-08 09:30" }
        ListElement { name: "High Temperature Validation"; speed: 1.8; strokeLength: 100; clampForce: 300; waterTemp: 45; cycles: 20; lastModified: "2025-01-07 14:15" }
        ListElement { name: "Low Force Profile"; speed: 1.0; strokeLength: 60; clampForce: 120; waterTemp: 25; cycles: 5; lastModified: "2025-01-06 11:22" }
        ListElement { name: "Endurance Test"; speed: 1.2; strokeLength: 80; clampForce: 250; waterTemp: 37; cycles: 11; lastModified: "2025-01-05 16:45" }
    }

    property int selectedIndex: 0

    // Edited snapshot (keeps UI responsive without mutating list until Save)
    property var editedProtocol: ({
        name: protocolsModel.count ? protocolsModel.get(selectedIndex).name : "",
        speed: protocolsModel.count ? protocolsModel.get(selectedIndex).speed : 0,
        strokeLength: protocolsModel.count ? protocolsModel.get(selectedIndex).strokeLength : 0,
        clampForce: protocolsModel.count ? protocolsModel.get(selectedIndex).clampForce : 0,
        waterTemp: protocolsModel.count ? protocolsModel.get(selectedIndex).waterTemp : 0,
        cycles: protocolsModel.count ? protocolsModel.get(selectedIndex).cycles : 0,
        lastModified: protocolsModel.count ? protocolsModel.get(selectedIndex).lastModified : ""
    })

    function selectProtocol(index) {
        selectedIndex = index
        var m = protocolsModel.get(index)
        editedProtocol = ({
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
        if (!protocolsModel.count) return
        protocolsModel.setProperty(selectedIndex, "name", editedProtocol.name)
        protocolsModel.setProperty(selectedIndex, "speed", editedProtocol.speed)
        protocolsModel.setProperty(selectedIndex, "strokeLength", editedProtocol.strokeLength)
        protocolsModel.setProperty(selectedIndex, "clampForce", editedProtocol.clampForce)
        protocolsModel.setProperty(selectedIndex, "waterTemp", editedProtocol.waterTemp)
        protocolsModel.setProperty(selectedIndex, "cycles", editedProtocol.cycles)
        protocolsModel.setProperty(selectedIndex, "lastModified", "Just now")
        // also update snapshot
        selectProtocol(selectedIndex)
    }

    function duplicateProtocol() {
        protocolsModel.append({
            "name": editedProtocol.name + " (Copy)",
            "speed": editedProtocol.speed,
            "strokeLength": editedProtocol.strokeLength,
            "clampForce": editedProtocol.clampForce,
            "waterTemp": editedProtocol.waterTemp,
            "cycles": editedProtocol.cycles,
            "lastModified": "Just now"
        })
        selectProtocol(protocolsModel.count - 1)
    }

    function deleteProtocol() {
        if (protocolsModel.count <= 1) return
        protocolsModel.remove(selectedIndex)
        selectProtocol(Math.max(0, selectedIndex - 1))
    }

    function runProtocol() {
        console.log("RUN PROTOCOL:", JSON.stringify(editedProtocol))
        // Hook to ESP32 later
    }

    function calculateDistanceMeters() : real {
        // total distance ~ cycles * 2 * strokeLength(mm) -> meters
        return (editedProtocol.cycles * 2.0 * editedProtocol.strokeLength) / 1000.0
    }

    function calculateDurationMinutes() : int {
        // Rough estimate: distance / speed
        // speed is cm/s => m/s = speed/100
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
