import QtQuick 1.1
import com.nokia.meego 1.0

// The page title the stock applications wear: a band of the highlight
// colour with the name in it.
Rectangle {
    property alias text: label.text

    width: parent.width
    height: 72
    color: Farben.rot

    Label {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        x: 16
        width: parent.width - 32
        elide: Text.ElideRight
        font.pixelSize: 28
        color: Farben.weiss
    }
}
