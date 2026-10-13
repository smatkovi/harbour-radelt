import QtQuick 2.0
import Sailfish.Silica 1.0

// Die kurze Rueckmeldung am unteren Rand. Bis 0.8.3 sagte die App auf
// Sailfish zu einer Uebertragung gar nichts -- man tippte und sah nicht,
// ob es gegangen war. Bewusst ein Teil der Seite und kein Streifen im
// Anwendungsfenster: wie Silica das Fenster schichtet, ist nichts, was
// man ungeprueft annehmen sollte.
Label {
    id: hinweis

    function zeige(text) {
        hinweis.text = text
        hinweis.visible = true
        weg.restart()
    }

    anchors.bottom: parent.bottom
    anchors.bottomMargin: Theme.paddingLarge
    anchors.horizontalCenter: parent.horizontalCenter
    width: parent.width - 2 * Theme.horizontalPageMargin
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.Wrap
    font.pixelSize: Theme.fontSizeSmall
    color: palette.highlightColor
    visible: false

    Timer { id: weg; interval: 6000; onTriggered: hinweis.visible = false }

    // Beide Schritte einer Uebertragung melden sich hier: die Fahrt kann
    // oben sein und die Spur fehlen.
    Connections {
        target: Api
        onRideUploaded: hinweis.zeige(ok
            ? qsTr("Fahrt übertragen – jetzt kommt die Spur")
            : qsTr("Fahrt nicht übertragen: %1").arg(message))
        onTrackUploaded: hinweis.zeige(ok
            ? qsTr("Spur übertragen – die Fahrt ist vollständig oben")
            : qsTr("Fahrt ist oben, die Spur nicht: %1").arg(message))
    }
}
