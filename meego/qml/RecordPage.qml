import QtQuick 1.1
import com.nokia.meego 1.0

Page {
    id: page
    tools: recordTools

    // The receiver runs while this page is open, even before the start.
    Component.onCompleted: Recorder.startPositioning()
    Component.onDestruction: if (!Recorder.recording) Recorder.stopPositioning()

    Header {
        id: header
        text: Recorder.recording
              ? (Recorder.paused ? qsTr("Pause") : qsTr("Fahrt läuft"))
              : qsTr("Aufzeichnen")
    }

    Column {
        anchors.top: header.bottom
        anchors.topMargin: 24
        width: parent.width
        spacing: 24

        BigNumber {
            width: parent.width
            large: true
            value: Format.kilometres(Recorder.distance)
            unit: qsTr("Kilometer")
        }

        Row {
            width: parent.width
            BigNumber {
                width: parent.width / 2
                value: Format.duration(Recorder.movingSeconds)
                unit: qsTr("in Bewegung")
            }
            BigNumber {
                width: parent.width / 2
                value: Format.speed(Recorder.averageSpeed)
                unit: qsTr("km/h im Schnitt")
            }
        }

        Row {
            width: parent.width
            BigNumber {
                width: parent.width / 2
                value: Format.metres(Recorder.ascent)
                unit: qsTr("Höhenmeter")
            }
            BigNumber {
                width: parent.width / 2
                value: Format.duration(Recorder.totalSeconds)
                unit: qsTr("unterwegs")
            }
        }

        Label {
            x: 24
            width: parent.width - 48
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.pixelSize: 20
            color: Recorder.accuracy > 0 && Recorder.accuracy <= 25 ? "#8c8c8c" : "#ff4040"
            text: !Recorder.sourceAvailable
                  ? qsTr("Kein Ortungsdienst auf diesem Gerät")
                  : Recorder.accuracy < 0
                    ? qsTr("wartet auf Satelliten …")
                    : qsTr("Genauigkeit %1 m").arg(Math.round(Recorder.accuracy))
        }
    }

    ToolBarLayout {
        id: recordTools

        ToolIcon {
            iconId: "toolbar-back"
            onClicked: pageStack.pop()
        }

        Button {
            width: 180
            text: Recorder.recording ? qsTr("Beenden") : qsTr("Start")
            onClicked: {
                if (Recorder.recording)
                    saveSheet.open()
                else
                    Recorder.start()
            }
        }

        Button {
            width: 150
            visible: Recorder.recording
            text: Recorder.paused ? qsTr("Weiter") : qsTr("Pause")
            onClicked: Recorder.paused = !Recorder.paused
        }
    }

    SaveSheet { id: saveSheet }
}
