import QtQuick 1.1
import com.nokia.meego 1.0

// Freund:innen und die Organisationen, für die man radelt.
Page {
    id: page
    tools: tools

    Component.onCompleted: Api.fetchCommunity()

    function organisationsArt(t) {
        switch ((t ? t : "").toUpperCase()) {
        case "ASSOCIATION": return qsTr("Verein")
        case "COMPANY": case "WORKPLACE": return qsTr("Betrieb")
        case "MUNICIPALITY": return qsTr("Gemeinde")
        case "SCHOOL": return qsTr("Schule")
        case "UNIVERSITY": return qsTr("Universität")
        default: return t ? t : ""
        }
    }

    Header { id: header; text: qsTr("Community") }

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

            Label { x: 16; font.pixelSize: 22; color: Farben.grau; text: qsTr("Freund:innen") }

            Repeater {
                model: Api.friends
                delegate: Column {
                    x: 16
                    width: page.width - 32
                    Label {
                        width: parent.width
                        elide: Text.ElideRight
                        text: {
                            var n = modelData.nickname
                            if (n && n.length > 0) return n
                            return ((modelData.firstName ? modelData.firstName : "") + " "
                                    + (modelData.lastName ? modelData.lastName : "")).trim()
                        }
                    }
                    Label {
                        width: parent.width
                        font.pixelSize: 18
                        color: Farben.grau
                        text: (modelData.city ? modelData.city : "")
                              + (modelData.ranking ? " · " + qsTr("Rang %1").arg(modelData.ranking)
                                                   : " · " + qsTr("kein Rang"))
                    }
                }
            }

            Label {
                x: 16
                width: parent.width - 32
                wrapMode: Text.WordWrap
                font.pixelSize: 18
                color: Farben.grau
                visible: Api.friends.length === 0
                text: Api.loggedIn ? qsTr("Noch niemand.") : qsTr("Nicht angemeldet")
            }

            Item { width: 1; height: 10 }
            Label { x: 16; font.pixelSize: 22; color: Farben.grau; text: qsTr("Ich radle für") }

            Repeater {
                model: Api.organisations
                delegate: Column {
                    x: 16
                    width: page.width - 32
                    Label {
                        width: parent.width
                        elide: Text.ElideRight
                        text: modelData.name ? modelData.name : ""
                    }
                    Label {
                        width: parent.width
                        font.pixelSize: 18
                        color: Farben.grau
                        text: page.organisationsArt(modelData.type)
                    }
                }
            }

            Label {
                x: 16
                width: parent.width - 32
                wrapMode: Text.WordWrap
                font.pixelSize: 18
                color: Farben.grau
                visible: Api.organisations.length === 0
                text: qsTr("Keine Organisation gewählt. Das geht auf radelt.at.")
            }

            Item { width: 1; height: 16 }
        }
    }

    ToolBarLayout {
        id: tools
        ToolIcon { iconId: "toolbar-back"; onClicked: pageStack.pop() }
        ToolIcon { iconId: "toolbar-refresh"; onClicked: Api.fetchCommunity() }
    }
}
