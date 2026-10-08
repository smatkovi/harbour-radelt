import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

Page {
    id: page

    allowedOrientations: Orientation.All

    // The receiver runs while this page is open, even before the start: a
    // ride started on a fresh fix begins in the wrong street.
    onStatusChanged: {
        if (status === PageStatus.Active)
            Recorder.startPositioning()
        else if (status === PageStatus.Inactive && !Recorder.recording)
            Recorder.stopPositioning()
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        Column {
            id: content
            width: page.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: Recorder.recording
                       ? (Recorder.paused ? qsTr("Pause") : qsTr("Fahrt läuft"))
                       : qsTr("Aufzeichnen")
            }

            BigNumber {
                width: parent.width
                large: true
                value: Format.kilometres(Recorder.distance)
                unit: qsTr("Kilometer")
            }

            Row {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin

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
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin

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

            // What the receiver is doing right now. A rider who sees
            // "wartet auf Satelliten" knows why the kilometres stand still.
            Item {
                width: parent.width
                height: satelliteLabel.height + Theme.paddingMedium

                Label {
                    id: satelliteLabel
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.Wrap
                    color: Recorder.accuracy > 0 && Recorder.accuracy <= 25
                           ? Theme.secondaryColor : Theme.errorColor
                    text: !Recorder.sourceAvailable
                          ? qsTr("Kein Ortungsdienst auf diesem Gerät")
                          : Recorder.accuracy < 0
                            ? qsTr("wartet auf Satelliten …")
                            : qsTr("Genauigkeit %1 m").arg(Math.round(Recorder.accuracy))
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingLarge

                Button {
                    text: Recorder.recording ? qsTr("Beenden") : qsTr("Start")
                    onClicked: {
                        if (Recorder.recording) {
                            pageStack.push(Qt.resolvedUrl("SaveDialog.qml"))
                        } else {
                            Recorder.start()
                        }
                    }
                }

                Button {
                    visible: Recorder.recording
                    text: Recorder.paused ? qsTr("Weiter") : qsTr("Pause")
                    onClicked: Recorder.paused = !Recorder.paused
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                wrapMode: Text.Wrap
                visible: Recorder.recording
                text: qsTr("%n Punkt(e) aufgezeichnet", "", Recorder.pointCount)
            }
        }
    }
}
