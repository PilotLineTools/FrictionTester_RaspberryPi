import QtQuick
import QtQuick.Controls
import QtQml
import PilotLine_FrictionTester

ProtocolsScreenForm {
    id: view

    width: Constants.width
    height: Constants.height

    // passed in from NavShell
    property QtObject appMachine

    // Protocol data model
    ListModel {
        id: protocolsModel
        ListElement {
            name: "Standard Catheter Test"
            speed: 1.5
            strokeLength: 80
            clampForce: 250
            waterTemp: 37
            cycles: 100
            lastModified: "2025-01-08 09:30"
        }
        ListElement {
            name: "High Temperature Validation"
            speed: 0.8
            strokeLength: 100
            clampForce: 300
            waterTemp: 45
            cycles: 200
            lastModified: "2025-01-07 14:15"
        }
        ListElement {
            name: "Low Force Profile"
            speed: 1.0
            strokeLength: 60
            clampForce: 150
            waterTemp: 25
            cycles: 50
            lastModified: "2025-01-06 11:22"
        }
        ListElement {
            name: "Endurance Test"
            speed: 2.0
            strokeLength: 90
            clampForce: 280
            waterTemp: 37
            cycles: 1000
            lastModified: "2025-01-05 16:45"
        }
    }

    // Current selected/edited protocol
    property var selectedProtocol: protocolsModel.count > 0 ? protocolsModel.get(0) : null
    property var editedProtocol: QtObject {
        property string name: selectedProtocol ? selectedProtocol.name : ""
        property real speed: selectedProtocol ? selectedProtocol.speed : 1.5
        property int strokeLength: selectedProtocol ? selectedProtocol.strokeLength : 80
        property int clampForce: selectedProtocol ? selectedProtocol.clampForce : 250
        property int waterTemp: selectedProtocol ? selectedProtocol.waterTemp : 37
        property int cycles: selectedProtocol ? selectedProtocol.cycles : 100
    }

    // Update edited protocol when selection changes
    onSelectedProtocolChanged: {
        if (selectedProtocol) {
            editedProtocol.name = selectedProtocol.name
            editedProtocol.speed = selectedProtocol.speed
            editedProtocol.strokeLength = selectedProtocol.strokeLength
            editedProtocol.clampForce = selectedProtocol.clampForce
            editedProtocol.waterTemp = selectedProtocol.waterTemp
            editedProtocol.cycles = selectedProtocol.cycles
        }
    }

    // Calculate estimated duration (minutes)
    function calculateDuration() {
        if (!editedProtocol) return 0
        return Math.floor((editedProtocol.cycles * editedProtocol.strokeLength) / (editedProtocol.speed * 60))
    }

    // Calculate total distance (meters)
    function calculateDistance() {
        if (!editedProtocol) return 0
        return ((editedProtocol.cycles * editedProtocol.strokeLength) / 1000).toFixed(1)
    }

    // Handle protocol selection
    function selectProtocol(index) {
        if (index >= 0 && index < protocolsModel.count) {
            selectedProtocol = protocolsModel.get(index)
        }
    }

    // Handle field changes
    function updateField(field, value) {
        editedProtocol[field] = value
    }

    // Handle run protocol
    function runProtocol() {
        console.log("Running protocol:", editedProtocol.name)
        // TODO: Implement protocol execution
        if (appMachine) {
            // Send protocol parameters to ESP32
        }
    }

    Component.onCompleted: {
        console.log("✅ ProtocolsScreen WRAPPER LOADED", appMachine)
        if (protocolsModel.count > 0) {
            selectedProtocol = protocolsModel.get(0)
        }
    }
}
