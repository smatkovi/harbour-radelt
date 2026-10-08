import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            PageHeader { title: qsTr("Einstellungen") }

            TextSwitch {
                text: qsTr("Fahrten gleich übertragen")
                description: qsTr("Sobald eine Fahrt gespeichert ist, geht sie zu radelt.at")
                checked: Settings.uploadAutomatically
                onCheckedChanged: Settings.uploadAutomatically = checked
            }

            TextSwitch {
                text: qsTr("Bildschirm anlassen")
                description: qsTr("Nur während der Aufzeichnung. Kostet Akku, zeigt dafür die Zahlen.")
                checked: Settings.keepDisplayOn
                onCheckedChanged: Settings.keepDisplayOn = checked
            }

            Slider {
                width: parent.width
                minimumValue: 10
                maximumValue: 100
                stepSize: 5
                value: Settings.accuracyLimit
                valueText: qsTr("%1 m").arg(Math.round(value))
                label: qsTr("Punkte verwerfen ab")
                onReleased: Settings.accuracyLimit = value
            }

            SectionHeader { text: qsTr("Konto") }

            DetailItem {
                label: qsTr("Angemeldet als")
                value: Api.loggedIn ? Api.displayName : qsTr("niemand")
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Api.loggedIn ? qsTr("Abmelden") : qsTr("Anmelden")
                onClicked: {
                    if (Api.loggedIn)
                        Api.logout()
                    else
                        pageStack.push(Qt.resolvedUrl("LoginPage.qml"))
                }
            }
        }
    }
}
