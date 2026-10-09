import QtQuick 1.1
import com.nokia.meego 1.0

// Verlauf und Trophäen des Kontos.
Page {
    id: page
    tools: tools

    Component.onCompleted: Api.fetchTimeline()

    Header { id: header; text: qsTr("Verlauf") }

    Column {
        id: kopf
        anchors.top: header.bottom
        anchors.topMargin: 12
        width: parent.width
        spacing: 8

        Label { x: 16; font.pixelSize: 22; color: Farben.grau; text: qsTr("Trophäen") }

        ListView {
            width: parent.width
            height: Api.trophies.length > 0 ? 110 : 0
            visible: Api.trophies.length > 0
            orientation: ListView.Horizontal
            model: Api.trophies
            spacing: 12
            clip: true

            delegate: Column {
                width: 110
                spacing: 6
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 56; height: 56; radius: 28
                    color: Farben.rot
                    Label {
                        anchors.centerIn: parent
                        color: Farben.weiss
                        font.pixelSize: 28
                        text: "★"
                    }
                }
                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 16
                    color: Farben.grau
                    wrapMode: Text.WordWrap
                    text: modelData.name ? modelData.name
                                         : (modelData.title ? modelData.title : qsTr("Trophäe"))
                }
            }
        }

        Label {
            x: 16
            width: parent.width - 32
            wrapMode: Text.WordWrap
            font.pixelSize: 18
            color: Farben.grau
            visible: Api.trophies.length === 0
            text: Api.loggedIn ? qsTr("Noch keine Trophäe.") : qsTr("Nicht angemeldet")
        }

        Label { x: 16; font.pixelSize: 22; color: Farben.grau; text: qsTr("Ereignisse") }
    }

    ListView {
        id: list
        anchors.top: kopf.bottom
        anchors.topMargin: 8
        anchors.bottom: parent.bottom
        width: parent.width
        clip: true
        model: Api.timeline

        delegate: Item {
            width: list.width
            height: 64
            Column {
                anchors.verticalCenter: parent.verticalCenter
                x: 16
                width: parent.width - 32
                Label {
                    width: parent.width
                    elide: Text.ElideRight
                    text: {
                        if (modelData.title) return modelData.title
                        if (modelData.name) return modelData.name
                        if (modelData.distance !== undefined)
                            return Format.kilometres(modelData.distance) + " km"
                        return modelData.type ? modelData.type : qsTr("Eintrag")
                    }
                }
                Label {
                    width: parent.width
                    font.pixelSize: 18
                    color: Farben.grau
                    elide: Text.ElideRight
                    text: modelData.date || modelData.created_at || modelData.createdAt || ""
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
        visible: list.count === 0
        text: qsTr("Kein Verlauf")
    }

    ScrollDecorator { flickableItem: list }

    ToolBarLayout {
        id: tools
        ToolIcon { iconId: "toolbar-back"; onClicked: pageStack.pop() }
        ToolIcon { iconId: "toolbar-refresh"; onClicked: Api.fetchTimeline() }
    }
}
