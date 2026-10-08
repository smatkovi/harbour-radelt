import QtQuick 1.1
import com.nokia.meego 1.0

Page {
    id: page
    tools: mainTools

    Header { id: header; text: qsTr("Österreich radelt") }

    Row {
        id: numbers
        anchors.top: header.bottom
        anchors.topMargin: 16
        width: parent.width

        BigNumber {
            width: parent.width / 2
            value: Format.kilometres(Rides.todayDistance)
            unit: qsTr("km heute")
        }
        BigNumber {
            width: parent.width / 2
            value: Format.kilometres(Rides.seasonDistance)
            unit: qsTr("km in der Saison")
        }
    }

    Button {
        id: recordButton
        anchors.top: numbers.bottom
        anchors.topMargin: 16
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 48
        text: Recorder.recording ? qsTr("Aufzeichnung ansehen") : qsTr("Fahrt aufzeichnen")
        onClicked: pageStack.push(Qt.resolvedUrl("RecordPage.qml"))
    }

    Label {
        id: listHeading
        anchors.top: recordButton.bottom
        anchors.topMargin: 16
        x: 16
        font.pixelSize: 22
        color: "#8c8c8c"
        text: qsTr("Meine Fahrten")
    }

    ListView {
        id: list
        anchors.top: listHeading.bottom
        anchors.topMargin: 8
        anchors.bottom: parent.bottom
        width: parent.width
        clip: true
        model: Rides

        delegate: Item {
            width: list.width
            height: 72

            Column {
                anchors.verticalCenter: parent.verticalCenter
                x: 16
                width: parent.width - 32

                Label {
                    width: parent.width
                    elide: Text.ElideRight
                    text: title.length > 0 ? title : Format.dayAndTime(start)
                }
                Label {
                    width: parent.width
                    font.pixelSize: 20
                    color: "#8c8c8c"
                    elide: Text.ElideRight
                    text: Format.kilometres(distance) + " km · "
                          + Format.duration(movingSeconds > 0 ? movingSeconds : totalSeconds)
                          + (uploaded ? "" : " · " + qsTr("nicht übertragen"))
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: pageStack.push(Qt.resolvedUrl("RidePage.qml"), { rideId: rideId })
            }
        }
    }

    Label {
        anchors.centerIn: list
        width: parent.width - 64
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        color: "#8c8c8c"
        visible: list.count === 0
        text: qsTr("Noch keine Fahrt. Mit „Fahrt aufzeichnen“ anfangen oder im Menü eine Fahrt eintragen.")
    }

    ScrollDecorator { flickableItem: list }

    ToolBarLayout {
        id: mainTools

        ToolIcon {
            iconId: "toolbar-view-menu"
            onClicked: mainMenu.open()
        }
    }

    Menu {
        id: mainMenu

        MenuLayout {
            MenuItem {
                text: qsTr("Fahrt eintragen")
                onClicked: pageStack.push(Qt.resolvedUrl("ManualRidePage.qml"))
            }
            MenuItem {
                text: qsTr("Übertragen")
                enabled: Api.loggedIn && Rides.pendingCount > 0
                onClicked: Api.uploadPending()
            }
            MenuItem {
                text: Api.loggedIn ? qsTr("Abmelden") : qsTr("Anmelden")
                onClicked: {
                    if (Api.loggedIn)
                        Api.logout()
                    else
                        pageStack.push(Qt.resolvedUrl("LoginPage.qml"))
                }
            }
            MenuItem {
                text: qsTr("Einstellungen")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
        }
    }
}
