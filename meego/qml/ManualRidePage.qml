import QtQuick 1.1
import com.nokia.meego 1.0
import com.nokia.extras 1.0

// Kilometres without a recording -- the way most entries on radelt.at are
// made, and the only way for a ride the phone did not come along on.
Page {
    id: page
    tools: manualTools

    property date chosenDate: new Date()

    Header { id: header; text: qsTr("Fahrt eintragen") }

    Column {
        anchors.top: header.bottom
        anchors.topMargin: 24
        width: parent.width
        spacing: 16

        Button {
            x: 16
            width: parent.width - 32
            text: qsTr("Tag: %1").arg(Format.day(page.chosenDate))
            onClicked: dayPicker.open()
        }

        Label { x: 16; text: qsTr("Kilometer") }
        TextField {
            id: kmField
            x: 16
            width: parent.width - 32
            inputMethodHints: Qt.ImhFormattedNumbersOnly
        }

        Label { x: 16; text: qsTr("Name der Fahrt") }
        TextField {
            id: titleField
            x: 16
            width: parent.width - 32
            placeholderText: qsTr("Zur Arbeit")
        }

        Row {
            x: 16
            spacing: 16
            Switch {
                id: uploadSwitch
                checked: Api.loggedIn && Settings.uploadAutomatically
                enabled: Api.loggedIn
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Gleich übertragen")
            }
        }
    }

    DatePickerDialog {
        id: dayPicker
        titleText: qsTr("Tag der Fahrt")
        acceptButtonText: qsTr("Übernehmen")
        rejectButtonText: qsTr("Abbrechen")
        onAccepted: page.chosenDate = new Date(dayPicker.year, dayPicker.month - 1, dayPicker.day)
    }

    ToolBarLayout {
        id: manualTools

        ToolIcon { iconId: "toolbar-back"; onClicked: pageStack.pop() }

        Button {
            width: 200
            text: qsTr("Eintragen")
            enabled: parseFloat(kmField.text.replace(",", ".")) > 0
            onClicked: {
                var id = Rides.addManual(page.chosenDate,
                                         parseFloat(kmField.text.replace(",", ".")),
                                         titleField.text, "", "")
                if (id.length > 0 && uploadSwitch.checked)
                    Api.uploadRide(id)
                pageStack.pop()
            }
        }
    }
}
