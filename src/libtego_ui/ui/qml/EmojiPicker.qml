import QtQuick 2.0
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.0
import QtQuick.Controls.Styles 1.2
import QtQuick.Dialogs 1.0
import "qrc:/ui/emoji.js" as EmojiJSON

Rectangle {
    id: emojiPicker
    property EmojiCategoryButton currSelEmojiButton
    property variant emojiParsedJson
    property int buttonWidth: 20
    property TextArea textArea
    property var skin_tones: ["🏻","🏼","🏽","🏾","🏿"]
    property var current_skin_tone: 0

    property alias current_skin_selected: button_skin.text

    //displays all Emoji of one categroy by modifying the ListModel of emojiGrid
    function categoryChangedHandler (newCategoryName){
        emojiByCategory.clear()

        for (var i = 0; i < emojiParsedJson.emoji_by_category[newCategoryName].length; i++) {
            var elem = emojiParsedJson.emoji_by_category[newCategoryName][i]
            emojiByCategory.append({eCatName: newCategoryName, eCatText: elem})
        }
    }

    //adds the clicked Emoji (and one ' ' if the previous character isn't an Emoji) to textArea
    function emojiClickedHandler(selectedEmoji) {
        var strAppnd = ""
        var plainText = textArea.getText(0, textArea.length)

        if (plainText.length > 0) {
            var lastChar = plainText[plainText.length-1]
            if ((lastChar !== ' ')) {
                strAppnd = "&nbsp;"
            }
        }
        else{
            strAppnd = "&nbsp;"
        }

        strAppnd += '<span style="font-size:22px;font-family:Noto Emoji">' + selectedEmoji + '</span> '
        //strAppnd += selectedEmoji

        textArea.insert(textArea.cursorPosition, strAppnd)
    }

    //parses JSON, publishes button handlers and inits textArea
    function completedHandler() {
        emojiParsedJson = JSON.parse(EmojiJSON.emoji_json)
        for (var i = 0; i < emojiParsedJson.emoji_categories.length; i++) {
            var elem = emojiParsedJson.emoji_categories[i]
            emojiCategoryButtons.append({eCatName: elem.name, eCatText: elem.emoji_unified})
        }

        Qt.emojiCategoryChangedHandler = categoryChangedHandler
        Qt.emojiClickedHandler = emojiClickedHandler

        textArea.cursorPosition = textArea.length
        //textArea.Keys.pressed.connect(keyPressedHandler)
    }

    function function_assign() {
        Qt.emojiCategoryChangedHandler = categoryChangedHandler
        Qt.emojiClickedHandler = emojiClickedHandler
    }

/*
    //checks if the previous character is an Emoji and adds a ' ' if that's the case
    //this is necessary, because Emoji use a bigger font-size, and that font-size is kept using without a ' '
    function keyPressedHandler(event) {
        var testStr = txtIn.getText(txtIn.length-2, txtIn.length)
        var ptrn = new RegExp("[\uD800-\uDBFF][\uDC00-\uDFFF]")
        if ((event.key !== Qt.Key_Backspace) && (ptrn.test(testStr))) {
            txtIn.text += " "
            txtIn.cursorPosition = txtIn.length
        }
    }
*/

    //all emoji of one category
    ListModel {
        id: emojiByCategory
    }

    GridView {
        id: emojiGrid
        width: parent.width
        anchors.fill: parent
        anchors.bottomMargin: buttonWidth
        cellWidth: buttonWidth; cellHeight: buttonWidth

        model: emojiByCategory
        delegate: EmojiButton {
            width: buttonWidth
            height: buttonWidth
            color: emojiPicker.color
            onClickedFunction: {
                             emojiClickedHandler(b)
                    }
        }
    }


    //seperator
    Rectangle {
        color: emojiPicker.color
        anchors.bottom: parent.bottom
        width: parent.width
        height: buttonWidth
    }
    Rectangle {
        color: "black"
        anchors.bottom: parent.bottom
        anchors.bottomMargin: buttonWidth
        width: parent.width
        height: 1
    }

    //emoji category selector
    ListView {
        width: parent.width
        anchors.bottom: parent.bottom
        anchors.bottomMargin: buttonWidth
        orientation: ListView.Horizontal

        model: emojiCategoryButtons
        delegate: EmojiCategoryButton {
            width: buttonWidth
            height: buttonWidth
            color: emojiPicker.color
            onClickedFunction: {
                             categoryChangedHandler(b)
                    }
        }

        Button {
            anchors {
                top: parent.top
                right: parent.right
            }
                    id: button_skin
                    text: "🏻"
                    Layout.alignment: Qt.AlignRight
                    style: ButtonStyle {
                        background: Rectangle {

                                implicitWidth: 22
                                implicitHeight: 22
                                border.color: control.hovered ? "#dddddd" : "transparent"
                                border.width: 1
                                radius: 5
                                color: "transparent"
                            }

                          label: Text {
                            renderType: Text.NativeRendering
                            font.family: "Noto Emoji"
                            text: control.text
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            font.pointSize: 16

                          }
                        }

                    onClicked: {
                        current_skin_tone += 1
                        if(current_skin_tone > 4){
                            current_skin_tone = 0
                        }
                        button_skin.text = skin_tones[current_skin_tone]
                    }
                }

    }

    ListModel {
        id: emojiCategoryButtons
    }

    //onVisibleChanged: function_assign()
    Component.onCompleted: completedHandler()

    //Rectangle {anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "darkgrey"; }
}

