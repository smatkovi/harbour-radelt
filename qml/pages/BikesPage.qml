import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

// Die Räder des Kontos. Die Plattform führt genau ein Hauptrad, auf das
// jede Fahrt fällt, die kein eigenes nennt; ein Rad mit Fahrten lässt sich
// nicht löschen, nur stilllegen -- beides sagt die Antwort des Servers, und
// die Knöpfe richten sich danach.
ThemedPage {
    allowedOrientations: Orientation.All

    onStatusChanged: if (status === PageStatus.Active) Api.refresh()

    SilicaListView {
        id: list
        anchors.fill: parent
        model: Api.bikeList

        header: PageHeader { title: qsTr("Meine Räder") }

        PullDownMenu {
            MenuItem {
                text: qsTr("Rad hinzufügen")
                onClicked: pageStack.push(Qt.resolvedUrl("BikeDialog.qml"), { bike: ({}) })
            }
        }

        delegate: ListItem {
            id: item
            contentHeight: Theme.itemSizeMedium
            width: list.width

            Column {
                x: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 2 * Theme.horizontalPageMargin

                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    color: item.highlighted ? palette.highlightColor : palette.primaryColor
                    text: modelData.name ? modelData.name : qsTr("Rad")
                }
                Label {
                    width: parent.width
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: palette.secondaryColor
                    text: (modelData.isMain ? qsTr("Hauptrad") : qsTr("Weiteres Rad"))
                          + (modelData.isEbike ? " · " + qsTr("E-Bike") : "")
                          + (modelData.isActive === false ? " · " + qsTr("stillgelegt") : "")
                }
            }

            onClicked: pageStack.push(Qt.resolvedUrl("BikeDialog.qml"), { bike: modelData })

            menu: ContextMenu {
                MenuItem {
                    visible: !modelData.isMain
                    text: qsTr("Als Hauptrad")
                    onClicked: {
                        var b = {}
                        for (var k in modelData) b[k] = modelData[k]
                        b.isMain = true
                        Api.saveBike(b)
                    }
                }
                MenuItem {
                    visible: modelData.canBeDeleted === true
                    text: qsTr("Löschen")
                    onClicked: item.remorseAction(qsTr("Rad löschen"),
                                                  function() { Api.deleteBike(modelData.id) })
                }
            }
        }

        ViewPlaceholder {
            enabled: list.count === 0
            text: Api.loggedIn ? qsTr("Keine Räder") : qsTr("Nicht angemeldet")
            hintText: Api.loggedIn ? qsTr("Über das Menü ein Rad anlegen") : ""
        }

        VerticalScrollDecorator { }
    }
}
