import QtQuick 1.1
import com.nokia.meego 1.0

// Die Räder des Kontos. Ein Rad mit Fahrten lässt sich nicht löschen, nur
// stilllegen -- das sagt der Server mit canBeDeleted.
Page {
    id: page
    tools: tools

    Component.onCompleted: Api.refresh()

    Header { id: header; text: qsTr("Meine Räder") }

    ListView {
        id: list
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        clip: true
        model: Api.bikeList

        delegate: Item {
            width: list.width
            height: 76

            Column {
                anchors.verticalCenter: parent.verticalCenter
                x: 16
                width: parent.width - 100
                Label {
                    width: parent.width
                    elide: Text.ElideRight
                    text: modelData.name ? modelData.name : qsTr("Rad")
                }
                Label {
                    width: parent.width
                    font.pixelSize: 18
                    color: Farben.grau
                    elide: Text.ElideRight
                    text: (modelData.isMain ? qsTr("Hauptrad") : qsTr("Weiteres Rad"))
                          + (modelData.isEbike ? " · " + qsTr("E-Bike") : "")
                          + (modelData.isActive === false ? " · " + qsTr("stillgelegt") : "")
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: bearbeiten.oeffnen(modelData)
                onPressAndHold: if (!modelData.isMain) {
                    var b = {}
                    for (var k in modelData) b[k] = modelData[k]
                    b.isMain = true
                    Api.saveBike(b)
                    appWindow.showMessage(qsTr("Als Hauptrad gesetzt"))
                }
            }
        }
    }

    Label {
        anchors.centerIn: list
        width: parent.width - 64
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        color: Farben.grau
        visible: list.count === 0
        text: Api.loggedIn ? qsTr("Keine Räder. Über das Menü eines anlegen.")
                           : qsTr("Nicht angemeldet")
    }

    ScrollDecorator { flickableItem: list }

    BikeSheet { id: bearbeiten }

    ToolBarLayout {
        id: tools
        ToolIcon { iconId: "toolbar-back"; onClicked: pageStack.pop() }
        ToolIcon { iconId: "toolbar-add"; onClicked: bearbeiten.oeffnen({}) }
    }
}
