import QtQuick 2.0
import QtQuick.Controls.Styles 1.2

Rectangle {
    id: emojiCategoryButton
    property string categoryName
    property var fontSize

    signal clickedFunction(var b)

    function completedHandler() {
        categoryName = eCatName

        //initialize
        if (parent.currSelEmojiButton === undefined) {
            clickedHandler()
        }
    }

    function pressedHandler() {
        if (state != "SELECTED") {
            state = state == "PRESSED" ? "RELEASED" :  "PRESSED"
        }
    }

    function clickedHandler() {
        if (parent.currSelEmojiButton !== undefined) {
            parent.currSelEmojiButton.state = "RELEASED"
        }

        parent.currSelEmojiButton = emojiCategoryButton
        state = "SELECTED"
        //Qt.emojiCategoryChangedHandler(emojiCategoryButton.categoryName)
        emojiCategoryButton.clickedFunction(emojiCategoryButton.categoryName);
    }


    Text {
        id: emojiText
        color: "#A2A2A2"
        text: qsTr(eCatText)
        font.pixelSize: fontSize - 8
        anchors.centerIn: parent
        font.family: iconFont.name
    }

    Rectangle{
        id: selectedIndicator
        color: "transparent"
        width: parent.width
        height: parent.height * 0.05
    }


    state: "RELEASED"
    states: [
        State {
            name: "PRESSED"
            PropertyChanges {
                target: emojiText
                font.pixelSize: fontSize - 10
            }
        },
        State {
            name: "RELEASED"
            PropertyChanges {
                target: emojiText
                font.pixelSize: fontSize - 8
            }
        },
        State {
            name: "SELECTED"
            PropertyChanges {
                target: selectedIndicator
                color: "#2b5278"
            }
        }
    ]

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: emojiText.color = palette.midlight == "#323232" ? "white" : "black"
        onExited: emojiText.color = "#A2A2A2"
        onPressedChanged: pressedHandler()
        onClicked: clickedHandler()
    }

    Component.onCompleted: completedHandler()
}
