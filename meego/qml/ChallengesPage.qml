import QtQuick 1.1
import com.nokia.meego 1.0

// Aktionen ("Kampagnen"). Fahrtenbuch, Radeltage und die Orte zum Sammeln
// haengen an einer Aktion -- ohne Aktionskennung antwortet der Dienst dort
// challenge_not_found. Ziele gehen auch ohne Aktion.
Page {
    id: page
    tools: tools

    Component.onCompleted: Api.fetchChallenges()

    Header { id: header; text: qsTr("Aktionen") }

    Flickable {
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        contentHeight: inhalt.height
        clip: true

        Column {
            id: inhalt
            width: page.width
            spacing: 6

            Item { width: 1; height: 10 }
            Label { x: 16; font.pixelSize: 22; color: Farben.grau; text: qsTr("Ich mache mit") }

            Repeater {
                model: Api.myChallenges
                delegate: Item {
                    width: page.width
                    height: 72
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 16
                        width: parent.width - 32
                        Label {
                            width: parent.width
                            elide: Text.ElideRight
                            text: modelData.name ? modelData.name : qsTr("Aktion")
                        }
                        Label {
                            width: parent.width
                            font.pixelSize: 18
                            color: Farben.grau
                            text: qsTr("Tippen: heute geradelt · Halten: abmelden")
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Api.addCyclingDay(modelData.id, new Date())
                            appWindow.showMessage(qsTr("Heutiger Radeltag eingetragen"))
                        }
                        onPressAndHold: {
                            Api.leaveChallenge(modelData.id)
                            appWindow.showMessage(qsTr("Abgemeldet"))
                        }
                    }
                }
            }

            Label {
                x: 16
                width: parent.width - 32
                wrapMode: Text.WordWrap
                font.pixelSize: 18
                color: Farben.grau
                visible: Api.myChallenges.length === 0
                text: Api.loggedIn
                      ? qsTr("Du machst bei keiner Aktion mit. Erst damit zählen Ziele, "
                             + "Radeltage und das Fahrtenbuch.")
                      : qsTr("Nicht angemeldet")
            }

            Item { width: 1; height: 10 }
            Label { x: 16; font.pixelSize: 22; color: Farben.grau; text: qsTr("Offene Aktionen") }

            Repeater {
                model: Api.openChallenges
                delegate: Item {
                    width: page.width
                    height: 72
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 16
                        width: parent.width - 32
                        Label {
                            width: parent.width
                            elide: Text.ElideRight
                            text: modelData.name ? modelData.name : qsTr("Aktion")
                        }
                        Label {
                            width: parent.width
                            font.pixelSize: 18
                            color: Farben.grau
                            text: qsTr("Antippen zum Mitmachen")
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Api.joinChallenge(modelData.id)
                            appWindow.showMessage(qsTr("Angemeldet"))
                        }
                    }
                }
            }

            Label {
                x: 16
                width: parent.width - 32
                wrapMode: Text.WordWrap
                font.pixelSize: 18
                color: Farben.grau
                visible: Api.openChallenges.length === 0
                text: qsTr("Zurzeit steht keine Aktion offen.")
            }

            Item { width: 1; height: 16 }
        }
    }

    ToolBarLayout {
        id: tools
        ToolIcon { iconId: "toolbar-back"; onClicked: pageStack.pop() }
        ToolIcon { iconId: "toolbar-refresh"; onClicked: Api.fetchChallenges() }
    }
}
