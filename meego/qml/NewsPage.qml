import QtQuick 1.1
import com.nokia.meego 1.0

// Neuigkeiten, Benachrichtigungen und Sponsoren -- alles nur gelesen.
Page {
    id: page
    tools: tools

    Component.onCompleted: Api.fetchNews()

    Header { id: header; text: qsTr("Neuigkeiten") }

    Flickable {
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        contentHeight: inhalt.height
        clip: true

        Column {
            id: inhalt
            width: page.width
            spacing: 6

            Item { width: 1; height: 10 }

            Repeater {
                model: Api.notifications
                delegate: Column {
                    x: 16
                    width: page.width - 32
                    Label {
                        width: parent.width
                        elide: Text.ElideRight
                        text: modelData.title ? modelData.title
                                              : (modelData.message ? modelData.message
                                                                   : qsTr("Hinweis"))
                    }
                    Label {
                        width: parent.width
                        font.pixelSize: 18
                        color: Farben.grau
                        text: modelData.created_at ? modelData.created_at : ""
                    }
                }
            }

            Label {
                x: 16
                font.pixelSize: 22
                color: Farben.grau
                visible: Api.news.length > 0
                text: qsTr("News und Veranstaltungen")
            }

            Repeater {
                model: Api.news
                delegate: Label {
                    x: 16
                    width: page.width - 32
                    elide: Text.ElideRight
                    text: modelData.title ? modelData.title : qsTr("Beitrag")
                }
            }

            Label {
                x: 16
                font.pixelSize: 22
                color: Farben.grau
                visible: Api.sponsors.length > 0
                text: qsTr("Sponsoren")
            }

            Repeater {
                model: Api.sponsors
                delegate: Label {
                    x: 16
                    width: page.width - 32
                    elide: Text.ElideRight
                    font.pixelSize: 20
                    text: modelData.name ? modelData.name : ""
                }
            }

            Label {
                x: 16
                width: parent.width - 32
                wrapMode: Text.WordWrap
                font.pixelSize: 18
                color: Farben.grau
                visible: Api.news.length === 0 && Api.notifications.length === 0
                text: Api.loggedIn ? qsTr("Nichts Neues.") : qsTr("Nicht angemeldet")
            }

            Item { width: 1; height: 16 }
        }
    }

    ToolBarLayout {
        id: tools
        ToolIcon { iconId: "toolbar-back"; onClicked: pageStack.pop() }
        ToolIcon { iconId: "toolbar-refresh"; onClicked: Api.fetchNews() }
    }
}
