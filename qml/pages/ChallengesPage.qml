import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

// Aktionen ("Kampagnen"). Fahrtenbuch, Radeltage und die Orte zum Sammeln
// hängen an einer Aktion — ohne Aktionskennung antwortet der Dienst dort
// mit challenge_not_found. Ziele gehen auch ohne Aktion.
ThemedPage {
    id: page

    allowedOrientations: Orientation.All

    onStatusChanged: if (status === PageStatus.Active) Api.fetchChallenges()

    function heuteGeradelt(id) {
        Api.addCyclingDay(id, new Date())
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: inhalt.height

        PullDownMenu {
            MenuItem { text: qsTr("Aktualisieren"); onClicked: Api.fetchChallenges() }
        }

        Column {
            id: inhalt
            width: parent.width

            PageHeader { title: qsTr("Aktionen") }

            SectionHeader { text: qsTr("Ich mache mit") }

            Repeater {
                model: Api.myChallenges
                delegate: ListItem {
                    id: meins
                    contentHeight: Theme.itemSizeMedium
                    width: inhalt.width

                    Column {
                        x: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            color: meins.highlighted ? palette.highlightColor : palette.primaryColor
                            text: modelData.name ? modelData.name : qsTr("Aktion")
                        }
                        Label {
                            width: parent.width
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: palette.secondaryColor
                            text: {
                                var von = modelData.dateStart || modelData.start || ""
                                var bis = modelData.dateEnd || modelData.end || ""
                                return von && bis ? von + " – " + bis : qsTr("läuft")
                            }
                        }
                    }

                    menu: ContextMenu {
                        MenuItem {
                            text: qsTr("Ich bin heute geradelt")
                            onClicked: {
                                page.heuteGeradelt(modelData.id)
                                hinweis.zeige(qsTr("Heutiger Radeltag eingetragen"))
                            }
                        }
                        MenuItem {
                            text: qsTr("Abmelden")
                            onClicked: meins.remorseAction(qsTr("Von der Aktion abmelden"),
                                           function() { Api.leaveChallenge(modelData.id) })
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
                visible: Api.myChallenges.length === 0
                text: Api.loggedIn
                      ? qsTr("Du machst bei keiner Aktion mit. Erst damit gibt es "
                             + "Radeltage, ein Fahrtenbuch und Orte zum Sammeln.")
                      : qsTr("Nicht angemeldet")
            }

            SectionHeader { text: qsTr("Offene Aktionen") }

            Repeater {
                model: Api.openChallenges
                delegate: ListItem {
                    contentHeight: Theme.itemSizeMedium
                    width: inhalt.width

                    Column {
                        x: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: modelData.name ? modelData.name : qsTr("Aktion")
                        }
                        Label {
                            width: parent.width
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: palette.secondaryColor
                            text: qsTr("Antippen zum Mitmachen")
                        }
                    }

                    onClicked: {
                        Api.joinChallenge(modelData.id)
                        hinweis.zeige(qsTr("Angemeldet"))
                    }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: palette.secondaryColor
                visible: Api.openChallenges.length === 0
                text: qsTr("Zurzeit steht keine Aktion offen.")
            }

            Item { width: 1; height: Theme.paddingLarge }
        }
    }

    Label {
        id: hinweis
        function zeige(t) { text = t; visible = true; weg.restart() }
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.paddingLarge
        anchors.horizontalCenter: parent.horizontalCenter
        color: palette.highlightColor
        visible: false
        Timer { id: weg; interval: 3000; onTriggered: hinweis.visible = false }
    }
}
