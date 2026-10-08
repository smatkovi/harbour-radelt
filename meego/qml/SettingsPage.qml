import QtQuick 1.1
import com.nokia.meego 1.0

Page {
    id: page
    tools: settingsTools

    Header { id: header; text: qsTr("Einstellungen") }

    Column {
        anchors.top: header.bottom
        anchors.topMargin: 24
        width: parent.width
        spacing: 20

        Row {
            x: 16
            spacing: 16
            Switch {
                checked: Settings.uploadAutomatically
                onCheckedChanged: Settings.uploadAutomatically = checked
            }
            Column {
                width: page.width - 150
                Label { text: qsTr("Fahrten gleich übertragen") }
                Label {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    font.pixelSize: 20
                    color: "#8c8c8c"
                    text: qsTr("Sobald eine Fahrt gespeichert ist, geht sie zu radelt.at")
                }
            }
        }

        Column {
            x: 16
            width: parent.width - 32
            Label { text: qsTr("Punkte verwerfen ab %1 m").arg(Math.round(accuracySlider.value)) }
            Slider {
                id: accuracySlider
                width: parent.width
                minimum: 10
                maximum: 100
                stepSize: 5
                value: Settings.accuracyLimit
                onValueChanged: Settings.accuracyLimit = value
            }
        }

        Detail {
            label: qsTr("Angemeldet als")
            value: Api.loggedIn ? Api.displayName : qsTr("niemand")
        }

        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 48
            text: Api.loggedIn ? qsTr("Abmelden") : qsTr("Anmelden")
            onClicked: {
                if (Api.loggedIn)
                    Api.logout()
                else
                    pageStack.push(Qt.resolvedUrl("LoginPage.qml"))
            }
        }
    }

    ToolBarLayout {
        id: settingsTools
        ToolIcon { iconId: "toolbar-back"; onClicked: pageStack.pop() }
    }
}
