import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

// Das Profil des Kontos. Der Dienst prüft email, firstName und lastName
// und antwortet bei Unsinn mit 409; nickname prüft er gar nicht — was man
// dort hineinschreibt, steht danach wortwörtlich im Konto.
ThemedPage {
    id: page

    allowedOrientations: Orientation.All

    property var p: Api.person

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: inhalt.height

        PullDownMenu {
            MenuItem {
                text: qsTr("Speichern")
                onClicked: page.speichern()
            }
        }

        Column {
            id: inhalt
            width: parent.width

            PageHeader { title: qsTr("Mein Profil") }

            TextField {
                id: vorname
                width: parent.width
                label: qsTr("Vorname")
                text: page.p.firstName ? page.p.firstName : ""
            }
            TextField {
                id: nachname
                width: parent.width
                label: qsTr("Nachname")
                text: page.p.lastName ? page.p.lastName : ""
            }
            TextField {
                id: spitzname
                width: parent.width
                label: qsTr("Spitzname")
                placeholderText: qsTr("wird in der Community gezeigt")
                text: page.p.nickname ? page.p.nickname : ""
            }
            TextField {
                id: mail
                width: parent.width
                label: qsTr("E-Mail")
                inputMethodHints: Qt.ImhEmailCharactersOnly | Qt.ImhNoAutoUppercase
                text: page.p.email ? page.p.email : ""
            }

            SectionHeader { text: qsTr("Sichtbarkeit") }

            TextSwitch {
                id: sichtbar
                text: qsTr("Für Freund:innen auffindbar")
                description: qsTr("Ohne das findet dich niemand über die Namenssuche.")
                checked: page.p.visibleForFriends === true
                onCheckedChanged: {
                    if (checked !== (page.p.visibleForFriends === true))
                        Api.setVisibleForFriends(checked)
                }
            }

            TextSwitch {
                text: qsTr("Spitznamen öffentlich zeigen")
                checked: page.p.showPublicNickname === true
                onCheckedChanged: {
                    if (checked !== (page.p.showPublicNickname === true)) {
                        var f = {}
                        f["showPublicNickname"] = checked
                        Api.updatePerson(f)
                    }
                }
            }

            SectionHeader { text: qsTr("Wohnort") }

            DetailItem { label: qsTr("Ort"); value: page.p.city ? page.p.city : "—" }
            DetailItem { label: qsTr("PLZ"); value: page.p.postalCode ? page.p.postalCode : "—" }
            DetailItem { label: qsTr("Bundesland"); value: page.p.state ? page.p.state : "—" }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: palette.secondaryColor
                text: qsTr("Wohnort und Bundesland ändert man auf radelt.at — sie "
                           + "entscheiden, welchen Aktionen die Kilometer zufallen.")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                color: palette.errorColor
                visible: Api.lastError.length > 0
                text: Api.lastError
            }

            Item { width: 1; height: Theme.paddingLarge }
        }
    }

    function speichern() {
        var f = {}
        f["firstName"] = vorname.text
        f["lastName"] = nachname.text
        f["nickname"] = spitzname.text
        f["email"] = mail.text
        Api.updatePerson(f)
    }

    Connections {
        target: Api
        onPersonChanged: page.p = Api.person
    }
}
