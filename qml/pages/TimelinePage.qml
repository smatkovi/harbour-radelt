import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

// Der Verlauf: was das Konto als Ereignisse führt (Kilometer, Orte, Ziele,
// Radeltage), und darüber die Trophäen. Beides kommt vom Server; die
// lokalen Fahrten stehen auf der Startseite.
ThemedPage {
    allowedOrientations: Orientation.All

    onStatusChanged: if (status === PageStatus.Active) Api.fetchTimeline()

    SilicaListView {
        id: list
        anchors.fill: parent
        model: Api.timeline

        PullDownMenu {
            MenuItem { text: qsTr("Aktualisieren"); onClicked: Api.fetchTimeline() }
        }

        header: Column {
            width: list.width

            PageHeader { title: qsTr("Verlauf") }

            SectionHeader {
                text: qsTr("Trophäen")
                visible: true
            }

            // Trophäen quer, damit auch zehn Stück noch auf den Schirm
            // passen, ohne den Verlauf nach unten zu drücken.
            SilicaListView {
                width: parent.width
                height: Api.trophies.length > 0 ? Theme.itemSizeExtraLarge : 0
                orientation: ListView.Horizontal
                model: Api.trophies
                visible: Api.trophies.length > 0
                spacing: Theme.paddingMedium
                leftMargin: Theme.horizontalPageMargin
                clip: true

                delegate: Column {
                    width: Theme.itemSizeLarge
                    height: parent.height
                    spacing: Theme.paddingSmall

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Theme.iconSizeMedium
                        height: width
                        radius: width / 2
                        color: Farben.rot
                        Label {
                            anchors.centerIn: parent
                            color: Farben.weiss
                            font.pixelSize: Theme.fontSizeLarge
                            text: "★"
                        }
                    }
                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Theme.fontSizeTiny
                        color: palette.secondaryColor
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        text: modelData.name ? modelData.name
                                             : (modelData.title ? modelData.title : qsTr("Trophäe"))
                    }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                font.pixelSize: Theme.fontSizeExtraSmall
                color: palette.secondaryColor
                wrapMode: Text.Wrap
                visible: Api.trophies.length === 0
                text: Api.loggedIn ? qsTr("Noch keine Trophäe.") : qsTr("Nicht angemeldet")
            }

            SectionHeader { text: qsTr("Ereignisse") }
        }

        delegate: ListItem {
            contentHeight: Theme.itemSizeSmall
            width: list.width

            Column {
                x: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 2 * Theme.horizontalPageMargin

                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
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
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: palette.secondaryColor
                    text: {
                        var d = modelData.date || modelData.created_at || modelData.createdAt
                        return d ? d : ""
                    }
                }
            }
        }

        ViewPlaceholder {
            enabled: list.count === 0
            text: qsTr("Kein Verlauf")
            hintText: Api.loggedIn ? qsTr("Sobald Fahrten gezählt sind, steht hier etwas")
                                   : qsTr("Dafür erst anmelden")
        }

        VerticalScrollDecorator { }
    }
}
