import QtQuick 1.1
import com.nokia.meego 1.0

// Die Übersicht: was das Jahr bisher gebracht hat, und der Balken je Monat.
Page {
    id: page
    tools: tools

    Component.onCompleted: Api.refresh()

    Header {
        id: header
        text: Api.yearStats.year ? qsTr("Übersicht %1").arg(Api.yearStats.year)
                                 : qsTr("Übersicht")
    }

    Flickable {
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        contentHeight: inhalt.height
        clip: true

        Column {
            id: inhalt
            width: page.width
            spacing: 20

            Item { width: 1; height: 8 }

            BigNumber {
                width: parent.width
                large: true
                value: Format.kilometres((Api.yearStats.km_total || 0) * 1000)
                unit: qsTr("Kilometer im Jahr")
            }

            Row {
                width: parent.width
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
                width: parent.width
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

            Label {
                x: 16
                font.pixelSize: 22
                color: Farben.grau
                text: qsTr("Monate")
            }

            // Balken je Monat, selbst gezeichnet.
            Item {
                x: 16
                width: parent.width - 32
                height: 160

                Row {
                    anchors.fill: parent
                    spacing: 2

                    Repeater {
                        model: Api.months
                        delegate: Item {
                            width: (160 * 0 + parent.width - 22) / 12
                            height: parent.height

                            // Kein Anweisungsblock als Bindung: das
                            // QML von Qt 4.7 nimmt das nicht an (der
                            // Pruefer meldet "Syntax error"). Die
                            // Funktion bekommt die Monate als Argument,
                            // damit die Bindung sie als Abhaengigkeit
                            // sieht und nachrechnet.
                            function hoechstWert(monate) {
                                var m = 1
                                for (var i = 0; i < monate.length; i++)
                                    m = Math.max(m, monate[i].km_total || 0)
                                return m
                            }

                            property real hoechst: hoechstWert(Api.months)

                            Rectangle {
                                anchors.bottom: beschriftung.top
                                anchors.bottomMargin: 4
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width * 0.7
                                height: Math.max(2, (parent.height - beschriftung.height - 4)
                                                    * (modelData.km_total || 0) / parent.hoechst)
                                radius: 2
                                color: Farben.rot
                            }
                            Label {
                                id: beschriftung
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                font.pixelSize: 16
                                color: Farben.grau
                                text: modelData.month
                                      ? parseInt(modelData.month.split("-")[1], 10) : ""
                            }
                        }
                    }
                }
            }

            Item { width: 1; height: 16 }
        }
    }

    ToolBarLayout {
        id: tools
        ToolIcon { iconId: "toolbar-back"; onClicked: pageStack.pop() }
        ToolIcon { iconId: "toolbar-refresh"; onClicked: Api.refresh() }
    }
}
