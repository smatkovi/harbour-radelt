import QtQuick 1.1
import com.nokia.meego 1.0

// Ein Rad anlegen oder ändern. Langes Tippen in der Liste macht das
// Hauptrad; hier steht alles andere.
Sheet {
    id: sheet

    property variant rad: ({})

    function oeffnen(vorlage) {
        rad = vorlage ? vorlage : ({})
        nameFeld.text = rad.name ? rad.name : ""
        ebike.checked = rad.isEbike === true
        haupt.checked = rad.isMain === true
        open()
    }

    acceptButtonText: qsTr("Speichern")
    rejectButtonText: qsTr("Abbrechen")

    content: Column {
        anchors.fill: parent
        spacing: 16

        Item { width: 1; height: 8 }

        Label { x: 16; text: qsTr("Bezeichnung") }
        TextField {
            id: nameFeld
            x: 16
            width: parent.width - 32
            placeholderText: qsTr("Mein Rad")
        }

        Row {
            x: 16
            spacing: 16
            Switch { id: ebike }
            Label { anchors.verticalCenter: parent.verticalCenter; text: qsTr("E-Bike") }
        }

        Row {
            x: 16
            spacing: 16
            Switch { id: haupt; enabled: sheet.rad.isMain !== true }
            Column {
                width: sheet.width - 120
                Label { text: qsTr("Hauptrad") }
                Label {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    font.pixelSize: 18
                    color: Farben.grau
                    text: qsTr("Fahrten ohne eigene Radwahl zählen hierauf")
                }
            }
        }
    }

    onAccepted: {
        if (nameFeld.text.length === 0)
            return
        var b = {}
        for (var k in sheet.rad) b[k] = sheet.rad[k]
        b.name = nameFeld.text
        b.isEbike = ebike.checked
        b.isMain = haupt.checked
        Api.saveBike(b)
    }
}
