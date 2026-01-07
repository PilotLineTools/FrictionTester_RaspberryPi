import QtQuick 6.5
import QtQuick.Controls 6.5
import QtQml
import PilotLine_FrictionTester

SettingsScreenForm {
    id: view

    // passed in from NavShell
    property QtObject appMachine

    Component.onCompleted: {
        console.log("✅ SettingsScreen WRAPPER LOADED", appMachine)
    }

}
