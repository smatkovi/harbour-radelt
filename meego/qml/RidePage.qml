import QtQuick 1.1
import com.nokia.meego 1.0

Page {
    id: page
    tools: rideTools

    property string rideId
    property variant ride: Rides.ride(rideId)

    Header {
        id: header
        text: page.ride.title.length > 0 ? page.ride.title
                                         : Format.dayAndTime(page.ride.start)
    }

    Column {
        anchors.top: header.bottom
        anchors.topMargin: 24
        width: parent.width
        spacing: 12

        BigNumber {
            width: parent.width
            large: true
            value: Format.kilometres(page.ride.distance)
            unit: qsTr("Kilometer")
        }

        Detail { label: qsTr("Beginn"); value: Format.dayAndTime(page.ride.start) }
        Detail {
            visible: !page.ride.manual
            label: qsTr("In Bewegung"); value: Format.duration(page.ride.movingSeconds)
        }
        Detail {
            visible: !page.ride.manual
            label: qsTr("Höhenmeter"); value: Format.metres(page.ride.ascent)
        }
        Detail {
            label: qsTr("Übertragen")
            value: page.ride.uploaded ? qsTr("ja") : qsTr("nein")
        }

        Label {
            x: 16
            width: parent.width - 32
            wrapMode: Text.WordWrap
            font.pixelSize: 20
            color: "#8c8c8c"
            visible: page.ride.note.length > 0
            text: page.ride.note
        }
    }

    ToolBarLayout {
        id: rideTools

        ToolIcon { iconId: "toolbar-back"; onClicked: pageStack.pop() }

        Button {
            width: 200
            visible: !page.ride.uploaded && Api.loggedIn
            text: qsTr("Übertragen")
            onClicked: Api.uploadRide(page.rideId)
        }

        ToolIcon {
            iconId: "toolbar-delete"
            onClicked: removeQuery.open()
        }
    }

    QueryDialog {
        id: removeQuery
        titleText: qsTr("Fahrt löschen?")
        message: qsTr("Die Fahrt wird vom Telefon gelöscht. Was schon übertragen wurde, bleibt auf radelt.at.")
        acceptButtonText: qsTr("Löschen")
        rejectButtonText: qsTr("Behalten")
        onAccepted: {
            // Was schon uebertragen ist, auch dort wegnehmen.
            if (page.ride.uploaded && page.ride.remoteId > 0)
                Api.deleteRemoteRide(page.ride.remoteId)
            Rides.remove(page.rideId)
            pageStack.pop()
        }
    }

    Connections {
        target: Rides
        onCountChanged: page.ride = Rides.ride(page.rideId)
    }
}
