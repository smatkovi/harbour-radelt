import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

// Das Fahrtenbuch der Plattform: ein Kalender, in dem die Tage stehen, an
// denen man geradelt ist. Im Original heißt das "Radelt zur Arbeit"; die
// Tage hängen immer an einer Aktion, ohne Aktionskennung antwortet der
// Dienst mit challenge_not_found.
//
// Gerechnet wird im C++-Kern (Api.monthGrid): das JavaScript von Qt 4.7
// kann "2026-10-09" nicht lesen, und damit beide Oberflächen denselben
// Kalender zeigen, soll nur eine Stelle rechnen.
ThemedPage {
    id: page

    allowedOrientations: Orientation.All

    property int jahr: 0
    property int monat: 0
    property var aktion: Api.myChallenges.length > 0 ? Api.myChallenges[0] : null
    property var gitter: []

    readonly property var monatsnamen: [
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

    function blättern(schritte) {
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
    }

    onStatusChanged: if (status === PageStatus.Active) laden()

    Connections {
        target: Api
        onJourneyLogsChanged: page.neuRechnen()
        onChallengesChanged: {
            if (!page.aktion && Api.myChallenges.length > 0) {
                page.aktion = Api.myChallenges[0]
                page.laden()
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: inhalt.height

        PullDownMenu {
            MenuItem {
                text: qsTr("Heute eintragen")
                enabled: page.aktion !== null
                onClicked: {
                    Api.addCyclingDay(page.aktion.id, new Date())
                    hinweis.zeige(qsTr("Heutiger Radeltag eingetragen"))
                }
            }
            MenuItem { text: qsTr("Aktualisieren"); onClicked: page.laden() }
        }

        Column {
            id: inhalt
            width: parent.width

            PageHeader {
                title: qsTr("Fahrtenbuch")
                description: page.aktion ? page.aktion.name : qsTr("keine Aktion")
            }

            // Bei mehreren Aktionen muss man wählen können, zu welcher die
            // Tage gehören -- der Dienst führt je Aktion ein eigenes Buch.
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

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: palette.secondaryColor
                visible: Api.myChallenges.length === 0
                text: Api.loggedIn
                      ? qsTr("Radeltage hängen immer an einer Aktion. Unter „Aktionen“ "
                             + "bei einer mitmachen, dann wird hier mitgeschrieben.")
                      : qsTr("Nicht angemeldet")
            }

            // Monatskopf mit Blättern.
            Row {
                width: parent.width
                height: Theme.itemSizeSmall

                IconButton {
                    width: Theme.itemSizeSmall
                    height: Theme.itemSizeSmall
                    icon.source: "image://theme/icon-m-back"
                    onClicked: page.blättern(-1)
                }
                Label {
                    width: parent.width - 2 * Theme.itemSizeSmall
                    height: Theme.itemSizeSmall
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: palette.highlightColor
                    text: page.monat >= 1
                          ? page.monatsnamen[page.monat - 1] + " " + page.jahr : ""
                }
                IconButton {
                    width: Theme.itemSizeSmall
                    height: Theme.itemSizeSmall
                    icon.source: "image://theme/icon-m-forward"
                    onClicked: page.blättern(1)
                }
            }

            // Wochentage, Montag zuerst -- so legt der Kern das Gitter.
            Row {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                Repeater {
                    model: [qsTr("Mo"), qsTr("Di"), qsTr("Mi"), qsTr("Do"),
                            qsTr("Fr"), qsTr("Sa"), qsTr("So")]
                    delegate: Label {
                        width: parent.width / 7
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: palette.secondaryColor
                        text: modelData
                    }
                }
            }

            Grid {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                columns: 7

                Repeater {
                    model: page.gitter
                    delegate: Item {
                        width: (parent.width) / 7
                        height: width

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width - Theme.paddingSmall
                            height: width
                            radius: width / 2
                            visible: modelData.inMonth
                            color: modelData.logged ? palette.highlightColor : "transparent"
                            opacity: modelData.logged ? 0.35 : 1
                            border.width: modelData.today ? 2 : 0
                            border.color: palette.highlightColor
                        }

                        Label {
                            anchors.centerIn: parent
                            text: modelData.day
                            color: modelData.logged ? palette.highlightColor
                                 : (modelData.future ? palette.secondaryColor
                                                     : palette.primaryColor)
                            opacity: modelData.inMonth ? 1 : 0.25
                            font.pixelSize: Theme.fontSizeSmall
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

            Item { width: 1; height: Theme.paddingMedium }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: palette.secondaryColor
                visible: page.aktion !== null
                text: qsTr("%n Radeltag(e) eingetragen", "", Api.journeyLogs.length)
                      + " · " + qsTr("Tag antippen zum Ein- und Austragen")
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
