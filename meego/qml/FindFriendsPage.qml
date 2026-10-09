import QtQuick 1.1
import com.nokia.meego 1.0

// Freund:innen suchen und anfragen. Mindestens drei Buchstaben -- darunter
// fragt die App gar nicht erst, so hält es auch die Original-App.
Page {
    id: page
    tools: tools

    Header { id: header; text: qsTr("Freund:innen suchen") }

    TextField {
        id: suche
        anchors.top: header.bottom
        anchors.topMargin: 12
        x: 16
        width: parent.width - 32
        placeholderText: qsTr("Name")
        onTextChanged: verzoegert.restart()
    }

    // Nicht bei jedem Tastendruck fragen: das Netz am N9 ist langsam.
    Timer {
        id: verzoegert
        interval: 600
        onTriggered: Api.searchFriends(suche.text)
    }

    Label {
        id: hinweis
        anchors.top: suche.bottom
        anchors.topMargin: 6
        x: 16
        width: parent.width - 32
        wrapMode: Text.WordWrap
        font.pixelSize: 18
        color: Farben.grau
        visible: suche.text.length > 0 && suche.text.length < 3
        text: qsTr("Bitte mindestens drei Buchstaben.")
    }

    BusyIndicator {
        anchors.top: hinweis.bottom
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        running: Api.searching
        visible: Api.searching
    }

    ListView {
        id: list
        anchors.top: hinweis.bottom
        anchors.topMargin: 12
        anchors.bottom: parent.bottom
        width: parent.width
        clip: true
        model: Api.foundPeople

        delegate: Item {
            width: list.width
            height: 72

            Column {
                anchors.verticalCenter: parent.verticalCenter
                x: 16
                width: parent.width - 32
                Label {
                    width: parent.width
                    elide: Text.ElideRight
                    // Die Suche liefert firstname/lastname klein geschrieben,
                    // anders als die Freundesliste -- am Server gemessen.
                    text: ((modelData.firstname ? modelData.firstname : "") + " "
                           + (modelData.lastname ? modelData.lastname : "")).trim()
                }
                Label {
                    width: parent.width
                    font.pixelSize: 18
                    color: Farben.grau
                    elide: Text.ElideRight
                    text: {
                        var ort = modelData.city ? modelData.city : ""
                        var st = modelData.friendshipStatus
                        if (!st) return ort
                        if (st === "ACCEPTED") return ort + " · " + qsTr("befreundet")
                        if (st === "PENDING") return ort + " · " + qsTr("angefragt")
                        return ort + " · " + st
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (modelData.friendshipStatus)
                        return
                    Api.requestFriend(modelData.id)
                    appWindow.showMessage(qsTr("Anfrage geschickt"))
                }
            }
        }
    }

    Label {
        anchors.centerIn: list
        width: parent.width - 64
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        color: Farben.grau
        visible: list.count === 0 && !Api.searching
        text: suche.text.length >= 3 ? qsTr("Niemanden gefunden")
                                     : qsTr("Nach dem Namen suchen")
    }

    ScrollDecorator { flickableItem: list }

    ToolBarLayout {
        id: tools
        ToolIcon { iconId: "toolbar-back"; onClicked: pageStack.pop() }
    }
}
