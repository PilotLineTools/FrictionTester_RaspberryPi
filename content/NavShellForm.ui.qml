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
    property alias calibrationButton: calibrationButton
    property alias aboutButton: aboutButton
    
    // Property to receive SerialController from parent (Python backend)
    property var serialController: null


    // NAV
    Rectangle {
        id: nav
        width: 117
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        color: Constants.bgCard

        ButtonGroup {
            id: navGroup
            exclusive: true
        }

        Column {
            anchors.fill: parent
            anchors.margins: 16
            anchors.rightMargin: 156
            spacing: 12

            Button {
                id: homeButton
                text: qsTr("Home")
                checkable: true
                checked: true
                ButtonGroup.group: navGroup
                width: 80
                height: 80

                background: Rectangle {
                    radius: 14

                    color: homeButton.checked ? Constants.accentPrimary // selected
                                              : Constants.bgSurface // default

                    border.width: homeButton.checked ? 2 : 1
                    border.color: homeButton.checked ? Constants.accentSky : Constants.borderDefault
                }
            }
            Button {
                id: protocolsButton
                text: qsTr("Protocols")
                checkable: true
                ButtonGroup.group: navGroup
                width: 80
                height: 80

                background: Rectangle {
                    radius: 14

                    color: protocolsButton.checked ? Constants.accentPrimary // selected
                                                   : Constants.bgSurface // default

                    border.width: protocolsButton.checked ? 2 : 1
                    border.color: protocolsButton.checked ? Constants.accentSky : Constants.borderDefault
                }
            }
            Button {
                id: settingsButton
                text: qsTr("Settings")
                checkable: true
                ButtonGroup.group: navGroup
                width: 80
                height: 80

                background: Rectangle {
                    radius: 14

                    color: settingsButton.checked ? Constants.accentPrimary // selected
                                                  : Constants.bgSurface // default

                    border.width: settingsButton.checked ? 2 : 1
                    border.color: settingsButton.checked ? Constants.accentSky : Constants.borderDefault
                }
            }
            Button {
                id: calibrationButton
                text: qsTr("Calibration")
                checkable: true
                ButtonGroup.group: navGroup
                width: 80
                height: 80

                background: Rectangle {
                    radius: 14

                    color: calibrationButton.checked ? Constants.accentPrimary // selected
                                                     : Constants.bgSurface // default

                    border.width: calibrationButton.checked ? 2 : 1
                    border.color: calibrationButton.checked ? Constants.accentSky : Constants.borderDefault
                }
            }
            Button {
                id: aboutButton
                text: qsTr("About")
                checkable: true
                ButtonGroup.group: navGroup
                width: 80
                height: 80

                background: Rectangle {
                    radius: 14

                    color: aboutButton.checked ? Constants.accentPrimary // selected
                                               : Constants.bgSurface // default

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
