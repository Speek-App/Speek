import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import QtQuick.Controls.Styles 1.2
import im.ricochet 1.0
import im.utility 1.0
import QtQuick.Dialogs 1.0

FocusScope {
    id: chatPage

    property ContactUser contact
    property TextArea textField: textInput
    property alias textInputMain: textInput
    property var conversationModel: (contact !== null) ? contact.conversation : null
    property bool emojiVisible: false
    property int margin_chat: 0
    property bool richTextActive: !uiSettings.data.disableDefaultRichText

    function forceActiveFocus() {
        textField.forceActiveFocus()
    }

    function sendFile() {
        contact.sendFile();
    }

    Utility {
           id: utility
        }

    FileDialog {
        id: fileDialog
        nameFilters: ["Images (*.png *.jpg *.jpeg)"]
        onAccepted: {
            var b = utility.toBase64(fileDialog.fileUrl.toString());
            textInput.insert(textInput.cursorPosition, '&nbsp;' + b + ' ')
        }
    }

    onVisibleChanged: if (visible) forceActiveFocus()

    property bool active: visible && activeFocusItem !== null
    onActiveChanged: {
        if (active)
            conversationModel.resetUnreadCount()
    }

    Connections {
        target: conversationModel
        function onUnreadCountChanged(user, unreadCount) {
            if (active) conversationModel.resetUnreadCount()
        }
    }

    RowLayout {
        id: infoBar
        anchors {
            top: parent.top
            left: parent.left
            leftMargin: 4
            right: parent.right
            rightMargin: 4
        }
        height: implicitHeight + 8
        spacing: 8

        ColorLetterCircle{
            name: contact != null ? contact.nickname : ""
            icon: contact != null ? contact.icon : ""
        }
        ColumnLayout{
            spacing:0
            Label {
                text: contact != null ? contact.nickname : ""
                textFormat: Text.PlainText
                font.pointSize: styleHelper.pointSize
                anchors.topMargin: 15
            }
            Label {
                anchors.bottomMargin: 15
                text: contact != null ? contact.status == 0 ? "online": "offline" : ""
                textFormat: Text.PlainText
                font.pointSize: styleHelper.pointSize *0.8
            }
        }

        Item {
            Layout.fillWidth: true
            height: 1
        }
    }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            top: infoBar.top
            bottom: infoBar.bottom
        }
        color: palette.base
        z: -1

        Column {
            anchors {
                top: parent.bottom
                left: parent.left
                right: parent.right
            }
            Rectangle { width: parent.width; height: 1; color: "darkgrey"; }
        }
    }

    ChatMessageArea {
        id: chatmessagearea1
        anchors {
            top: infoBar.bottom
            topMargin: 1
            left: parent.left
            right: parent.right
            bottom: statusBar.top
        }
        anchors.bottomMargin: emojiVisible ? emojiPicker.height:0
        model: conversationModel
        border.width: 0
    }

    EmojiPicker {
            id: emojiPicker

            anchors.fill: parent
            anchors.bottomMargin: statusBar.height
            anchors.topMargin: parent.height - 200

            visible: emojiVisible

            color: "white"
            buttonWidth: 28
            textArea: textField     //the TextArea in which EmojiPicker is pasting the Emoji into
        }

    Rectangle {
        id: statusBar
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: statusLayout.height + 8
        color: Qt.lighter(palette.midlight, 1.14)

        Rectangle {anchors.top: parent.top; width: parent.width; height: 1; color: "darkgrey"; }

        RowLayout {
            id: statusLayout
            width: statusBar.width - 8
            y: 4

            Rectangle {width: 3; height: parent.height; color: "transparent"; }

            Button {
                        style: ButtonStyle {
                            background: Rectangle {
                                    implicitWidth: 28
                                    implicitHeight: 28
                                    border.color: control.hovered ? "#dddddd" : "transparent"
                                    border.width: 1
                                    radius: 5
                                    color: "transparent"
                                }
                              label: Image {
                                  height: 28
                                  width: 28
                                  sourceSize.width: 28
                                  sourceSize.height: 28
                                  source: palette.base == "#2a2a2a" ? "qrc:/icons/display-rich-text-svgrepo-com-white.png" : "qrc:/icons/display-rich-text-svgrepo-com.png"
                                  antialiasing: true
                              }
                            }

                        onClicked: {
                            richTextActive = !richTextActive
                            textInput.text = ""
                        }
                    }
            Button {
                        visible: richTextActive
                        style: ButtonStyle {
                            background: Rectangle {
                                    implicitWidth: 28
                                    implicitHeight: 28
                                    border.color: control.hovered ? "#dddddd" : "transparent"
                                    border.width: 1
                                    radius: 5
                                    color: "transparent"
                                }
                              label: Image {
                                  height: 28
                                  width: 28
                                  sourceSize.width: 28
                                  sourceSize.height: 28
                                  source: palette.base == "#2a2a2a" ? "qrc:/icons/emoji-add-svgrepo-com-white.png" : "qrc:/icons/emoji-add-svgrepo-com.png"
                                  antialiasing: true
                              }
                         }

                        onClicked: {
                            emojiVisible = !emojiVisible
                        }
                    }

            TextArea {
                id: textInput
                Layout.fillWidth: true
                y: 4
                frameVisible: true
                backgroundVisible: false

                // This ridiculous incantation enables an automatically sized TextArea
                Layout.preferredHeight: mapFromItem(flickableItem, 0, 0).y * 2 +
                                        Math.max(styleHelper.textHeight + 2*edit.textMargin, flickableItem.contentHeight)
                Layout.maximumHeight: (styleHelper.textHeight * 4) + (2 * edit.textMargin)
                textMargin: 3
                wrapMode: TextEdit.Wrap
                textFormat: richTextActive ? TextEdit.RichText : TextEdit.PlainText

                font.pointSize: styleHelper.pointSize
                font.family: "Helvetica"
                textColor: "black"

                verticalAlignment: Qt.AlignVCenter
                horizontalAlignment: Qt.AlignLeft

                style: TextAreaStyle {
                    frame: Rectangle {
                    radius: 8
                    border.width: 0
                    border.color: "white"
                    color:"white"
                    y:0
                    }
                        }

                property TextEdit edit

                Component.onCompleted: {
                    var objects = contentItem.contentItem.children
                    for (var i = 0; i < objects.length; i++) {
                        if (objects[i].hasOwnProperty('textDocument')) {
                            edit = objects[i]
                            break
                        }
                    }

                    edit.Keys.pressed.connect(keyHandler)
                }

                function keyHandler(event) {
                    switch (event.key) {
                        case Qt.Key_Enter:
                        case Qt.Key_Return:
                            if (event.modifiers & Qt.ShiftModifier || event.modifiers & Qt.AltModifier) {
                                textInput.insert(textInput.cursorPosition, "\n")
                            } else {
                                send()
                            }
                            event.accepted = true
                            break
                        default:
                            event.accepted = false
                    }
                }

                function send() {
                    function chunkSubstr(str, size) {
                      const numChunks = Math.ceil(str.length / size)
                      const chunks = new Array(numChunks)

                      for (let i = 0, o = 0; i < numChunks; ++i, o += size) {
                        chunks[i] = str.substr(o, size)
                      }

                      return chunks
                    }
                    if (textInput.text.length > 63000){
                        conversationModel.sendMessage(textInput.text)
                    }
                    else{
                        conversationModel.sendMessage(textInput.text)
                    }
                    textInput.remove(0, textInput.length)
                }

                onLengthChanged: {
                    if (textInput.length > 6300000)
                        textInput.remove(6300000, textInput.length)
                }

                Accessible.role: Accessible.EditableText
                //: label for accessibility tech like screen readers
                Accessible.name: qsTr("Message area") // todo: translation
                //: description of the text area used to send messages for accessibility tech like screen readers
                Accessible.description: qsTr("Write the message to be sent here. Press enter to send")
            }

            Button {
                style: ButtonStyle {
                    background: Rectangle {
                        implicitWidth: 28
                        implicitHeight: 28
                        border.color: control.hovered ? "#dddddd" : "transparent"
                        border.width: 1
                        radius: 5
                        color: "transparent"
                    }
                    label: Image {
                        height: 28
                        width: 28
                        sourceSize.width: 28
                        sourceSize.height: 28
                        source: palette.base == "#2a2a2a" ? "qrc:/icons/paperclip-svgrepo-com-white.png" : "qrc:/icons/paperclip-svgrepo-com.png"
                        antialiasing: true
                    }
                }

                onClicked: {
                    sendFile()
                }
            }

            Button {
                id: img1
                visible: richTextActive
                style: ButtonStyle {
                    background: Rectangle {
                        implicitWidth: 28
                        implicitHeight: 28
                        border.color: control.hovered ? "#dddddd" : "transparent"
                        border.width: 1
                        radius: 5
                        color: "transparent"
                    }
                    label: Image {
                        height: 30
                        width: 30
                        sourceSize.width: 30
                        sourceSize.height: 30
                        source: palette.base == "#2a2a2a" ? "qrc:/icons/image-add-svgrepo-com-white.png" : "qrc:/icons/image-add-svgrepo-com.png"
                        antialiasing: true
                    }
                }

                onClicked: {
                    fileDialog.open()
                }
            }
        }
    }
}

