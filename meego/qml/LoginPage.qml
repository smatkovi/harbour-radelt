import QtQuick 1.1
import com.nokia.meego 1.0

// The same two fields as the website. Only the token the server hands back
// is kept, never the password.
Page {
    id: page
    tools: loginTools

    Header { id: header; text: qsTr("Anmelden") }

    Column {
        anchors.top: header.bottom
        anchors.topMargin: 24
        width: parent.width
        spacing: 16

        Label { x: 16; text: qsTr("E-Mail oder Benutzername") }
        TextField {
            id: userField
            x: 16
            width: parent.width - 32
            text: Settings.email
            inputMethodHints: Qt.ImhEmailCharactersOnly | Qt.ImhNoAutoUppercase
        }

        Label { x: 16; text: qsTr("Passwort") }
        TextField {
            id: passwordField
            x: 16
            width: parent.width - 32
            echoMode: TextInput.Password
        }

        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 48
            text: qsTr("Anmelden")
            enabled: !Api.busy && userField.text.length > 0 && passwordField.text.length > 0
            onClicked: Api.login(userField.text, passwordField.text)
        }

        BusyIndicator {
            anchors.horizontalCenter: parent.horizontalCenter
            running: Api.busy
            visible: Api.busy
            platformStyle: BusyIndicatorStyle { size: "medium" }
        }

        Label {
            x: 16
            width: parent.width - 32
            wrapMode: Text.WordWrap
            color: "#ff4040"
            visible: Api.lastError.length > 0
            text: Api.lastError
        }

        Label {
            x: 16
            width: parent.width - 32
            wrapMode: Text.WordWrap
            font.pixelSize: 20
            color: "#8c8c8c"
            text: qsTr("Das Konto ist dasselbe wie auf radelt.at. Angelegt wird es dort, nicht hier.")
        }
    }

    ToolBarLayout {
        id: loginTools
        ToolIcon { iconId: "toolbar-back"; onClicked: pageStack.pop() }
    }

    Connections {
        target: Api
        onLoggedInChanged: if (Api.loggedIn) pageStack.pop()
    }
}
