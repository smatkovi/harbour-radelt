import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

// Für wen gefahren wird: die Organisationen, denen die Kilometer
// zugeschrieben werden. Der Dienst kennt nur die ganze Liste — wer eine
// dazunimmt, schickt alle mit; das macht der Kern.
ThemedPage {
    id: page

    allowedOrientations: Orientation.All

    // Genau diese fünf nimmt der Dienst; alles andere lehnt er mit
    // wrong_organisation_category ab (am Server nachgemessen).
    readonly property var arten: [
        { kennung: "", name: qsTr("alle Arten") },
        { kennung: "MUNICIPALITY", name: qsTr("Gemeinde") },
        { kennung: "WORKPLACE", name: qsTr("Betrieb") },
        { kennung: "SCHOOL", name: qsTr("Schule") },
        { kennung: "ASSOCIATION", name: qsTr("Verein") },
        { kennung: "UNIVERSITY", name: qsTr("Universität") }]

    property string art: ""

    function suchen() {
        Api.searchOrganisations(suchfeld.text, page.art)
    }

    onStatusChanged: if (status === PageStatus.Active) Api.fetchCommunity()

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: inhalt.height

        PullDownMenu {
            MenuItem { text: qsTr("Aktualisieren"); onClicked: Api.fetchCommunity() }
        }

        Column {
            id: inhalt
            width: parent.width

            PageHeader {
                title: qsTr("Für wen ich fahre")
                description: Api.organisations.length > 0
                             ? qsTr("%n Organisation(en)", "", Api.organisations.length)
                             : qsTr("noch niemand")
            }

            Repeater {
                model: Api.organisations
                delegate: ListItem {
                    id: meine
                    contentHeight: Theme.itemSizeMedium
                    width: inhalt.width

                    Column {
                        x: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            color: meine.highlighted ? palette.highlightColor : palette.primaryColor
                            text: modelData.name ? modelData.name : qsTr("Organisation")
                        }
                        Label {
                            width: parent.width
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: palette.secondaryColor
                            text: page.artName(modelData.type)
                        }
                    }

                    menu: ContextMenu {
                        MenuItem {
                            text: qsTr("Nicht mehr für diese fahren")
                            onClicked: meine.remorseAction(qsTr("Entfernen"),
                                           function() { Api.removeOrganisation(modelData.id) })
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
                visible: Api.organisations.length === 0
                text: Api.loggedIn
                      ? qsTr("Du fährst noch für niemanden. Unten suchen und dazunehmen – "
                             + "dann zählen deine Kilometer auch dort mit.")
                      : qsTr("Nicht angemeldet")
            }

            SectionHeader { text: qsTr("Dazunehmen") }

            SearchField {
                id: suchfeld
                width: parent.width
                placeholderText: qsTr("Name der Organisation")
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: page.suchen()
            }

            ComboBox {
                width: parent.width
                label: qsTr("Art")
                currentIndex: 0
                menu: ContextMenu {
                    Repeater {
                        model: page.arten
                        delegate: MenuItem {
                            text: modelData.name
                            onClicked: {
                                page.art = modelData.kennung
                                page.suchen()
                            }
                        }
                    }
                }
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Suchen")
                enabled: !Api.searchingOrganisations
                onClicked: page.suchen()
            }

            Item { width: 1; height: Theme.paddingMedium }

            Repeater {
                model: Api.foundOrganisations
                delegate: ListItem {
                    id: treffer
                    contentHeight: Theme.itemSizeMedium
                    width: inhalt.width
                    enabled: !Api.ridesFor(modelData.id)

                    Column {
                        x: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            color: treffer.highlighted ? palette.highlightColor : palette.primaryColor
                            opacity: treffer.enabled ? 1 : 0.4
                            text: modelData.name ? modelData.name : qsTr("Organisation")
                        }
                        Label {
                            width: parent.width
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: palette.secondaryColor
                            text: page.artName(modelData.type)
                                  + (Api.ridesFor(modelData.id)
                                     ? " · " + qsTr("schon dabei")
                                     : " · " + qsTr("antippen zum Dazunehmen"))
                        }
                    }

                    onClicked: {
                        Api.addOrganisation(modelData.id)
                        hinweis.zeige(qsTr("Dazugenommen"))
                    }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: palette.secondaryColor
                visible: Api.foundOrganisations.length === 0 && !Api.searchingOrganisations
                text: qsTr("Nach einem Namen suchen oder nur eine Art wählen.")
            }

            Item { width: 1; height: Theme.paddingLarge }
        }

        VerticalScrollDecorator { }
    }

    function artName(kennung) {
        for (var i = 0; i < arten.length; ++i)
            if (arten[i].kennung === kennung)
                return arten[i].name
        return kennung ? kennung : ""
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
