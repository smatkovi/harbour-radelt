import QtQuick 1.1
import com.nokia.meego 1.0
import com.nokia.extras 1.0

// Ein Ziel anlegen oder ändern. Das Datum geht als reines yyyy-MM-dd zum
// Dienst -- mit Uhrzeit stürzt die Route ab.
Sheet {
    id: sheet

    property variant ziel: ({})
    property date von: new Date()
    property date bis: new Date()

    function oeffnen(vorlage) {
        ziel = vorlage ? vorlage : ({})
        name.text = ziel.name ? ziel.name : ""
        km.text = ziel.distance ? String(Math.round(ziel.distance)) : ""
        beschreibung.text = ziel.description ? ziel.description : ""
        von = ziel.dateStart ? new Date(ziel.dateStart) : new Date()
        bis = ziel.dateEnd ? new Date(ziel.dateEnd)
                           : new Date(new Date().getTime() + 90 * 86400000)
        open()
    }

    acceptButtonText: qsTr("Speichern")
    rejectButtonText: qsTr("Abbrechen")

    content: Flickable {
        anchors.fill: parent
        contentHeight: felder.height

        Column {
            id: felder
            width: parent.width
            spacing: 12

            Item { width: 1; height: 8 }

            Label { x: 16; text: qsTr("Name des Ziels") }
            TextField { id: name; x: 16; width: parent.width - 32
                        placeholderText: qsTr("Im Oktober 200 km") }

            Label { x: 16; text: qsTr("Kilometer") }
            TextField { id: km; x: 16; width: parent.width - 32
                        inputMethodHints: Qt.ImhFormattedNumbersOnly }

            Label { x: 16; text: qsTr("Beschreibung") }
            TextArea { id: beschreibung; x: 16; width: parent.width - 32 }

            Button {
                x: 16; width: parent.width - 32
                text: qsTr("Von: %1").arg(Format.day(sheet.von))
                onClicked: vonWahl.open()
            }
            Button {
                x: 16; width: parent.width - 32
                text: qsTr("Bis: %1").arg(Format.day(sheet.bis))
                onClicked: bisWahl.open()
            }
        }
    }

    DatePickerDialog {
        id: vonWahl
        titleText: qsTr("Beginn")
        acceptButtonText: qsTr("Übernehmen")
        onAccepted: sheet.von = new Date(vonWahl.year, vonWahl.month - 1, vonWahl.day)
    }
    DatePickerDialog {
        id: bisWahl
        titleText: qsTr("Ende")
        acceptButtonText: qsTr("Übernehmen")
        onAccepted: sheet.bis = new Date(bisWahl.year, bisWahl.month - 1, bisWahl.day)
    }

    onAccepted: {
        var k = parseFloat(km.text.replace(",", "."))
        if (name.text.length === 0 || !(k > 0))
            return
        Api.saveGoal(name.text, beschreibung.text, k, sheet.von, sheet.bis,
                     sheet.ziel.id ? sheet.ziel.id : 0)
    }
}
