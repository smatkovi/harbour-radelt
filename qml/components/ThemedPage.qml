import QtQuick 2.0
import Sailfish.Silica 1.0

// Seite mit dem Hausfarbschema: Rot auf hellem oder auf dunklem Grund
// (Settings.colorTheme 1 / 2), oder die Systemfarben des gewählten
// Ambiente (0). Silica-Bauteile nehmen die Farben über die palette auf,
// eigene Elemente benutzen ebenfalls palette.*.
//
// Dasselbe Muster wie in Fahrplan AT -- dort hat es sich bewährt, und
// zwei Apps desselben Hauses sollen sich gleich anfühlen.
Page {
    id: themedPage

    readonly property int colorTheme: Settings.colorTheme
    readonly property bool customTheme: colorTheme !== 0
    readonly property bool lightTheme: colorTheme === 1
    // Das Rot der Marke, auf hellem Grund etwas tiefer, auf dunklem heller,
    // damit es in beiden Fällen gleich kräftig wirkt.
    readonly property color accentColor: lightTheme ? "#c00d0d" : "#e03a3a"
    // Schwarz heisst hier wirklich 000000, nicht "fast schwarz": auf dem
    // OLED bleiben die Pixel damit aus, und der Rand einer Seite fällt
    // nicht gegen den Hintergrund auf.
    readonly property color pageBackground: lightTheme ? "#f7f7f7" : "#000000"

    palette.colorScheme: customTheme ? (lightTheme ? Theme.DarkOnLight : Theme.LightOnDark) : Theme.colorScheme
    palette.primaryColor: customTheme ? (lightTheme ? "#1f1f1f" : "#ffffff") : Theme.primaryColor
    palette.secondaryColor: customTheme ? (lightTheme ? "#6a6a6a" : "#bababa") : Theme.secondaryColor
    palette.highlightColor: customTheme ? accentColor : Theme.highlightColor
    palette.secondaryHighlightColor: customTheme ? (lightTheme ? "#8a0909" : "#ff8a99") : Theme.secondaryHighlightColor
    palette.highlightBackgroundColor: customTheme ? accentColor : Theme.highlightBackgroundColor
    palette.highlightDimmerColor: customTheme ? (lightTheme ? "#7a0a1d" : "#3a0404") : Theme.highlightDimmerColor

    Rectangle {
        anchors.fill: parent
        visible: themedPage.customTheme
        color: themedPage.pageBackground
        z: -1
    }
}
