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
        // **Feste Höhe.** InfoBanner leitet seine implicitHeight aus
        // text.lineCount ab, während der Text seine Höhe über Anker aus
        // dem Banner nimmt -- ein Ringschluss. QML bricht ihn auf, das
        // Banner bleibt bei mehrzeiligem Text zu niedrig, und
        // getTopMargin() rechnet (height - paintedHeight)/2 ins Negative:
        // die erste Zeile wird oben abgeschnitten. 80 ist die Höhe, die
        // das Bauteil selbst für zwei Zeilen vorsieht.
        height: 80
    }

    Connections {
        target: Api
        onRideUploaded: {
            // Kurz halten: drei Zeilen schneidet InfoBanner wieder ab.
            // Der Wortlaut des Dienstes steht in Api.lastError und im
            // Protokoll.
            banner.text = ok ? qsTr("Fahrt übertragen")
                             : qsTr("Fahrt nicht übertragen")
            banner.show()
        }
        // Die Fahrt zaehlt schon, wenn nur die Spur scheitert -- das muss
        // anders klingen, sonst schickt man sie doppelt.
        // Auch den Erfolg melden: sonst tippt man "Spur nachsenden" und
        // sieht nicht, ob etwas passiert ist.
        onTrackUploaded: {
            banner.text = ok ? qsTr("Spur übertragen")
                             : qsTr("Spur nicht angekommen")
            banner.show()
        }
    }

    function showMessage(text) {
        banner.text = text
        banner.show()
    }
}
