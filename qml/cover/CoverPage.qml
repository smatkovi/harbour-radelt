import QtQuick 2.0
import Sailfish.Silica 1.0

// The cover shows what the rider wants without unlocking: the kilometres so
// far, and whether the recording is still running.
CoverBackground {
    Column {
        anchors.centerIn: parent
        width: parent.width - 2 * Theme.paddingMedium

        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSizeHuge
            color: Theme.highlightColor
            text: Recorder.recording ? Format.kilometres(Recorder.distance)
                                     : Format.kilometres(Rides.todayDistance)
        }
        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            text: Recorder.recording ? qsTr("km, läuft") : qsTr("km heute")
        }
        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.secondaryColor
            visible: Recorder.recording
            text: Format.duration(Recorder.movingSeconds)
        }
    }

    CoverActionList {
        enabled: Recorder.recording

        CoverAction {
            iconSource: Recorder.paused ? "image://theme/icon-cover-play"
                                        : "image://theme/icon-cover-pause"
            onTriggered: Recorder.paused = !Recorder.paused
        }
    }
}
