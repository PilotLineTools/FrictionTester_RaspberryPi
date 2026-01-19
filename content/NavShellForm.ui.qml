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
    property alias settingsButton: settingsButton
    property alias historyButton: historyButton
    property alias aboutButton: aboutButton

    // Property to receive SerialController from parent (Python backend)
    property var serialController: null

    // ✅ NEW: Nav interactivity control (set from NavShell.qml)
    property bool navEnabled: true
    property real navOpacity: navEnabled ? 1.0 : 0.35

    // NAV
    Rectangle {
        id: nav
        width: Constants.sidebarWidth
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        color: Constants.bgCard

        // ✅ Make entire sidebar obey enabled/opacity
        enabled: root.navEnabled
        opacity: root.navOpacity

        ButtonGroup {
            id: navGroup
            exclusive: true
        }

        Column {
            anchors.fill: parent
            anchors.margins: 16
            anchors.rightMargin: 156
            spacing: constants.mediumSpacing

            Button {
                id: homeButton
                text: qsTr("Home")
                checkable: true
                checked: true
                ButtonGroup.group: navGroup
                width: Constants.mediumButtonWidth
                height: Constants.mediumButtonHeight
                enabled: root.navEnabled

                background: Rectangle {
                    radius: 14
                    color: homeButton.checked ? Constants.accentPrimary : Constants.bgSurface
                    border.width: homeButton.checked ? 2 : 1
                    border.color: homeButton.checked ? Constants.accentSky : Constants.borderDefault
                }
            }

            Button {
                id: protocolsButton
                text: qsTr("Protocols")
                checkable: true
                ButtonGroup.group: navGroup
                width: Constants.mediumButtonWidth
                height: Constants.mediumButtonHeight
                enabled: root.navEnabled

                background: Rectangle {
                    radius: 14
                    color: protocolsButton.checked ? Constants.accentPrimary : Constants.bgSurface
                    border.width: protocolsButton.checked ? 2 : 1
                    border.color: protocolsButton.checked ? Constants.accentSky : Constants.borderDefault
                }
            }

            Button {
                id: historyButton
                text: qsTr("History")
                checkable: true
                ButtonGroup.group: navGroup
                width: Constants.mediumButtonWidth
                height: Constants.mediumButtonHeight
                enabled: root.navEnabled

                background: Rectangle {
                    radius: 14
                    color: historyButton.checked ? Constants.accentPrimary : Constants.bgSurface
                    border.width: historyButton.checked ? 2 : 1
                    border.color: historyButton.checked ? Constants.accentSky : Constants.borderDefault
                }
            }

            Button {
                id: settingsButton
                text: qsTr("Settings")
                checkable: true
                ButtonGroup.group: navGroup
                width: Constants.mediumButtonWidth
                height: Constants.mediumButtonHeight
                enabled: root.navEnabled

                background: Rectangle {
                    radius: 14
                    color: settingsButton.checked ? Constants.accentPrimary : Constants.bgSurface
                    border.width: settingsButton.checked ? 2 : 1
                    border.color: settingsButton.checked ? Constants.accentSky : Constants.borderDefault
                }
            }

            Button {
                id: aboutButton
                text: qsTr("About")
                checkable: true
                ButtonGroup.group: navGroup
                width: Constants.mediumButtonWidth
                height: Constants.mediumButtonHeight
                enabled: root.navEnabled

                background: Rectangle {
                    radius: 14
                    color: aboutButton.checked ? Constants.accentPrimary : Constants.bgSurface
                    border.width: aboutButton.checked ? 2 : 1
                    border.color: aboutButton.checked ? Constants.accentSky : Constants.borderDefault
                }
            }
        }
    }

    // CONTENT
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
