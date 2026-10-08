import QtQuick 1.1
import com.nokia.meego 1.0

// Ending a ride: name it and let it go up. Rejecting keeps the recording
// running -- a slip of the thumb must not throw away an hour of riding.
Sheet {
    id: sheet

    acceptButtonText: qsTr("Speichern")
    rejectButtonText: qsTr("Weiterfahren")

    content: Flickable {
        anchors.fill: parent
        contentHeight: fields.height

        Column {
            id: fields
            width: parent.width
            spacing: 16

            Label { x: 16; text: qsTr("Name der Fahrt") }
            TextField {
                id: titleField
                x: 16
                width: parent.width - 32
                placeholderText: Format.dayAndTime(new Date())
            }

            Label { x: 16; text: qsTr("Notiz") }
            TextArea {
                id: noteField
                x: 16
                width: parent.width - 32
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

            Label {
                x: 16
                width: parent.width - 32
                wrapMode: Text.WordWrap
                font.pixelSize: 20
                color: "#8c8c8c"
                text: qsTr("%1 km · %2 · %3 Höhenmeter")
                      .arg(Format.kilometres(Recorder.distance))
                      .arg(Format.duration(Recorder.movingSeconds))
                      .arg(Format.metres(Recorder.ascent))
            }
        }
    }

    onAccepted: {
        var id = Rides.saveRecording(titleField.text, "", noteField.text)
        Recorder.stop()
        Recorder.stopPositioning()
        if (id.length > 0 && uploadSwitch.checked)
            Api.uploadRide(id)
        pageStack.pop()
    }
}
