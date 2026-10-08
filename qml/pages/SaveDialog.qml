import QtQuick 2.0
import Sailfish.Silica 1.0

// Shown when the rider ends a ride: name it, say which bike, and let it go
// up. Cancelling keeps the recording running -- a slip of the thumb must
// not throw away an hour of riding.
Dialog {
    id: dialog

    canAccept: true
    acceptDestination: pageStack.previousPage(pageStack.previousPage())
    acceptDestinationAction: PageStackAction.Pop

    DialogHeader {
        id: header
        acceptText: qsTr("Speichern")
        cancelText: qsTr("Weiterfahren")
    }

    Column {
        anchors.top: header.bottom
        width: parent.width

        TextField {
            id: titleField
            width: parent.width
            label: qsTr("Name der Fahrt")
            placeholderText: Format.dayAndTime(new Date())
            EnterKey.iconSource: "image://theme/icon-m-enter-next"
            EnterKey.onClicked: noteField.focus = true
        }

        ComboBox {
            id: bikeBox
            width: parent.width
            label: qsTr("Rad")
            menu: ContextMenu {
                Repeater {
                    model: Api.bikes.length > 0 ? Api.bikes : [ qsTr("Mein Rad") ]
                    MenuItem { text: modelData }
                }
            }
        }

        TextArea {
            id: noteField
            width: parent.width
            label: qsTr("Notiz")
        }

        TextSwitch {
            id: uploadSwitch
            text: qsTr("Gleich übertragen")
            checked: Api.loggedIn && Settings.uploadAutomatically
            enabled: Api.loggedIn
            description: Api.loggedIn ? "" : qsTr("Dafür erst anmelden")
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * Theme.horizontalPageMargin
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            wrapMode: Text.Wrap
            text: qsTr("%1 km · %2 · %3 Höhenmeter")
                  .arg(Format.kilometres(Recorder.distance))
                  .arg(Format.duration(Recorder.movingSeconds))
                  .arg(Format.metres(Recorder.ascent))
        }
    }

    onAccepted: {
        var id = Rides.saveRecording(titleField.text, bikeBox.value, noteField.text)
        Recorder.stop()
        Recorder.stopPositioning()
        if (id.length > 0 && uploadSwitch.checked)
            Api.uploadRide(id)
    }
}
