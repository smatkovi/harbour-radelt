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
        // Der Akzent des gewählten Schemas: unter dem Hausschema das Rot,
        // unter "Ambience" die Systemfarbe.
        color: palette.highlightColor
        text: value
    }
    Label {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Theme.fontSizeExtraSmall
        color: palette.secondaryColor
        wrapMode: Text.Wrap
        text: unit
    }
}
