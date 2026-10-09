import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

ThemedPage {
    id: page

    property string rideId
    property var ride: Rides.ride(rideId)

    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                visible: !page.ride.uploaded && Api.loggedIn
                text: qsTr("Übertragen")
                onClicked: Api.uploadRide(page.rideId)
            }
            MenuItem {
                text: qsTr("Löschen")
                onClicked: {
                    // Was schon übertragen ist, auch dort wegnehmen --
                    // sonst zählt es auf radelt.at weiter.
                    if (page.ride.uploaded && page.ride.remoteId > 0)
                        Api.deleteRemoteRide(page.ride.remoteId)
                    Rides.remove(page.rideId)
                    pageStack.pop()
                }
            }
        }

        Column {
            id: column
            width: page.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: page.ride.title.length > 0 ? page.ride.title
                                                  : Format.dayAndTime(page.ride.start)
            }

            BigNumber {
                width: parent.width
                large: true
                value: Format.kilometres(page.ride.distance)
                unit: qsTr("Kilometer")
            }

            DetailItem {
                label: qsTr("Beginn")
                value: Format.dayAndTime(page.ride.start)
            }
            DetailItem {
                visible: !page.ride.manual
                label: qsTr("In Bewegung")
                value: Format.duration(page.ride.movingSeconds)
            }
            DetailItem {
                visible: !page.ride.manual
                label: qsTr("Unterwegs")
                value: Format.duration(page.ride.totalSeconds)
            }
            DetailItem {
                visible: !page.ride.manual
                label: qsTr("Höhenmeter")
                value: Format.metres(page.ride.ascent)
            }
            DetailItem {
                visible: page.ride.bike.length > 0
                label: qsTr("Rad")
                value: page.ride.bike
            }
            DetailItem {
                label: qsTr("Übertragen")
                value: page.ride.uploaded ? qsTr("ja") : qsTr("nein")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                visible: page.ride.note.length > 0
                color: palette.secondaryColor
                text: page.ride.note
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: palette.secondaryColor
                visible: !page.ride.manual
                text: qsTr("Die Strecke liegt als GPX unter %1").arg(Rides.gpxPath(page.rideId))
            }
        }
    }

    Connections {
        target: Rides
        onCountChanged: page.ride = Rides.ride(page.rideId)
    }
}
