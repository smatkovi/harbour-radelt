import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

// The same two fields as the website: e-mail or user name, and password.
// The app keeps only the token the server hands back, never the password.
ThemedPage {
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            PageHeader { title: qsTr("Anmelden") }

            TextField {
                id: userField
                width: parent.width
                label: qsTr("E-Mail oder Benutzername")
                text: Settings.email
                inputMethodHints: Qt.ImhEmailCharactersOnly | Qt.ImhNoAutoUppercase
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: passwordField.focus = true
            }

            PasswordField {
                id: passwordField
                width: parent.width
                label: qsTr("Passwort")
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: login.clicked(null)
            }

            Button {
                id: login
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Anmelden")
                enabled: !Api.busy && userField.text.length > 0 && passwordField.text.length > 0
                onClicked: Api.login(userField.text, passwordField.text)
            }

            BusyIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                running: Api.busy
                size: BusyIndicatorSize.Medium
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                color: palette.errorColor
                visible: Api.lastError.length > 0
                text: Api.lastError
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: palette.secondaryColor
                text: qsTr("Das Konto ist dasselbe wie auf radelt.at. Angelegt wird es dort, nicht hier.")
            }
        }
    }

    Connections {
        target: Api
        onLoggedInChanged: if (Api.loggedIn) pageStack.pop()
    }
}
