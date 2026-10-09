import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

// Ziele: eigene und die Vorlagen, die die Plattform vorschlägt.
ThemedPage {
    id: page
    allowedOrientations: Orientation.All

    onStatusChanged: if (status === PageStatus.Active) Api.fetchGoals()

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: inhalt.height

        PullDownMenu {
            MenuItem {
                text: qsTr("Eigenes Ziel")
                onClicked: pageStack.push(Qt.resolvedUrl("GoalDialog.qml"), { ziel: ({}) })
            }
            MenuItem { text: qsTr("Aktualisieren"); onClicked: Api.fetchGoals() }
        }

        Column {
            id: inhalt
            width: parent.width

            PageHeader { title: qsTr("Meine Ziele") }

            Repeater {
                model: Api.goals
                delegate: ListItem {
                    id: zeile
                    contentHeight: Theme.itemSizeMedium
                    width: inhalt.width

                    Column {
                        x: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 2 * Theme.horizontalPageMargin

                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            color: zeile.highlighted ? palette.highlightColor : palette.primaryColor
                            text: modelData.name ? modelData.name : qsTr("Ziel")
                        }
                        Label {
                            width: parent.width
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: palette.secondaryColor
                            text: {
                                var z = modelData.distance ? modelData.distance : 0
                                var i = modelData.progress !== undefined ? modelData.progress
                                      : (modelData.current !== undefined ? modelData.current : 0)
                                var s = Math.round(i) + " / " + Math.round(z) + " km"
                                if (modelData.dateEnd) s += " · bis " + modelData.dateEnd
                                return s
                            }
                        }
                        // Der Fortschritt als Balken -- eine Zahl allein sagt
                        // auf dem Rad zu wenig.
                        Rectangle {
                            width: parent.width
                            height: Theme.paddingSmall
                            radius: height / 2
                            color: Theme.rgba(palette.secondaryColor, 0.3)
                            Rectangle {
                                height: parent.height
                                radius: parent.radius
                                color: palette.highlightColor
                                width: {
                                    var z = modelData.distance ? modelData.distance : 0
                                    var i = modelData.progress !== undefined ? modelData.progress
                                          : (modelData.current !== undefined ? modelData.current : 0)
                                    return z > 0 ? Math.min(1, i / z) * parent.width : 0
                                }
                            }
                        }
                    }

                    onClicked: pageStack.push(Qt.resolvedUrl("GoalDialog.qml"), { ziel: modelData })

                    menu: ContextMenu {
                        MenuItem {
                            text: qsTr("Löschen")
                            onClicked: zeile.remorseAction(qsTr("Ziel löschen"),
                                           function() { Api.deleteGoal(modelData.id) })
                        }
                    }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: palette.secondaryColor
                visible: Api.goals.length === 0
                text: Api.loggedIn ? qsTr("Noch kein Ziel. Über das Menü eines anlegen.")
                                   : qsTr("Nicht angemeldet")
            }

            SectionHeader {
                text: qsTr("Vorschläge")
                visible: Api.goalTemplates.length > 0
            }

            Repeater {
                model: Api.goalTemplates
                delegate: ListItem {
                    contentHeight: Theme.itemSizeSmall
                    width: inhalt.width
                    Label {
                        x: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        truncationMode: TruncationMode.Fade
                        text: (modelData.name ? modelData.name : qsTr("Vorschlag"))
                              + (modelData.distance ? " · " + Math.round(modelData.distance) + " km" : "")
                    }
                    onClicked: Api.selectGoal(modelData.id, true)
                }
            }

            Item { width: 1; height: Theme.paddingLarge }
        }
    }
}
