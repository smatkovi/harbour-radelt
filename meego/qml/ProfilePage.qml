import QtQuick 1.1
import com.nokia.meego 1.0

// Das Profil des Kontos. Der Dienst prüft email, firstName und lastName;
// nickname prüft er nicht -- was dort hineingeht, steht danach wörtlich
// im Konto.
Page {
    id: page
    tools: tools

    property variant p: Api.person

    Header { id: header; text: qsTr("Mein Profil") }

    Flickable {
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        contentHeight: inhalt.height
        clip: true

        Column {
            id: inhalt
            width: page.width
            spacing: 12

            Item { width: 1; height: 8 }

            Label { x: 16; text: qsTr("Vorname") }
            TextField { id: vorname; x: 16; width: parent.width - 32
                        text: page.p.firstName ? page.p.firstName : "" }

            Label { x: 16; text: qsTr("Nachname") }
            TextField { id: nachname; x: 16; width: parent.width - 32
                        text: page.p.lastName ? page.p.lastName : "" }

            Label { x: 16; text: qsTr("Spitzname") }
            TextField { id: spitzname; x: 16; width: parent.width - 32
                        placeholderText: qsTr("wird in der Community gezeigt")
                        text: page.p.nickname ? page.p.nickname : "" }

            Label { x: 16; text: qsTr("E-Mail") }
            TextField { id: mail; x: 16; width: parent.width - 32
                        inputMethodHints: Qt.ImhEmailCharactersOnly | Qt.ImhNoAutoUppercase
                        text: page.p.email ? page.p.email : "" }

            Row {
                x: 16
                spacing: 16
                Switch {
                    id: sichtbar
                    checked: page.p.visibleForFriends === true
                    onCheckedChanged: {
                        if (checked !== (page.p.visibleForFriends === true))
                            Api.setVisibleForFriends(checked)
                    }
                }
                Column {
                    width: page.width - 120
                    Label { text: qsTr("Für Freund:innen auffindbar") }
                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        font.pixelSize: 18
                        color: Farben.grau
                        text: qsTr("Ohne das findet dich niemand über die Namenssuche.")
                    }
                }
            }

            Detail { label: qsTr("Ort"); value: page.p.city ? page.p.city : "—" }
            Detail { label: qsTr("PLZ"); value: page.p.postalCode ? page.p.postalCode : "—" }
            Detail { label: qsTr("Bundesland"); value: page.p.state ? page.p.state : "—" }

            Label {
                x: 16
                width: parent.width - 32
                wrapMode: Text.WordWrap
                font.pixelSize: 18
                color: Farben.grau
                text: qsTr("Wohnort und Bundesland ändert man auf radelt.at.")
            }

            Label {
                x: 16
                width: parent.width - 32
                wrapMode: Text.WordWrap
                color: "#ff4040"
                visible: Api.lastError.length > 0
                text: Api.lastError
            }

            Item { width: 1; height: 16 }
        }
    }

    ToolBarLayout {
        id: tools
        ToolIcon { iconId: "toolbar-back"; onClicked: pageStack.pop() }
        Button {
            width: 180
            text: qsTr("Speichern")
            onClicked: {
                var f = {}
                f["firstName"] = vorname.text
                f["lastName"] = nachname.text
                f["nickname"] = spitzname.text
                f["email"] = mail.text
                Api.updatePerson(f)
                appWindow.showMessage(qsTr("Profil gespeichert"))
            }
        }
    }

    Connections {
        target: Api
        onPersonChanged: page.p = Api.person
    }
}
