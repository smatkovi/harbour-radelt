import QtQuick 2.0
import Sailfish.Silica 1.0

// One number with its unit underneath -- the whole page is made of these.
Column {
    property string value: "0"
    property string unit: ""
    property bool large: false

    Label {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: large ? Theme.fontSizeHuge : Theme.fontSizeLarge
        color: Theme.highlightColor
        text: value
    }
    Label {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.secondaryColor
        wrapMode: Text.Wrap
        text: unit
    }
}
