import QtQuick 1.1
import com.nokia.meego 1.0

// Orte sammeln. Eingesammelt wird einer, indem die eigene Position
// gemeldet wird; ob sie nah genug ist, entscheidet die Plattform. Einen
// eigenen Radius hat auch die Original-App nicht.
//
// Bilder zeigt diese Seite nicht: die Orte verlinken ihre Fotos ueber
// HTTPS, und das Qt 4.7 dieses Geraets kommt an modernem TLS nicht
// vorbei (dafuer gibt es den Rust-Holer, aber ein Foto ist das nicht
// wert). Lieber kein Bild als ein kaputter Platzhalter.
Page {
    id: page
    tools: werkzeuge

    property variant aktion: null
    property bool nurOffene: true
    property variant liste: []

    function laden() {
        if (page.aktion)
            Api.fetchPois(page.aktion.id)
        else
            neuOrdnen()
    }

    function waehleErste() {
        if (!aktion && Api.myChallenges.length > 0) {
            aktion = Api.myChallenges[0]
            laden()
        }
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
        return m < 1000 ? Math.round(m) + " m" : (m / 1000).toFixed(1) + " km"
    }

    // Unter Qt 4.7 ist eine Eigenschaft aus einer Funktion nicht
    // nachvollziehbar; die Liste wird deshalb einmal gebaut und gemerkt.
    function neuOrdnen() {
        var alle = Api.pois
        var neu = []
        for (var i = 0; i < alle.length; ++i) {
            if (page.nurOffene && alle[i].collected)
                continue
            neu.push(alle[i])
        }
        if (Recorder.positionValid)
            neu.sort(function(a, b) { return entfernung(a) - entfernung(b) })
        liste = neu
    }

    Component.onCompleted: {
        Recorder.startPositioning()
        Api.fetchChallenges()
        waehleErste()
        laden()
    }
    Component.onDestruction: Recorder.stopPositioning()

    Connections {
        target: Api
        onChallengesChanged: page.waehleErste()
        onPoisChanged: {
            page.neuOrdnen()
            if (Api.poiMessage.length > 0)
                appWindow.showMessage(Api.poiMessage)
        }
    }
    Connections {
        target: Recorder
        onPositionChanged: page.neuOrdnen()
    }

    Header {
        id: kopf
        text: page.aktion ? qsTr("Orte sammeln") + " · " + page.aktion.name
                          : qsTr("Orte sammeln")
    }

    Column {
        id: oben
        anchors.top: kopf.bottom
        width: parent.width
        spacing: 4

        Item { width: 1; height: 6 }

        Label {
            x: 16
            width: parent.width - 32
            wrapMode: Text.WordWrap
            font.pixelSize: 18
            color: Farben.grau
            text: Recorder.positionValid
                  ? qsTr("Nach Naehe sortiert · Genauigkeit ")
                    + Math.round(Recorder.accuracy) + " m"
                  : qsTr("Warte auf den Empfaenger – noch nicht nach Naehe sortiert")
        }

        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 32
            text: qsTr("Hier einsammeln")
            enabled: Recorder.positionValid && Api.loggedIn
            onClicked: {
                Api.collectHere(Recorder.latitude, Recorder.longitude)
                appWindow.showMessage(qsTr("Position gemeldet …"))
            }
        }
    }

    ListView {
        id: ansicht
        anchors.top: oben.bottom
        anchors.topMargin: 6
        anchors.bottom: parent.bottom
        width: parent.width
        clip: true
        model: page.liste

        delegate: Item {
            width: page.width
            height: 76

            Column {
                anchors.verticalCenter: parent.verticalCenter
                x: 16
                width: parent.width - 32
                Label {
                    width: parent.width
                    elide: Text.ElideRight
                    text: modelData.name ? modelData.name : qsTr("Ort")
                }
                Label {
                    width: parent.width
                    elide: Text.ElideRight
                    font.pixelSize: 18
                    color: Farben.grau
                    text: page.entfernungText(modelData)
                          + (modelData.routeName ? " · " + modelData.routeName : "")
                          + (modelData.collected ? " · " + qsTr("eingesammelt") : "")
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: pageStack.push(Qt.resolvedUrl("OrtPage.qml"),
                                          { ort: modelData,
                                            entfernung: page.entfernungText(modelData) })
            }
        }
    }

    Label {
        anchors.centerIn: parent
        width: parent.width - 64
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        color: Farben.grau
        visible: page.liste.length === 0
        text: page.aktion
              ? qsTr("Diese Aktion sammelt keine Orte, oder alle sind schon "
                     + "eingesammelt.")
              : qsTr("Orte gehoeren zu einer Aktion. Unter \"Aktionen\" bei einer "
                     + "mitmachen.")
    }

    ToolBarLayout {
        id: werkzeuge
        ToolIcon {
            iconId: "toolbar-back"
            onClicked: pageStack.pop()
        }
        ToolIcon {
            iconId: "toolbar-view-menu"
            onClicked: {
                page.nurOffene = !page.nurOffene
                page.neuOrdnen()
                appWindow.showMessage(page.nurOffene ? qsTr("Nur offene Orte")
                                                     : qsTr("Alle Orte"))
            }
        }
        ToolIcon {
            iconId: "toolbar-refresh"
            onClicked: page.laden()
        }
    }
}
