import QtQuick 2.0
import Sailfish.Silica 1.0

// Ein Ziel anlegen oder ändern. Das Datum geht als reines yyyy-MM-dd zum
// Dienst — mit Uhrzeit stürzt die Route ab.
Dialog {
    id: dialog

    property var ziel: ({})
    property date von: ziel.dateStart ? new Date(ziel.dateStart) : new Date()
    property date bis: ziel.dateEnd ? new Date(ziel.dateEnd)
                                    : new Date(new Date().getTime() + 90 * 86400000)

    canAccept: name.text.length > 0 && parseFloat(km.text.replace(",", ".")) > 0

    Column {
        width: parent.width

        DialogHeader { acceptText: dialog.ziel.id ? qsTr("Speichern") : qsTr("Anlegen") }

        TextField {
            id: name
            width: parent.width
            label: qsTr("Name des Ziels")
            placeholderText: qsTr("Im Oktober 200 km")
            text: dialog.ziel.name ? dialog.ziel.name : ""
        }

        TextField {
            id: km
            width: parent.width
            label: qsTr("Kilometer")
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            text: dialog.ziel.distance ? String(Math.round(dialog.ziel.distance)) : ""
        }

        TextArea {
            id: beschreibung
            width: parent.width
            label: qsTr("Beschreibung")
            text: dialog.ziel.description ? dialog.ziel.description : ""
        }

        ValueButton {
            label: qsTr("Von")
            value: Format.day(dialog.von)
            onClicked: {
                var p = pageStack.push("Sailfish.Silica.DatePickerDialog", { date: dialog.von })
                p.accepted.connect(function() { dialog.von = p.date })
            }
        }

        ValueButton {
            label: qsTr("Bis")
            value: Format.day(dialog.bis)
            onClicked: {
                var p = pageStack.push("Sailfish.Silica.DatePickerDialog", { date: dialog.bis })
                p.accepted.connect(function() { dialog.bis = p.date })
            }
        }
    }

    onAccepted: Api.saveGoal(name.text, beschreibung.text,
                             parseFloat(km.text.replace(",", ".")),
                             dialog.von, dialog.bis,
                             dialog.ziel.id ? dialog.ziel.id : 0)
}
