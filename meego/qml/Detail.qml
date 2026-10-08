import QtQuick 1.1
import com.nokia.meego 1.0

// A label and its value on one line, the way the stock detail pages set it.
Item {
    property alias label: name.text
    property alias value: content.text

    width: parent.width
    height: visible ? Math.max(name.height, content.height) + 8 : 0

    Label {
        id: name
        x: 16
        width: parent.width * 0.45 - 16
        font.pixelSize: 22
        color: "#8c8c8c"
        wrapMode: Text.WordWrap
    }
    Label {
        id: content
        x: parent.width * 0.45
        width: parent.width * 0.55 - 16
        font.pixelSize: 22
        wrapMode: Text.WordWrap
    }
}
