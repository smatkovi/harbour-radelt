import QtQuick 1.1
import com.nokia.meego 1.0

// Ziele: eigene und die Vorschläge der Plattform.
Page {
    id: page
    tools: tools

    Component.onCompleted: Api.fetchGoals()

    Header { id: header; text: qsTr("Meine Ziele") }

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

            Repeater {
                model: Api.goals
                delegate: Item {
                    width: page.width
                    height: 86
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 16
                        width: parent.width - 32
                        spacing: 4
                        Label {
                            width: parent.width
                            elide: Text.ElideRight
                            text: modelData.name ? modelData.name : qsTr("Ziel")
                        }
                        Label {
                            width: parent.width
                            font.pixelSize: 18
                            color: Farben.grau
                            text: {
                                var z = modelData.distance ? modelData.distance : 0
                                var i = modelData.progress !== undefined ? modelData.progress
                                      : (modelData.current !== undefined ? modelData.current : 0)
                                var s = Math.round(i) + " / " + Math.round(z) + " km"
                                if (modelData.dateEnd) s += " · bis " + modelData.dateEnd
                                return s
                            }
                        }
                        // Fortschritt als Balken -- eine Zahl allein sagt
                        // auf dem Rad zu wenig.
                        Rectangle {
                            width: parent.width
                            height: 6
                            radius: 3
                            color: "#3a3a3a"
                            Rectangle {
                                height: parent.height
                                radius: parent.radius
                                color: Farben.rot
                                width: {
                                    var z = modelData.distance ? modelData.distance : 0
                                    var i = modelData.progress !== undefined ? modelData.progress
                                          : (modelData.current !== undefined ? modelData.current : 0)
                                    return z > 0 ? Math.min(1, i / z) * parent.width : 0
                                }
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: bearbeiten.oeffnen(modelData)
                        onPressAndHold: {
                            Api.deleteGoal(modelData.id)
                            appWindow.showMessage(qsTr("Ziel gelöscht"))
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
                visible: Api.goals.length === 0
                text: Api.loggedIn ? qsTr("Noch kein Ziel. Über das Plus eines anlegen.")
                                   : qsTr("Nicht angemeldet")
            }

            Label {
                x: 16
                font.pixelSize: 22
                color: Farben.grau
                visible: Api.goalTemplates.length > 0
                text: qsTr("Vorschläge")
            }

            Repeater {
                model: Api.goalTemplates
                delegate: Item {
                    width: page.width
                    height: 56
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 16
                        width: parent.width - 32
                        elide: Text.ElideRight
                        text: (modelData.name ? modelData.name : qsTr("Vorschlag"))
                              + (modelData.distance ? " · " + Math.round(modelData.distance) + " km" : "")
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Api.selectGoal(modelData.id, true)
                            appWindow.showMessage(qsTr("Ziel übernommen"))
                        }
                    }
                }
            }

            Item { width: 1; height: 16 }
        }
    }

    GoalSheet { id: bearbeiten }

    ToolBarLayout {
        id: tools
        ToolIcon { iconId: "toolbar-back"; onClicked: pageStack.pop() }
        ToolIcon { iconId: "toolbar-add"; onClicked: bearbeiten.oeffnen({}) }
        ToolIcon { iconId: "toolbar-refresh"; onClicked: Api.fetchGoals() }
    }
}
