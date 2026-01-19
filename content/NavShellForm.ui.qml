import QtQuick
import QtQuick.Controls
import PilotLine_FrictionTester

Rectangle {
    id: root
    width: Constants.width
    height: Constants.height
    color: Constants.bgPrimary

    property alias stack: stack
    property alias homeButton: homeButton
    property alias protocolsButton: protocolsButton
    property alias historyButton: historyButton
    property alias settingsButton: settingsButton
    property alias aboutButton: aboutButton

    property bool navEnabled: true
    property real navOpacity: navEnabled ? 1.0 : 0.35

    // ======================
    // NAV SIDEBAR
    // ======================
    Rectangle {
        id: nav
        width: Constants.sidebarWidth
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        color: Constants.bgCard
        enabled: root.navEnabled
        opacity: root.navOpacity

        ButtonGroup {
            id: navGroup
            exclusive: true
        }

        Column {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 0

            function navButtonHeight() {
                return height / 5
            }

            // ===== HOME =====
            Button {
                id: homeButton
                checkable: true
                checked: true
                ButtonGroup.group: navGroup
                width: 150
                height: parent.navButtonHeight()
                enabled: root.navEnabled

                background: Rectangle {
                    radius: Constants.radiusLG
                    color: homeButton.checked ? Constants.accentPrimary : Constants.bgSurface
                    border.width: homeButton.checked ? 2 : 1
                    border.color: homeButton.checked ? Constants.accentSky : Constants.borderDefault
                }

                contentItem: Text {
                    text: "Home"
                    anchors.centerIn: parent
                    color: Constants.textPrimary
                    font.pixelSize: Constants.fontLG
                    font.bold: true
                }
            }

            // ===== PROTOCOLS =====
            Button {
                id: protocolsButton
                checkable: true
                ButtonGroup.group: navGroup
                width: 150
                height: parent.navButtonHeight()
                enabled: root.navEnabled

                background: Rectangle {
                    radius: Constants.radiusLG
                    color: protocolsButton.checked ? Constants.accentPrimary : Constants.bgSurface
                    border.width: protocolsButton.checked ? 2 : 1
                    border.color: protocolsButton.checked ? Constants.accentSky : Constants.borderDefault
                }

                contentItem: Text {
                    text: "Protocols"
                    anchors.centerIn: parent
                    color: Constants.textPrimary
                    font.pixelSize: Constants.fontLG
                    font.bold: true
                }
            }

            // ===== HISTORY =====
            Button {
                id: historyButton
                checkable: true
                ButtonGroup.group: navGroup
                width: 150
                height: parent.navButtonHeight()
                enabled: root.navEnabled

                background: Rectangle {
                    radius: Constants.radiusLG
                    color: historyButton.checked ? Constants.accentPrimary : Constants.bgSurface
                    border.width: historyButton.checked ? 2 : 1
                    border.color: historyButton.checked ? Constants.accentSky : Constants.borderDefault
                }

                contentItem: Text {
                    text: "History"
                    anchors.centerIn: parent
                    color: Constants.textPrimary
                    font.pixelSize: Constants.fontLG
                    font.bold: true
                }
            }

            // ===== SETTINGS =====
            Button {
                id: settingsButton
                checkable: true
                ButtonGroup.group: navGroup
                width: 150
                height: parent.navButtonHeight()
                enabled: root.navEnabled

                background: Rectangle {
                    radius: Constants.radiusLG
                    color: settingsButton.checked ? Constants.accentPrimary : Constants.bgSurface
                    border.width: settingsButton.checked ? 2 : 1
                    border.color: settingsButton.checked ? Constants.accentSky : Constants.borderDefault
                }

                contentItem: Text {
                    text: "Settings"
                    anchors.centerIn: parent
                    color: Constants.textPrimary
                    font.pixelSize: Constants.fontLG
                    font.bold: true
                }
            }

            // ===== ABOUT =====
            Button {
                id: aboutButton
                checkable: true
                ButtonGroup.group: navGroup
                width: 150
                height: parent.navButtonHeight()
                enabled: root.navEnabled

                background: Rectangle {
                    radius: Constants.radiusLG
                    color: aboutButton.checked ? Constants.accentPrimary : Constants.bgSurface
                    border.width: aboutButton.checked ? 2 : 1
                    border.color: aboutButton.checked ? Constants.accentSky : Constants.borderDefault
                }

                contentItem: Text {
                    text: "About"
                    anchors.centerIn: parent
                    color: Constants.textPrimary
                    font.pixelSize: Constants.fontLG
                    font.bold: true
                }
            }
        }
    }

    // ======================
    // MAIN CONTENT
    // ======================
    StackView {
        id: stack
        anchors.left: nav.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        replaceEnter: null
        replaceExit: null
    }
}
