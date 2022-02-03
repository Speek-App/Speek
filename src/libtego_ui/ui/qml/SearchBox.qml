import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.2
import im.ricochet 1.0

TextArea {
    id: searchBox
    font.pointSize: styleHelper.pointSize * 0.9
    frameVisible: true
    backgroundVisible: false
    textMargin: 5
    wrapMode: TextEdit.Wrap
    textFormat: TextEdit.PlainText
    flickableItem.interactive: false

    property string placeholderText: "Search"

    Text {
        x: 5
        y: 2
        font.pointSize: styleHelper.pointSize * 0.9
        text: searchBox.placeholderText
        color: "#aaa"
        visible: !searchBox.text
    }

    font.family: "Helvetica"
    textColor: palette.text

    style: TextAreaStyle {
            frame: Rectangle {
            radius: 8
            color: palette.window
        }
    }
}
