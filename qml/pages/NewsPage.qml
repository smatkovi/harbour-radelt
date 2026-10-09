import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

// Neuigkeiten, Benachrichtigungen und Sponsoren — alles nur gelesen.
ThemedPage {
    allowedOrientations: Orientation.All

    onStatusChanged: if (status === PageStatus.Active) Api.fetchNews()

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: inhalt.height

        PullDownMenu {
            MenuItem { text: qsTr("Aktualisieren"); onClicked: Api.fetchNews() }
        }

        Column {
            id: inhalt
            width: parent.width

            PageHeader { title: qsTr("Neuigkeiten") }

            Repeater {
                model: Api.notifications
                delegate: ListItem {
                    contentHeight: Theme.itemSizeSmall
                    width: inhalt.width
                    Column {
                        x: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: modelData.title ? modelData.title
                                                  : (modelData.message ? modelData.message
                                                                       : qsTr("Hinweis"))
                        }
                        Label {
                            width: parent.width
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: palette.secondaryColor
                            text: modelData.created_at ? modelData.created_at : ""
                        }
                    }
                }
            }

            SectionHeader {
                text: qsTr("News und Veranstaltungen")
                visible: Api.news.length > 0
            }

            Repeater {
                model: Api.news
                delegate: ListItem {
                    contentHeight: Theme.itemSizeSmall
                    width: inhalt.width
                    Label {
                        x: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        truncationMode: TruncationMode.Fade
                        text: modelData.title ? modelData.title : qsTr("Beitrag")
                    }
                }
            }

            SectionHeader {
                text: qsTr("Sponsoren")
                visible: Api.sponsors.length > 0
            }

            Repeater {
                model: Api.sponsors
                delegate: Label {
                    x: Theme.horizontalPageMargin
                    width: inhalt.width - 2 * Theme.horizontalPageMargin
                    truncationMode: TruncationMode.Fade
                    font.pixelSize: Theme.fontSizeSmall
                    text: modelData.name ? modelData.name : ""
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: palette.secondaryColor
                visible: Api.news.length === 0 && Api.notifications.length === 0
                text: Api.loggedIn ? qsTr("Nichts Neues.") : qsTr("Nicht angemeldet")
            }

            Item { width: 1; height: Theme.paddingLarge }
        }
    }
}
