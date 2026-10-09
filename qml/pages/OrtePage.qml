import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

// Orte sammeln. Die Plattform hängt Orte an die Strecken einer Aktion;
// eingesammelt wird einer, indem man seine eigene Position meldet und der
// Dienst antwortet, welcher Ort dort in Reichweite liegt. Einen eigenen
// Radius gibt es nicht -- die Original-App schickt ihre Position als
// Kasten, dessen Ecken zusammenfallen, und lässt den Dienst entscheiden.
ThemedPage {
    id: page

    allowedOrientations: Orientation.All

    property var aktion: Api.myChallenges.length > 0 ? Api.myChallenges[0] : null
    property bool nurOffene: true

    function laden() {
        if (page.aktion)
            Api.fetchPois(page.aktion.id)
    }

    // Nach Nähe sortieren, sobald der Empfänger etwas weiß. Ohne Position
    // bleibt die Reihenfolge, die der Dienst schickt -- eine erfundene
    // Entfernung wäre schlimmer als keine.
    function orte() {
        var alle = Api.pois
        var liste = []
        for (var i = 0; i < alle.length; ++i) {
            if (page.nurOffene && alle[i].collected)
                continue
            liste.push(alle[i])
        }
        if (!Recorder.positionValid)
            return liste
        liste.sort(function(a, b) { return entfernung(a) - entfernung(b) })
        return liste
    }

    function entfernung(ort) {
        if (!ort.hasPosition || !Recorder.positionValid)
            return 1e12
        return Api.metresBetween(Recorder.latitude, Recorder.longitude,
                                 ort.latitude, ort.longitude)
    }

    function entfernungText(ort) {
        if (!ort.hasPosition)
            return qsTr("ohne Koordinaten")
        if (!Recorder.positionValid)
            return qsTr("Position noch unbekannt")
        var m = entfernung(ort)
        return m < 1000 ? Math.round(m) + " m"
                        : (m / 1000).toFixed(1) + " km"
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            Recorder.startPositioning()
            laden()
        } else if (status === PageStatus.Inactive) {
            Recorder.stopPositioning()
        }
    }

    Connections {
        target: Api
        onChallengesChanged: {
            if (!page.aktion && Api.myChallenges.length > 0) {
                page.aktion = Api.myChallenges[0]
                page.laden()
            }
        }
        onPoisChanged: if (Api.poiMessage.length > 0) hinweis.zeige(Api.poiMessage)
    }

    SilicaListView {
        id: liste
        anchors.fill: parent
        model: page.orte()

        PullDownMenu {
            MenuItem {
                text: page.nurOffene ? qsTr("Auch eingesammelte zeigen")
                                     : qsTr("Nur offene zeigen")
                onClicked: page.nurOffene = !page.nurOffene
            }
            MenuItem { text: qsTr("Aktualisieren"); onClicked: page.laden() }
            MenuItem {
                text: qsTr("Hier einsammeln")
                enabled: Recorder.positionValid && Api.loggedIn
                onClicked: {
                    Api.collectHere(Recorder.latitude, Recorder.longitude)
                    hinweis.zeige(qsTr("Position gemeldet …"))
                }
            }
        }

        header: Column {
            width: liste.width

            PageHeader {
                title: qsTr("Orte sammeln")
                description: page.aktion ? page.aktion.name : qsTr("keine Aktion")
            }

            ComboBox {
                width: parent.width
                visible: Api.myChallenges.length > 1
                label: qsTr("Aktion")
                menu: ContextMenu {
                    Repeater {
                        model: Api.myChallenges
                        delegate: MenuItem {
                            text: modelData.name ? modelData.name : qsTr("Aktion")
                            onClicked: {
                                page.aktion = modelData
                                page.laden()
                            }
                        }
                    }
                }
            }

            // Der Empfänger braucht einen Moment; solange ist die
            // Reihenfolge nicht nach Nähe, und das soll man wissen.
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: palette.secondaryColor
                text: Recorder.positionValid
                      ? qsTr("Nach Nähe sortiert · Genauigkeit %1 m")
                        .arg(Math.round(Recorder.accuracy))
                      : qsTr("Warte auf den Empfänger – noch nicht nach Nähe sortiert")
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Hier einsammeln")
                enabled: Recorder.positionValid && Api.loggedIn
                onClicked: {
                    Api.collectHere(Recorder.latitude, Recorder.longitude)
                    hinweis.zeige(qsTr("Position gemeldet …"))
                }
            }

            Item { width: 1; height: Theme.paddingMedium }
        }

        delegate: ListItem {
            id: zeile
            contentHeight: Theme.itemSizeMedium
            width: liste.width

            Column {
                x: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 2 * Theme.horizontalPageMargin

                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    color: zeile.highlighted ? palette.highlightColor : palette.primaryColor
                    text: modelData.name ? modelData.name : qsTr("Ort")
                }
                Label {
                    width: parent.width
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: palette.secondaryColor
                    truncationMode: TruncationMode.Fade
                    text: page.entfernungText(modelData)
                          + (modelData.routeName ? " · " + modelData.routeName : "")
                          + (modelData.collected ? " · " + qsTr("eingesammelt") : "")
                }
            }

            onClicked: pageStack.push(Qt.resolvedUrl("OrtPage.qml"),
                                      { ort: modelData,
                                        entfernung: page.entfernungText(modelData) })
        }

        ViewPlaceholder {
            enabled: liste.count === 0
            text: page.aktion ? qsTr("Keine Orte") : qsTr("Keine Aktion")
            hintText: page.aktion
                      ? qsTr("Diese Aktion sammelt keine Orte, oder alle sind schon "
                             + "eingesammelt.")
                      : qsTr("Orte gehören zu einer Aktion. Unter „Aktionen“ bei einer "
                             + "mitmachen.")
        }

        VerticalScrollDecorator { }
    }

    Label {
        id: hinweis
        function zeige(t) { text = t; visible = true; weg.restart() }
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.paddingLarge
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 2 * Theme.horizontalPageMargin
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        color: palette.highlightColor
        visible: false
        Timer { id: weg; interval: 4000; onTriggered: hinweis.visible = false }
    }
}
