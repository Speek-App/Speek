import QtQuick 2.0
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.0
import QtQuick.Controls.Styles 1.2
import QtQuick.Dialogs 1.0
import QtQuick.Window 2.15
import im.utility 1.0
import "qrc:/ui/emoji.js" as EmojiJSON
import "qrc:/ui/emoji_names.js" as EmojiNamesJSON

Rectangle {
    id: emojiPicker
    property EmojiCategoryButton currSelEmojiButton
    property variant emojiParsedJson
    property int buttonWidth: 20
    property TextArea textArea
    property var skin_tones: ["🏻","🏼","🏽","🏾","🏿"]
    property var current_skin_tone: 0
    property var emojiRenderSize: Screen.devicePixelRatio > 1.5 ? "36" : "18"
    property var emojiFont: typeof(uiSettings.data.emojiFont) !== "undefined" ? uiSettings.data.emojiFont.toLowerCase() : availableEmoji[0]
    property var availableEmoji: ["noto-emoji", "twemoji", "emojitwo"]
    property var emojiJoinChar: "-"
    property var emojiNamesParsedJson: JSON.parse(EmojiNamesJSON.emoji_json)

    property alias current_skin_selected: button_skin.text

    Utility {
       id: utility
    }

    //displays all Emoji of one categroy by modifying the ListModel of emojiGrid
    function categoryChangedHandler (newCategoryName){
        emojiByCategory.clear()

        for (var i = 0; i < emojiParsedJson.emoji_by_category[newCategoryName].length; i++) {
            var elem = emojiParsedJson.emoji_by_category[newCategoryName][i]
            emojiByCategory.append({eCatName: newCategoryName, eCatText: elem})
        }
    }

    function emojiExists(emoji) {
        var characterCode;
        characterCode = prepend_0(fixedCharCodeAt(emoji, 0).toString(16))

        if(emoji.length >= 4)
            for(var i = 2; i<emoji.length; i+=2)
                characterCode += emojiPicker.emojiJoinChar + prepend_0(fixedCharCodeAt(emoji, i).toString(16))

        var resource = ':/emoji/' + emojiPicker.emojiFont + '/' + emojiPicker.emojiRenderSize + '/' + characterCode + '.png'
        if(!utility.checkFileExists(resource)){
            for(var i = 0; i<emojiPicker.availableEmoji.length; i++){
                if(emojiPicker.emojiFont !== emojiPicker.availableEmoji[i]){
                    resource = ':/emoji/' + emojiPicker.availableEmoji[i] + '/' + emojiPicker.emojiRenderSize + '/' + characterCode + '.png'
                    if(utility.checkFileExists(resource))
                        return true;
                }
            }
        }
        else{
            return true;
        }
        return false;
    }

    function searchChanged(searchText){
        emojiByCategory.clear()

        for (var i = 0; i < emojiNamesParsedJson.emojis.length; i++) {
            var elem = emojiNamesParsedJson.emojis[i]
            if(elem.name.toLowerCase().includes(searchText.toLowerCase()) && emojiExists(elem.emoji))
                emojiByCategory.append({eCatName: "Search", eCatText: elem.emoji})
        }
    }

    function toSurrogatePair(val){
        var s = parseInt(val, 16);

        if (s >= 0x10000 && s <= 0x10FFFF) {
          var hi = Math.floor((s - 0x10000) / 0x400) + 0xD800;
          var lo = ((s - 0x10000) % 0x400) + 0xDC00;
          return String.fromCharCode(hi, lo);
        }
        else {
          return "";
        }
    }

    function fixedCharCodeAt(str, idx) {
      idx = idx || 0;
      var code = str.charCodeAt(idx);
      var hi, low;

      if (0xD800 <= code && code <= 0xDBFF) {
        hi = code;
        low = str.charCodeAt(idx + 1);
        if (isNaN(low)) {
          throw 'High surrogate not followed by ' +
            'low surrogate in fixedCharCodeAt()';
        }
        return (
          (hi - 0xD800) * 0x400) +
          (low - 0xDC00) + 0x10000;
      }
      if (0xDC00 <= code && code <= 0xDFFF) {
        return false;
      }
      return code;
    }

    function prepend_0(str){
        if(str.length < 4)
            return ('0000'+str).slice(-4);
        return str;
    }

    function replaceImageWithEmojiCharacter(str){
        var regexImg = /<img src="qrc:\/emoji\/noto-emoji\/18\/(?:emoji_u){0,1}([a-f0-9-_]{0,100}).png" width="18" height="18" \/>/g

        str = str.replace(regexImg, function(match, contents, offset, input_string){
            var ret = "";
            var a = contents.split(emojiPicker.emojiJoinChar)

            for (var i = 0; i < a.length; i++){
                ret += toSurrogatePair(a[i])
            }

            return ret
        })
        return str
    }

    function replaceEmojiWithImage(emoji, options) {
        var characterCode;
        characterCode = prepend_0(fixedCharCodeAt(emoji, 0).toString(16))

        if(emoji.length >= 4)
            for(var i = 2; i<emoji.length; i+=2)
                characterCode += emojiPicker.emojiJoinChar + prepend_0(fixedCharCodeAt(emoji, i).toString(16))

        var resource = ':/emoji/' + emojiPicker.emojiFont + '/' + emojiPicker.emojiRenderSize + '/' + characterCode + '.png'
        if(!utility.checkFileExists(resource)){
            for(var i = 0; i<emojiPicker.availableEmoji.length; i++){
                if(emojiPicker.emojiFont !== emojiPicker.availableEmoji[i]){
                    resource = ':/emoji/' + emojiPicker.availableEmoji[i] + '/' + emojiPicker.emojiRenderSize + '/' + characterCode + '.png'
                    if(utility.checkFileExists(resource))
                        break
                }
            }
        }

        return '<img src="qrc' + resource + '" width=18 height=18 valign=bottom />'
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

        strAppnd += replaceEmojiWithImage(selectedEmoji) + "&nbsp;"
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

    //all emoji of one category
    ListModel {
        id: emojiByCategory
    }

    ListModel {
        id: emojiCategoryButtons
    }

    ColumnLayout{
        anchors.fill: parent
        spacing: 0

        Rectangle{
            Layout.maximumHeight: buttonWidth * 1.45
            Layout.preferredHeight: buttonWidth * 1.45
            Layout.fillWidth: true
            color: emojiPicker.color
            z:5

            SearchBox {
                id: searchEmoji
                anchors.fill: parent
                anchors.margins: 3

                text: ""

                onTextChanged: {
                    searchChanged(searchEmoji.text);
                }

                Accessible.role: Accessible.EditableText
                //: Name of the text input used to filter the emojis
                Accessible.name: qsTr("Emoji search")
                //: Description of what the emoji search filter is for accessibility tech like screen readers
                Accessible.description: qsTr("Which emoji to find")
            }
        }

        GridView {
            id: emojiGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: emojiGrid.width / Math.floor(emojiGrid.width / buttonWidth); cellHeight: buttonWidth

            model: emojiByCategory
            delegate: EmojiButton {
                width: emojiGrid.width / Math.floor(emojiGrid.width / buttonWidth)
                height: buttonWidth
                color: emojiPicker.color
                onClickedFunction: {
                    emojiClickedHandler(b)
                    forceActiveFocus()
                }
            }
        }

        Rectangle {
            color: styleHelper.borderColor2
            Layout.maximumHeight: 1
            Layout.preferredHeight: 1
            Layout.fillWidth: true
        }

        //emoji category selector
        Rectangle{
            Layout.maximumHeight: buttonWidth * 1.45
            Layout.preferredHeight: buttonWidth * 1.45
            Layout.fillWidth: true
            color: emojiPicker.color
            ListView {
                anchors.fill: parent
                orientation: ListView.Horizontal
                clip: true

                model: emojiCategoryButtons
                delegate: EmojiCategoryButton {
                    fontSize: buttonWidth
                    width: buttonWidth * 2
                    height: buttonWidth * 1.4
                    color: emojiPicker.color
                    onClickedFunction: {
                        categoryChangedHandler(b)
                        forceActiveFocus()
                    }
                }
                footer: Item{
                    height:2
                    width: 40
                }
                RowLayout {
                    y: 6
                    anchors {
                        right: parent.right
                    }
                    Button {
                        id: button_skin
                        text: skin_tones[0]
                        style: ButtonStyle {
                            background: Rectangle {
                                implicitWidth: 20
                                implicitHeight: 20
                                border.color: control.hovered ? "#dddddd" : "transparent"
                                border.width: 1
                                radius: 5
                                color: "transparent"
                             }

                             label: Text {
                                  renderType: Text.NativeRendering
                                  text: {
                                      return replaceEmojiWithImage(control.text)
                                  }
                                  textFormat: TextEdit.RichText
                                  verticalAlignment: Text.AlignVCenter
                                  horizontalAlignment: Text.AlignHCenter
                                  font.pointSize: 22
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
                    Item{
                        width: 4
                    }
                }
            }
        }
    }

    Component.onCompleted: completedHandler()
}

