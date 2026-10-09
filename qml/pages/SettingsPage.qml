import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

ThemedPage {
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            PageHeader { title: qsTr("Einstellungen") }

            ComboBox {
                property bool bereit: false
                readonly property var werte: [2, 1, 0]
                label: qsTr("Farbschema")
                currentIndex: werte.indexOf(Settings.colorTheme) >= 0
                              ? werte.indexOf(Settings.colorTheme) : 0
                menu: ContextMenu {
                    MenuItem { text: qsTr("Rot auf schwarzem Grund") }
                    MenuItem { text: qsTr("Rot auf hellem Grund") }
                    MenuItem { text: qsTr("Ambience (Systemfarben)") }
                }
                Component.onCompleted: bereit = true
                onCurrentIndexChanged: {
                    if (bereit && currentIndex >= 0)
                        Settings.colorTheme = werte[currentIndex]
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: palette.secondaryColor
                text: qsTr("Schwarz heißt hier wirklich #000000 — auf dem OLED bleiben "
                           + "die Pixel aus. Dazu gibt es ein eigenes Ambiente „Radelt“ "
                           + "in den Systemeinstellungen, das das ganze Gerät einfärbt.")
            }

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
