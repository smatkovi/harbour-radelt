import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.KeepAlive 1.2
import "pages"
import "cover"

ApplicationWindow
{
    id: app

    initialPage: Component { MainPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    // Sailfish does not freeze a running application, so the recording
    // survives a dark screen on its own. Blanking is only held off when the
    // rider wants to watch the numbers -- holding it always would eat the
    // battery the ride needs.
    DisplayBlanking {
        preventBlanking: Settings.keepDisplayOn && Recorder.recording
    }

    Component.onCompleted: {
        if (!Api.loggedIn && Settings.email.length > 0)
            Api.resume()
    }
}
