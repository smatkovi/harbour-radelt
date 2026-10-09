import QtQuick 1.1
import com.nokia.meego 1.0

Column {
    property string value: "0"
    property string unit: ""
    property bool large: false

    Label {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: large ? 72 : 40
        color: Farben.rot
        text: value
    }
    Label {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: 20
        color: Farben.grau
        wrapMode: Text.WordWrap
        text: unit
    }
}
