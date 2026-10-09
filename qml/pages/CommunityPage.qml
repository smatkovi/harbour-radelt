import QtQuick 2.0
import Sailfish.Silica 1.0

// Freund:innen und die Organisationen, für die man radelt. Die Plattform
// zeigt hier Ränge; wo sie keinen liefert (zu wenige Fahrten, Aktion noch
// nicht gestartet), steht das auch so da statt einer erfundenen Null.
Page {
    allowedOrientations: Orientation.All

    onStatusChanged: if (status === PageStatus.Active) Api.fetchCommunity()

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        PullDownMenu {
            MenuItem {
                visible: Api.shareUrl.length > 0
                text: qsTr("Einladungslink kopieren")
                onClicked: Clipboard.text = Api.shareUrl
            }
            MenuItem {
                text: qsTr("Aktualisieren")
                onClicked: Api.fetchCommunity()
            }
        }

        Column {
            id: content
            width: parent.width

            PageHeader { title: qsTr("Community") }

            SectionHeader { text: qsTr("Freund:innen") }

            Repeater {
                model: Api.friends
                delegate: ListItem {
                    contentHeight: Theme.itemSizeSmall
                    width: content.width
                    Column {
                        x: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: {
                                var n = modelData.nickname
                                if (n && n.length > 0) return n
                                return ((modelData.firstName ? modelData.firstName : "") + " "
                                        + (modelData.lastName ? modelData.lastName : "")).trim()
                            }
                        }
                        Label {
                            width: parent.width
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.secondaryColor
                            text: (modelData.city ? modelData.city : "")
                                  + (modelData.ranking
                                     ? " · " + qsTr("Rang %1").arg(modelData.ranking)
                                     : " · " + qsTr("kein Rang"))
                        }
                    }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                wrapMode: Text.Wrap
                visible: Api.friends.length === 0
                text: Api.loggedIn ? qsTr("Noch niemand. Über das Menü einen Einladungslink teilen.")
                                   : qsTr("Nicht angemeldet")
            }

            SectionHeader { text: qsTr("Ich radle für") }

            Repeater {
                model: Api.organisations
                delegate: ListItem {
                    contentHeight: Theme.itemSizeSmall
                    width: content.width
                    Column {
                        x: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: modelData.name ? modelData.name : ""
                        }
                        Label {
                            width: parent.width
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.secondaryColor
                            text: {
                                // Die Plattform kennt Verein, Betrieb,
                                // Gemeinde, Schule und Universität.
                                var t = modelData.type ? modelData.type : ""
                                switch (t.toUpperCase()) {
                                case "ASSOCIATION": return qsTr("Verein")
                                case "COMPANY": case "WORKPLACE": return qsTr("Betrieb")
                                case "MUNICIPALITY": return qsTr("Gemeinde")
                                case "SCHOOL": return qsTr("Schule")
                                case "UNIVERSITY": return qsTr("Universität")
                                default: return t
                                }
                            }
                        }
                    }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                wrapMode: Text.Wrap
                visible: Api.organisations.length === 0
                text: qsTr("Keine Organisation gewählt. Das geht auf radelt.at.")
            }

            Item { width: 1; height: Theme.paddingLarge }
        }
    }
}
