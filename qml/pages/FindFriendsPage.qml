import QtQuick 2.0
import Sailfish.Silica 1.0

// Freund:innen suchen und anfragen. Der Server verlangt mindestens drei
// Buchstaben; darunter fragt die App gar nicht erst.
Page {
    allowedOrientations: Orientation.All

    SilicaListView {
        id: list
        anchors.fill: parent
        model: Api.foundPeople

        header: Column {
            width: list.width

            PageHeader { title: qsTr("Freund:innen suchen") }

            SearchField {
                id: suche
                width: parent.width
                placeholderText: qsTr("Name")
                inputMethodHints: Qt.ImhNoAutoUppercase
                onTextChanged: verzoegert.restart()
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                visible: suche.text.length > 0 && suche.text.length < 3
                text: qsTr("Bitte mindestens drei Buchstaben.")
            }

            BusyIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                running: Api.searching
                visible: Api.searching
                size: BusyIndicatorSize.Medium
            }
        }

        // Nicht bei jedem Tastendruck fragen: das Netz auf dem Rad ist
        // langsam, und der Server mag es auch nicht.
        Timer {
            id: verzoegert
            interval: 600
            onTriggered: Api.searchFriends(suche.text)
        }

        delegate: ListItem {
            id: eintrag
            contentHeight: Theme.itemSizeMedium
            width: list.width

            Column {
                x: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 2 * Theme.horizontalPageMargin

                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    color: eintrag.highlighted ? Theme.highlightColor : Theme.primaryColor
                    // Die Suche liefert firstname/lastname klein geschrieben,
                    // anders als die Freundesliste -- am Server gemessen.
                    text: ((modelData.firstname ? modelData.firstname : "") + " "
                           + (modelData.lastname ? modelData.lastname : "")).trim()
                }
                Label {
                    width: parent.width
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
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

            onClicked: {
                if (modelData.friendshipStatus) {
                    // Schon befreundet oder angefragt -- nichts zu tun.
                    return
                }
                Api.requestFriend(modelData.id)
                anfrage.text = qsTr("Anfrage an %1 geschickt")
                    .arg(modelData.firstname ? modelData.firstname : qsTr("die Person"))
                anfrage.visible = true
            }
        }

        ViewPlaceholder {
            enabled: list.count === 0 && !Api.searching
            text: suche.text.length >= 3 ? qsTr("Niemanden gefunden")
                                         : qsTr("Nach dem Namen suchen")
            hintText: qsTr("Gefunden wird nur, wer das im Profil erlaubt hat")
        }

        VerticalScrollDecorator { }
    }

    Label {
        id: anfrage
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.paddingLarge
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 2 * Theme.horizontalPageMargin
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        color: Theme.highlightColor
        visible: false
        onVisibleChanged: if (visible) ausblenden.restart()
        Timer { id: ausblenden; interval: 3000; onTriggered: anfrage.visible = false }
    }
}
