import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

// Die Übersicht: was das Jahr bisher gebracht hat, und der Balken je Monat.
// Die Zahlen kommen vom Server (Jahresstatistik), nicht aus den lokalen
// Fahrten -- hier steht, was das Konto zählt.
Page {
    allowedOrientations: Orientation.All

    onStatusChanged: if (status === PageStatus.Active) Api.refresh()

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        PullDownMenu {
            MenuItem { text: qsTr("Aktualisieren"); onClicked: Api.refresh() }
        }

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: qsTr("Übersicht")
                description: Api.yearStats.year ? qsTr("Jahr %1").arg(Api.yearStats.year) : ""
            }

            BigNumber {
                width: parent.width
                large: true
                value: Format.kilometres((Api.yearStats.km_total || 0) * 1000)
                unit: qsTr("Kilometer im Jahr")
            }

            Row {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                BigNumber {
                    width: parent.width / 2
                    value: Format.metres(Api.yearStats.co2 || 0)
                    unit: qsTr("kg CO₂ gespart")
                }
                BigNumber {
                    width: parent.width / 2
                    value: Format.metres(Api.yearStats.money_saved || 0)
                    unit: qsTr("Euro gespart")
                }
            }

            Row {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                BigNumber {
                    width: parent.width / 2
                    value: Format.metres(Api.yearStats.kcal || 0)
                    unit: qsTr("Kalorien")
                }
                BigNumber {
                    width: parent.width / 2
                    value: Format.metres(Api.yearStats.height_meters_total || 0)
                    unit: qsTr("Höhenmeter")
                }
            }

            SectionHeader { text: qsTr("Monate") }

            // Balken je Monat, selbst gezeichnet -- Silica bringt kein
            // Diagramm mit, und ein Bild dafür wäre auf jedem Gerät falsch
            // skaliert.
            Item {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: Theme.itemSizeHuge

                Row {
                    anchors.fill: parent
                    spacing: 2

                    Repeater {
                        model: Api.months
                        delegate: Item {
                            width: (parent.width - 11 * 2) / 12
                            height: parent.height

                            property real hoechst: {
                                var m = 1
                                for (var i = 0; i < Api.months.length; i++)
                                    m = Math.max(m, Api.months[i].km_total || 0)
                                return m
                            }

                            Rectangle {
                                anchors.bottom: beschriftung.top
                                anchors.bottomMargin: Theme.paddingSmall
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width * 0.7
                                height: Math.max(2, (parent.height - beschriftung.height
                                                     - Theme.paddingSmall)
                                                    * (modelData.km_total || 0) / parent.hoechst)
                                radius: 2
                                color: Farben.rot
                            }
                            Label {
                                id: beschriftung
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                font.pixelSize: Theme.fontSizeTiny
                                color: Theme.secondaryColor
                                // "2026-03-01" -> "3"
                                text: modelData.month
                                      ? parseInt(modelData.month.split("-")[1], 10) : ""
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
                color: Theme.secondaryColor
                visible: !Api.loggedIn
                text: qsTr("Nicht angemeldet — hier stehen die Zahlen deines Kontos.")
            }

            Item { width: 1; height: Theme.paddingLarge }
        }
    }
}
