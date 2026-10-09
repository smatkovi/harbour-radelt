import QtQuick 2.0
import Sailfish.Silica 1.0

// Ein Rad anlegen oder ändern. Ein leeres `bike` heißt: neues Rad.
Dialog {
    id: dialog

    property var bike: ({})

    canAccept: nameField.text.length > 0

    Column {
        width: parent.width

        DialogHeader {
            acceptText: dialog.bike.id ? qsTr("Speichern") : qsTr("Anlegen")
        }

        TextField {
            id: nameField
            width: parent.width
            label: qsTr("Bezeichnung")
            placeholderText: qsTr("Mein Rad")
            text: dialog.bike.name ? dialog.bike.name : ""
            EnterKey.iconSource: "image://theme/icon-m-enter-close"
            EnterKey.onClicked: focus = false
        }

        TextSwitch {
            id: ebikeSwitch
            text: qsTr("E-Bike")
            checked: dialog.bike.isEbike === true
        }

        TextSwitch {
            id: mainSwitch
            text: qsTr("Hauptrad")
            description: qsTr("Fahrten ohne eigene Radwahl zählen hierauf")
            checked: dialog.bike.isMain === true
            enabled: dialog.bike.isMain !== true
        }
    }

    onAccepted: {
        var b = {}
        for (var k in dialog.bike) b[k] = dialog.bike[k]
        b.name = nameField.text
        b.isEbike = ebikeSwitch.checked
        b.isMain = mainSwitch.checked
        Api.saveBike(b)
    }
}
