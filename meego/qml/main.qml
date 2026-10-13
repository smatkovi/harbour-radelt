import QtQuick 1.1
import com.nokia.meego 1.0
import com.nokia.extras 1.0   // InfoBanner

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
            banner.text = ok ? qsTr("Fahrt übertragen – jetzt kommt die Spur")
                             : qsTr("Fahrt nicht übertragen: %1").arg(message)
            banner.show()
        }
        // Die Fahrt zaehlt schon, wenn nur die Spur scheitert -- das muss
        // anders klingen, sonst schickt man sie doppelt.
        // Auch den Erfolg melden: sonst tippt man "Spur nachsenden" und
        // sieht nicht, ob etwas passiert ist.
        onTrackUploaded: {
            banner.text = ok ? qsTr("Spur übertragen – die Fahrt ist vollständig oben")
                             : qsTr("Fahrt ist oben, die Spur nicht: %1").arg(message)
            banner.show()
        }
    }

    function showMessage(text) {
        banner.text = text
        banner.show()
    }
}
