import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

// Ein einzelner Ort zum Sammeln.
ThemedPage {
    id: page

    allowedOrientations: Orientation.All

    property var ort: null
    property string entfernung: ""

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: inhalt.height

        Column {
            id: inhalt
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: page.ort && page.ort.name ? page.ort.name : qsTr("Ort")
                description: page.ort && page.ort.routeName ? page.ort.routeName : ""
            }

            Image {
                width: parent.width
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                visible: status === Image.Ready
                source: page.ort && page.ort.image ? page.ort.image : ""
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                font.pixelSize: Theme.fontSizeExtraSmall
                color: palette.secondaryColor
                wrapMode: Text.Wrap
                visible: text.length > 0
                text: page.ort && page.ort.imageCredit ? page.ort.imageCredit : ""
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                textFormat: Text.RichText
                color: palette.primaryColor
                visible: text.length > 0
                text: page.ort && page.ort.description ? page.ort.description : ""
            }

            DetailItem {
                label: qsTr("Entfernung")
                value: page.entfernung
            }
            DetailItem {
                label: qsTr("Stand")
                value: page.ort && page.ort.collected ? qsTr("eingesammelt")
                                                      : qsTr("noch offen")
            }
            DetailItem {
                label: qsTr("Koordinaten")
                visible: page.ort !== null && page.ort.hasPosition
                value: page.ort && page.ort.hasPosition
                       ? page.ort.latitude.toFixed(5) + ", " + page.ort.longitude.toFixed(5)
                       : ""
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: page.ort && page.ort.externalLink
                text: qsTr("Mehr dazu im Netz")
                onClicked: Qt.openUrlExternally(page.ort.externalLink)
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: palette.secondaryColor
                text: qsTr("Eingesammelt wird vor Ort: auf der Orteseite „Hier "
                           + "einsammeln“ antippen. Ob du nah genug bist, "
                           + "entscheidet die Plattform.")
            }

            Item { width: 1; height: Theme.paddingLarge }
        }

        VerticalScrollDecorator { }
    }
}
