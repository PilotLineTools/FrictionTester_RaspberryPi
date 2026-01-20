import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PilotLine_FrictionTester

Rectangle {
    id: root
    anchors.fill: parent
    color: Constants.bgPrimary

    // passed in from NavShell
    property var backend

    // navigation signals (NavShell handles actual routing)
    signal backRequested()
    signal runChosen(var runObj)

    // UI state
    property bool busy: false
    property string loadError: ""
    property int selectedIndex: -1

    // lightweight toast/banner feedback
    property string toastText: ""
    property bool toastVisible: false

    ListModel { id: runsModel }

    function showToast(msg) {
        toastText = msg
        toastVisible = true
        toastTimer.restart()
    }

    function loadRuns() {
        if (!backend) {
            console.warn("HistoryScreen: backend is null")
            return
        }

        busy = true
        loadError = ""
        runsModel.clear()
        selectedIndex = -1

        backend.request("GET", "/runs", null, function(ok, status, data) {
            busy = false

            if (!ok || !data) {
                loadError = "Failed to load run history"
                console.error("GET /runs failed:", status, data)
                return
            }

            for (var i = 0; i < data.length; i++) {
                // expecting api_list_runs -> RunOut shape:
                // { id, protocol_id, protocol_name, status, started_at, finished_at, run_dir, notes }
                runsModel.append({
                    id: data[i].id,
                    protocol_id: data[i].protocol_id,
                    protocol_name: data[i].protocol_name || ("Protocol " + data[i].protocol_id),
                    status: (data[i].status || "").toUpperCase(),
                    started_at: data[i].started_at || "",
                    finished_at: data[i].finished_at || "",
                    run_dir: data[i].run_dir || "",
                    notes: data[i].notes || ""
                })
            }

            selectedIndex = (runsModel.count > 0) ? 0 : -1
        })
    }

    function statusColor(s) {
        // keep it simple; tweak later to match your palette
        if (s === "COMPLETED") return "#22C55E"   // green
        if (s === "ABORTED")   return "#F59E0B"   // amber
        if (s === "FAILED")    return "#DC2626"   // red
        if (s === "RUNNING")   return "#3B82F6"   // blue
        if (s === "PAUSED")    return "#A78BFA"   // purple
        return Constants.textSecondary
    }

    function exportRunCsv(runId) {
        if (!backend) return
        showToast("Exporting CSV…")

        // returns { format:"csv", path:"/path/to/export.csv" } when mode=file
        backend.request("GET", "/runs/" + runId + "/export?fmt=csv&mode=file", null, function(ok, status, data) {
            if (!ok || !data) {
                console.error("Export failed:", status, data)
                showToast("Export failed")
                return
            }
            showToast("Exported: " + (data.path || "export.csv"))
        })
    }

    function deleteRun(runId) {
        if (!backend) return
        busy = true
        backend.request("DELETE", "/runs/" + runId + "?delete_files=false", null, function(ok, status, data) {
            busy = false
            if (!ok) {
                console.error("DELETE /runs failed:", status, data)
                showToast("Delete failed")
                return
            }
            showToast("Run deleted")
            loadRuns()
        })
    }

    Component.onCompleted: loadRuns()

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
                text: "Back"
                Layout.preferredWidth: 120
                onClicked: root.backRequested()

                background: Rectangle { radius: 10; color: "transparent" }
                contentItem: Text {
                    text: parent.text
                    color: Constants.textPrimary
                    font.pixelSize: 16
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "Run History"
                color: Constants.textPrimary
                font.pixelSize: 22
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "Refresh"
                Layout.preferredWidth: 120
                enabled: !busy
                onClicked: loadRuns()
                background: Rectangle { radius: 10; color: Constants.bgSurface; border.color: Constants.borderDefault; border.width: 1 }
                contentItem: Text {
                    text: "Refresh"
                    color: Constants.textPrimary
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
            Button {
                text: "Retry"
                onClicked: loadRuns()
            }
        }

        // Empty state
        Column {
            anchors.centerIn: parent
            spacing: 8
            visible: !busy && loadError === "" && runsModel.count === 0

            Text {
                text: "No runs yet"
                color: Constants.textPrimary
                font.pixelSize: 22
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                text: "Completed/aborted tests will appear here."
                color: Constants.textSecondary
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // List
        ListView {
            id: list
            anchors.fill: parent
            anchors.margins: 14
            spacing: 14
            clip: true
            model: runsModel
            visible: !busy && loadError === "" && runsModel.count > 0

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
                        spacing: 10

                        Text {
                            text: protocol_name
                            color: Constants.textPrimary
                            font.pixelSize: 18
                            font.bold: true
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        // Status badge
                        Rectangle {
                            radius: 10
                            implicitHeight: 28
                            implicitWidth: 110
                            color: Constants.bgSurface
                            border.color: Constants.borderDefault
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 8

                                Rectangle {
                                    width: 10
                                    height: 10
                                    radius: 5
                                    color: root.statusColor(status)
                                }

                                Text {
                                    text: status
                                    color: Constants.textPrimary
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 18

                        ColumnLayout {
                            Text { text: "Started:"; color: Constants.textSecondary; font.pixelSize: 12 }
                            Text { text: started_at !== "" ? started_at : "--"; color: Constants.textPrimary; font.pixelSize: 14 }
                        }

                        ColumnLayout {
                            Text { text: "Finished:"; color: Constants.textSecondary; font.pixelSize: 12 }
                            Text { text: finished_at !== "" ? finished_at : "--"; color: Constants.textPrimary; font.pixelSize: 14 }
                        }

                        Item { Layout.fillWidth: true }

                        // Quick export options
                        Button {
                            text: "CSV"
                            enabled: !busy
                            onClicked: root.exportRunCsv(id)
                            background: Rectangle { radius: 10; color: Constants.bgSurface; border.color: Constants.borderDefault; border.width: 1 }
                            contentItem: Text { text: "CSV"; color: Constants.textPrimary; font.pixelSize: 14; font.bold: true }
                        }

                        // Trash
                        Button {
                            text: "🗑"
                            enabled: !busy
                            onClicked: root.deleteRun(id)
                            background: Rectangle {
                                radius: 10
                                color: Qt.rgba(0.87, 0.13, 0.13, 0.30)
                                border.color: "#DC2626"
                                border.width: 1
                            }
                            contentItem: Text {
                                text: "🗑"
                                color: "#DC2626"
                                font.pixelSize: 14
                            }
                        }
                    }
                }
            }
        }
    }

    // ---------------------------
    // Bottom CTA
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
            color: (root.selectedIndex >= 0 && !busy) ? Constants.accentPrimary : Constants.bgSurface
            border.color: Constants.borderDefault
            border.width: 1

            MouseArea {
                anchors.fill: parent
                enabled: (root.selectedIndex >= 0 && !busy)
                onClicked: {
                    var r = runsModel.get(root.selectedIndex)
                    root.runChosen({
                        id: r.id,
                        protocol_id: r.protocol_id,
                        protocol_name: r.protocol_name,
                        status: r.status,
                        started_at: r.started_at,
                        finished_at: r.finished_at,
                        run_dir: r.run_dir,
                        notes: r.notes
                    })
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    text: "📈"
                    color: (root.selectedIndex >= 0 && !busy) ? "white" : Constants.textSecondary
                    font.pixelSize: 18
                }

                Text {
                    text: "View Run"
                    color: (root.selectedIndex >= 0 && !busy) ? "white" : Constants.textSecondary
                    font.pixelSize: 18
                    font.bold: true
                }
            }
        }
    }

    // ---------------------------
    // Toast
    // ---------------------------
    Rectangle {
        id: toast
        visible: root.toastVisible
        opacity: visible ? 1 : 0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: bottomBar.top
        anchors.bottomMargin: 10
        radius: 12
        color: Constants.bgCard
        border.color: Constants.borderDefault
        border.width: 1
        width: Math.min(parent.width - 40, 520)
        height: 44

        Text {
            anchors.centerIn: parent
            text: root.toastText
            color: Constants.textPrimary
            font.pixelSize: 14
            elide: Text.ElideRight
            width: parent.width - 24
            horizontalAlignment: Text.AlignHCenter
        }

        Timer {
            id: toastTimer
            interval: 1400
            onTriggered: root.toastVisible = false
        }
    }
}
