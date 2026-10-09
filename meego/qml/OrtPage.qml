import QtQuick 1.1
import com.nokia.meego 1.0

// Ein einzelner Ort zum Sammeln. Ohne Bild, siehe OrtePage.qml.
Page {
    id: page
    tools: werkzeuge

    property variant ort: null
    property string entfernung: ""

    Header {
        id: kopf
        text: page.ort && page.ort.name ? page.ort.name : qsTr("Ort")
    }

    Flickable {
        anchors.top: kopf.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        contentHeight: inhalt.height
        clip: true

        Column {
            id: inhalt
            width: page.width
            spacing: 6

            Item { width: 1; height: 8 }

            Label {
                x: 16
                width: parent.width - 32
                wrapMode: Text.WordWrap
                font.pixelSize: 18
                color: Farben.grau
                visible: text.length > 0
                text: page.ort && page.ort.routeName ? page.ort.routeName : ""
            }

            Label {
                x: 16
                width: parent.width - 32
                wrapMode: Text.WordWrap
                textFormat: Text.RichText
                visible: text.length > 0
                text: page.ort && page.ort.description ? page.ort.description : ""
            }

            Detail { label: qsTr("Entfernung"); value: page.entfernung }
            Detail {
                label: qsTr("Stand")
                value: page.ort && page.ort.collected ? qsTr("eingesammelt")
                                                      : qsTr("noch offen")
            }
            Detail {
                label: qsTr("Koordinaten")
                visible: page.ort !== null && page.ort.hasPosition
                value: page.ort && page.ort.hasPosition
                       ? page.ort.latitude.toFixed(5) + ", " + page.ort.longitude.toFixed(5)
                       : ""
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 32
                visible: page.ort !== null && page.ort.externalLink ? true : false
                text: qsTr("Mehr dazu im Netz")
                onClicked: Qt.openUrlExternally(page.ort.externalLink)
            }

            Label {
                x: 16
                width: parent.width - 32
                wrapMode: Text.WordWrap
                font.pixelSize: 18
                color: Farben.grau
                text: qsTr("Eingesammelt wird vor Ort: auf der Orteseite \"Hier "
                           + "einsammeln\" antippen. Ob du nah genug bist, "
                           + "entscheidet die Plattform.")
            }

            Item { width: 1; height: 16 }
        }
    }

    ToolBarLayout {
        id: werkzeuge
        ToolIcon { iconId: "toolbar-back"; onClicked: pageStack.pop() }
    }
}
