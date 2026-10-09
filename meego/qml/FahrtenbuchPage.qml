import QtQuick 1.1
import com.nokia.meego 1.0

// Das Fahrtenbuch: ein Kalender mit den Tagen, an denen man geradelt ist.
// Die Tage haengen an einer Aktion; gerechnet wird im C++-Kern
// (Api.monthGrid), weil das JavaScript von Qt 4.7 kein ISO-Datum lesen
// kann und beide Oberflaechen denselben Kalender zeigen sollen.
Page {
    id: page
    tools: werkzeuge

    property int jahr: 0
    property int monat: 0
    property variant aktion: null
    property variant gitter: []

    property variant monatsnamen: [
        qsTr("Jänner"), qsTr("Februar"), qsTr("März"), qsTr("April"),
        qsTr("Mai"), qsTr("Juni"), qsTr("Juli"), qsTr("August"),
        qsTr("September"), qsTr("Oktober"), qsTr("November"), qsTr("Dezember")]

    function neuRechnen() {
        gitter = Api.monthGrid(jahr, monat)
    }

    function laden() {
        if (aktion)
            Api.fetchJourneyLogs(aktion.id)
        else
            neuRechnen()
    }

    function waehleErste() {
        if (!aktion && Api.myChallenges.length > 0) {
            aktion = Api.myChallenges[0]
            laden()
        }
    }

    function blaettern(schritte) {
        var m = monat + schritte
        var j = jahr
        while (m > 12) { m -= 12; j += 1 }
        while (m < 1)  { m += 12; j -= 1 }
        monat = m
        jahr = j
        neuRechnen()
    }

    function umschalten(feld) {
        if (!aktion || feld.future)
            return
        if (feld.logged)
            Api.deleteCyclingDays(aktion.id, [feld.date])
        else
            Api.saveCyclingDays(aktion.id, [feld.date], true)
    }

    Component.onCompleted: {
        var heute = new Date()
        jahr = heute.getFullYear()
        monat = heute.getMonth() + 1
        neuRechnen()
        Api.fetchChallenges()
        waehleErste()
        laden()
    }

    Connections {
        target: Api
        onJourneyLogsChanged: page.neuRechnen()
        onChallengesChanged: page.waehleErste()
    }

    Header {
        id: kopf
        text: page.aktion ? qsTr("Fahrtenbuch") + " · " + page.aktion.name
                          : qsTr("Fahrtenbuch")
    }

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
                wrapMode: Text.WordWrap
                font.pixelSize: 18
                color: Farben.grau
                visible: Api.myChallenges.length === 0
                text: Api.loggedIn
                      ? qsTr("Radeltage haengen immer an einer Aktion. Unter "
                             + "\"Aktionen\" bei einer mitmachen.")
                      : qsTr("Nicht angemeldet")
            }

            // Bei mehreren Aktionen durchschalten -- der Dienst fuehrt je
            // Aktion ein eigenes Buch.
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 32
                visible: Api.myChallenges.length > 1
                text: page.aktion ? page.aktion.name : qsTr("Aktion waehlen")
                onClicked: {
                    var alle = Api.myChallenges
                    var i = 0
                    for (var k = 0; k < alle.length; ++k)
                        if (page.aktion && alle[k].id === page.aktion.id) i = k
                    page.aktion = alle[(i + 1) % alle.length]
                    page.laden()
                }
            }

            Row {
                width: parent.width
                height: 56

                Button {
                    width: 72
                    height: 48
                    anchors.verticalCenter: parent.verticalCenter
                    text: "<"
                    onClicked: page.blaettern(-1)
                }
                Label {
                    width: parent.width - 144
                    height: 48
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: Farben.rot
                    font.pixelSize: 26
                    text: page.monat >= 1
                          ? page.monatsnamen[page.monat - 1] + " " + page.jahr : ""
                }
                Button {
                    width: 72
                    height: 48
                    anchors.verticalCenter: parent.verticalCenter
                    text: ">"
                    onClicked: page.blaettern(1)
                }
            }

            Row {
                x: 8
                width: parent.width - 16
                Repeater {
                    model: [qsTr("Mo"), qsTr("Di"), qsTr("Mi"), qsTr("Do"),
                            qsTr("Fr"), qsTr("Sa"), qsTr("So")]
                    delegate: Label {
                        width: (page.width - 16) / 7
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 18
                        color: Farben.grau
                        text: modelData
                    }
                }
            }

            Grid {
                x: 8
                width: parent.width - 16
                columns: 7

                Repeater {
                    model: page.gitter
                    delegate: Item {
                        width: (page.width - 16) / 7
                        height: width

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width - 6
                            height: width
                            radius: width / 2
                            visible: modelData.inMonth
                                     && (modelData.logged || modelData.today)
                            color: modelData.logged ? Farben.rot : "transparent"
                            border.width: modelData.today ? 2 : 0
                            border.color: Farben.rot
                        }

                        Label {
                            anchors.centerIn: parent
                            text: modelData.day
                            font.pixelSize: 22
                            color: modelData.logged ? Farben.weiss
                                 : (modelData.future ? Farben.grau : Farben.schwarz)
                            opacity: modelData.inMonth ? 1 : 0.25
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: modelData.inMonth && !modelData.future
                                     && page.aktion !== null
                            onClicked: page.umschalten(modelData)
                        }
                    }
                }
            }

            Item { width: 1; height: 8 }

            Label {
                x: 16
                width: parent.width - 32
                wrapMode: Text.WordWrap
                font.pixelSize: 18
                color: Farben.grau
                visible: page.aktion !== null
                text: Api.journeyLogs.length + " "
                      + qsTr("Radeltage eingetragen · Tag antippen zum Ein- und Austragen")
            }

            Item { width: 1; height: 16 }
        }
    }

    ToolBarLayout {
        id: werkzeuge
        ToolIcon {
            iconId: "toolbar-back"
            onClicked: pageStack.pop()
        }
        ToolIcon {
            iconId: "toolbar-add"
            visible: page.aktion !== null
            onClicked: {
                Api.addCyclingDay(page.aktion.id, new Date())
                appWindow.showMessage(qsTr("Heutiger Radeltag eingetragen"))
            }
        }
        ToolIcon {
            iconId: "toolbar-refresh"
            onClicked: page.laden()
        }
    }
}
