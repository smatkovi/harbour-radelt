import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

ThemedPage {
    id: page

    allowedOrientations: Orientation.All

    SilicaListView {
        id: list
        anchors.fill: parent
        model: Rides

        header: Column {
            width: list.width

            PageHeader {
                title: "Österreich radelt"
                description: Api.loggedIn ? Api.displayName : qsTr("nicht angemeldet")
            }

            // The two numbers a rider opens the app for.
            Row {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                BigNumber {
                    width: parent.width / 2
                    value: Format.kilometres(Rides.todayDistance)
                    unit: qsTr("km heute")
                }
                BigNumber {
                    width: parent.width / 2
                    value: Format.kilometres(Rides.seasonDistance)
                    unit: qsTr("km in der Saison")
                }
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Recorder.recording ? qsTr("Aufzeichnung ansehen") : qsTr("Fahrt aufzeichnen")
                onClicked: pageStack.push(Qt.resolvedUrl("RecordPage.qml"))
            }

            Item { width: 1; height: Theme.paddingLarge }

            SectionHeader { text: qsTr("Meine Fahrten") }
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Mein Profil")
                onClicked: pageStack.push(Qt.resolvedUrl("ProfilePage.qml"))
            }
            MenuItem {
                text: qsTr("Neuigkeiten")
                onClicked: pageStack.push(Qt.resolvedUrl("NewsPage.qml"))
            }
            MenuItem {
                text: qsTr("Einstellungen")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
            MenuItem {
                text: qsTr("Meine Ziele")
                onClicked: pageStack.push(Qt.resolvedUrl("GoalsPage.qml"))
            }
            MenuItem {
                text: qsTr("Aktionen")
                onClicked: pageStack.push(Qt.resolvedUrl("ChallengesPage.qml"))
            }
            MenuItem {
                text: qsTr("Fahrtenbuch")
                onClicked: pageStack.push(Qt.resolvedUrl("FahrtenbuchPage.qml"))
            }
            MenuItem {
                text: qsTr("Orte sammeln")
                onClicked: pageStack.push(Qt.resolvedUrl("OrtePage.qml"))
            }
            MenuItem {
                text: qsTr("Übersicht")
                onClicked: pageStack.push(Qt.resolvedUrl("OverviewPage.qml"))
            }
            MenuItem {
                text: qsTr("Verlauf")
                onClicked: pageStack.push(Qt.resolvedUrl("TimelinePage.qml"))
            }
            MenuItem {
                text: qsTr("Für wen ich fahre")
                onClicked: pageStack.push(Qt.resolvedUrl("OrganisationsPage.qml"))
            }
            MenuItem {
                text: qsTr("Community")
                onClicked: pageStack.push(Qt.resolvedUrl("CommunityPage.qml"))
            }
            MenuItem {
                text: qsTr("Meine Räder")
                onClicked: pageStack.push(Qt.resolvedUrl("BikesPage.qml"))
            }
            MenuItem {
                text: Api.loggedIn ? qsTr("Abmelden") : qsTr("Anmelden")
                onClicked: {
                    if (Api.loggedIn)
                        Api.logout()
                    else
                        pageStack.push(Qt.resolvedUrl("LoginPage.qml"))
                }
            }
            MenuItem {
                text: qsTr("Fahrt eintragen")
                onClicked: pageStack.push(Qt.resolvedUrl("ManualRidePage.qml"))
            }
            MenuItem {
                visible: Api.loggedIn && Rides.pendingCount > 0
                text: qsTr("%n Fahrt(en) übertragen", "", Rides.pendingCount)
                onClicked: Api.uploadPending()
            }
        }

        delegate: ListItem {
            id: item
            contentHeight: Theme.itemSizeMedium
            width: list.width

            Column {
                x: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 2 * Theme.horizontalPageMargin

                Label {
                    width: parent.width
                    text: title.length > 0 ? title : Format.dayAndTime(start)
                    truncationMode: TruncationMode.Fade
                    color: item.highlighted ? palette.highlightColor : palette.primaryColor
                }
                Label {
                    width: parent.width
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: item.highlighted ? palette.secondaryHighlightColor : palette.secondaryColor
                    text: Format.kilometres(distance) + " km · "
                          + Format.duration(movingSeconds > 0 ? movingSeconds : totalSeconds)
                          + (manual ? " · " + qsTr("eingetragen") : "")
                          + (uploaded ? "" : " · " + qsTr("nicht übertragen"))
                }
            }

            onClicked: pageStack.push(Qt.resolvedUrl("RidePage.qml"), { rideId: rideId })

            menu: ContextMenu {
                MenuItem {
                    visible: !uploaded && Api.loggedIn
                    text: qsTr("Übertragen")
                    onClicked: Api.uploadRide(rideId)
                }
                MenuItem {
                    text: qsTr("Löschen")
                    onClicked: item.remorseAction(qsTr("Fahrt löschen"),
                                                  function() { Rides.remove(rideId) })
                }
            }
        }

        ViewPlaceholder {
            enabled: list.count === 0
            text: qsTr("Noch keine Fahrt")
            hintText: qsTr("Mit „Fahrt aufzeichnen“ anfangen oder über das Menü eine Fahrt eintragen")
        }

        VerticalScrollDecorator { }
    }
}
