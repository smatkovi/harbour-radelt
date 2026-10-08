import QtQuick 1.1
import com.nokia.meego 1.0

PageStackWindow {
    id: appWindow

    initialPage: MainPage { }
    showStatusBar: true
    showToolBar: true

    // The dark theme is the one the stock applications use at night and the
    // one the red of the app icon sits in best. theme.inverted is global on
    // Harmattan, platform chrome included.
    Component.onCompleted: {
        theme.inverted = true
        if (!Api.loggedIn && Settings.email.length > 0)
            Api.resume()
    }

    InfoBanner {
        id: banner
        timerShowTime: 4000
    }

    Connections {
        target: Api
        onRideUploaded: {
            banner.text = ok ? qsTr("Fahrt übertragen")
                             : qsTr("Nicht übertragen: %1").arg(message)
            banner.show()
        }
    }

    function showMessage(text) {
        banner.text = text
        banner.show()
    }
}
