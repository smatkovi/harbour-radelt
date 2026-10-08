import QtQuick 2.0
import Sailfish.Silica 1.0

// Kilometres without a recording -- the way most entries on radelt.at are
// made, and the only way for a ride the phone did not come along on.
Dialog {
    id: dialog

    property var chosenDate: new Date()

    canAccept: parseFloat(kmField.text.replace(",", ".")) > 0

    Column {
        width: parent.width

        DialogHeader { acceptText: qsTr("Eintragen") }

        ValueButton {
            label: qsTr("Tag")
            value: Format.day(dialog.chosenDate)
            onClicked: {
                var picker = pageStack.push("Sailfish.Silica.DatePickerDialog",
                                            { date: dialog.chosenDate })
                picker.accepted.connect(function() { dialog.chosenDate = picker.date })
            }
        }

        TextField {
            id: kmField
            width: parent.width
            label: qsTr("Kilometer")
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            placeholderText: qsTr("Kilometer")
            EnterKey.iconSource: "image://theme/icon-m-enter-next"
            EnterKey.onClicked: titleField.focus = true
        }

        TextField {
            id: titleField
            width: parent.width
            label: qsTr("Name der Fahrt")
            placeholderText: qsTr("Zur Arbeit")
        }

        TextSwitch {
            id: uploadSwitch
            text: qsTr("Gleich übertragen")
            checked: Api.loggedIn && Settings.uploadAutomatically
            enabled: Api.loggedIn
        }
    }

    onAccepted: {
        var id = Rides.addManual(dialog.chosenDate,
                                 parseFloat(kmField.text.replace(",", ".")),
                                 titleField.text, "", "")
        if (id.length > 0 && uploadSwitch.checked)
            Api.uploadRide(id)
    }
}
