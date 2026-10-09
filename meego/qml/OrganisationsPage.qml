import QtQuick 1.1
import com.nokia.meego 1.0

// Fuer wen gefahren wird: die Organisationen, denen die Kilometer
// zugeschrieben werden. Der Dienst kennt nur die ganze Liste -- wer eine
// dazunimmt, schickt alle mit; das macht der Kern.
Page {
    id: page
    tools: werkzeuge

    // Genau diese fuenf nimmt der Dienst; alles andere lehnt er ab.
    property variant artKennungen: ["", "MUNICIPALITY", "WORKPLACE", "SCHOOL",
                                    "ASSOCIATION", "UNIVERSITY"]
    property variant artNamen: [qsTr("alle Arten"), qsTr("Gemeinde"),
                                qsTr("Betrieb"), qsTr("Schule"),
                                qsTr("Verein"), qsTr("Universität")]
    property int artIndex: 0

    function artName(kennung) {
        for (var i = 0; i < artKennungen.length; ++i)
            if (artKennungen[i] === kennung)
                return artNamen[i]
        return kennung ? kennung : ""
    }

    function suchen() {
        Api.searchOrganisations(suchfeld.text, artKennungen[artIndex])
    }

    Component.onCompleted: Api.fetchCommunity()

    Header { id: kopf; text: qsTr("Für wen ich fahre") }

    Flickable {
        anchors.top: kopf.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        contentHeight: inhalt.height
        clip: true

        Column {
            id: inhalt
            width: page.width
            spacing: 6

            Item { width: 1; height: 8 }

            Label {
                x: 16
                width: parent.width - 32
                font.pixelSize: 22
                color: Farben.grau
                text: Api.organisations.length > 0
                      ? qsTr("Meine Organisationen")
                      : qsTr("Noch niemand")
            }

            Repeater {
                model: Api.organisations
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
                            text: modelData.name ? modelData.name : qsTr("Organisation")
                        }
                        Label {
                            width: parent.width
                            font.pixelSize: 18
                            color: Farben.grau
                            text: page.artName(modelData.type) + " · "
                                  + qsTr("halten: entfernen")
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onPressAndHold: {
                            Api.removeOrganisation(modelData.id)
                            appWindow.showMessage(qsTr("Entfernt"))
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
                visible: Api.organisations.length === 0
                text: Api.loggedIn
                      ? qsTr("Du faehrst noch fuer niemanden. Unten suchen und "
                             + "dazunehmen, dann zaehlen die Kilometer auch dort mit.")
                      : qsTr("Nicht angemeldet")
            }

            Label { x: 16; font.pixelSize: 22; color: Farben.grau; text: qsTr("Dazunehmen") }

            TextField {
                id: suchfeld
                x: 16
                width: parent.width - 32
                placeholderText: qsTr("Name der Organisation")
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                Keys.onReturnPressed: page.suchen()
            }

            Button {
                x: 16
                width: parent.width - 32
                text: qsTr("Art") + ": " + page.artNamen[page.artIndex]
                onClicked: {
                    page.artIndex = (page.artIndex + 1) % page.artKennungen.length
                    page.suchen()
                }
            }

            Button {
                x: 16
                width: parent.width - 32
                text: Api.searchingOrganisations ? qsTr("Suche läuft …") : qsTr("Suchen")
                enabled: !Api.searchingOrganisations
                onClicked: page.suchen()
            }

            Repeater {
                model: Api.foundOrganisations
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
                            color: Api.ridesFor(modelData.id) ? Farben.grau : Farben.schwarz
                            text: modelData.name ? modelData.name : qsTr("Organisation")
                        }
                        Label {
                            width: parent.width
                            font.pixelSize: 18
                            color: Farben.grau
                            text: page.artName(modelData.type)
                                  + (Api.ridesFor(modelData.id)
                                     ? " · " + qsTr("schon dabei")
                                     : " · " + qsTr("antippen zum Dazunehmen"))
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: !Api.ridesFor(modelData.id)
                        onClicked: {
                            Api.addOrganisation(modelData.id)
                            appWindow.showMessage(qsTr("Dazugenommen"))
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
                visible: Api.foundOrganisations.length === 0 && !Api.searchingOrganisations
                text: qsTr("Nach einem Namen suchen oder nur eine Art waehlen.")
            }

            Item { width: 1; height: 16 }
        }
    }

    ToolBarLayout {
        id: werkzeuge
        ToolIcon { iconId: "toolbar-back"; onClicked: pageStack.pop() }
        ToolIcon { iconId: "toolbar-refresh"; onClicked: Api.fetchCommunity() }
    }
}
