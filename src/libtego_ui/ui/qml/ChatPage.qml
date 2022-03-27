import QtQuick 2.0
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.0
import QtQuick.Controls.Styles 1.2
import im.ricochet 1.0
import im.utility 1.0
import QtQuick.Dialogs 1.3

FocusScope{
    id: chatFocusScope
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

    function sendFileWithPath(path) {
        contact.sendFile(path);
    }

    function _openPreferences() {
        root.openPreferences("ContactPreferences.qml", { 'selectedContact': contact })
    }

    Timer {
        id: timer
    }

    function delay(delayTime, cb) {
        timer.interval = delayTime;
        timer.repeat = false;
        timer.triggered.connect(cb);
        timer.start();
    }

    Utility {
       id: utility
    }

    onVisibleChanged: if (visible) forceActiveFocus()

    property bool active: visible && activeFocusItem !== null
    onActiveChanged: {
        if (active)
            conversationModel.resetUnreadCount()
    }

    FocusScope {
        visible: contact.status == 0 || contact.status == 1 ? true : false

        anchors.fill: parent
        id: chatPage

        FileDialog {
            id: fileDialog
            nameFilters: ["Images (*.png *.jpg *.jpeg)"]
            onAccepted: {
                var b = utility.toBase64(fileDialog.fileUrl.toString());
                //textInput.insert(textInput.cursorPosition, '&nbsp;' + b + ' ')

                var regex = "^!<Image>\\{[A-Za-z0-9-_. %]{0,40},width=(\\d{1,4}),height=(\\d{1,4})\\}data:((?:\\w+\/(?:(?!;).)+)?)((?:;[\\w\\W]*?[^;])*),(.+)$";
                const found = b.match(regex);
                if(found){
                    var object = createDialog("SendImageDialog.qml", { "imageBase64": found[5], "conversationModel": conversationModel, "imageBase64_send": b }, window)
                    object.visible = true
                }
                //conversationModel.sendMessage(b)
            }
        }

        FileDialog {
            id: multiFileDialog
            selectMultiple: true
            onAccepted: {
                console.log(multiFileDialog.fileUrls)
                var files_list = [];
                for(var i = 0; i < multiFileDialog.fileUrls.length; i++){
                    files_list.push(String(multiFileDialog.fileUrls[i]))
                }

                var b = utility.makeTempZipFromMultipleFiles(files_list);
                console.log(b);
                if(b.error === ""){
                    sendZipDialog.fileToSend = b.filePath
                    sendZipDialog.text = qsTr("Are you sure you want to send the archive %1 to %2? (size: %3)").arg(b.fileName).arg(contact.nickname).arg(b.size)
                    sendZipDialog.visible = true;
                }
                else{
                    sendZipDialogError.text = qsTr("Error when creating the zip archive <%1>").arg(b.error)
                    sendZipDialogError.visible = true;
                }
            }
        }

        FileDialog {
            id: folderDialog
            selectFolder: true
            onAccepted: {
                var b = utility.makeTempZipFromFolder(folderDialog.folder);
                if(b.error === ""){
                    sendZipDialog.fileToSend = b.filePath
                    sendZipDialog.text = qsTr("Are you sure you want to send the archive %1 to %2? (size: %3)").arg(b.fileName).arg(contact.nickname).arg(b.size)
                    sendZipDialog.visible = true;
                }
                else{
                    sendZipDialogError.text = qsTr("Error when creating the zip archive <%1>").arg(b.error)
                    sendZipDialogError.visible = true;
                }
            }
        }

        MessageDialog {
            id: sendZipDialog

            title: qsTr("File Transfer")
            icon: StandardIcon.Question
            text: ""
            standardButtons: StandardButton.Yes | StandardButton.Cancel | StandardButton.Open

            visible: false

            property string fileToSend: ""

            onButtonClicked: {
                if (clickedButton === StandardButton.Yes) {
                    visible = false;
                    console.log(fileToSend)
                    sendFileWithPath(fileToSend);
                }
                else if (clickedButton === StandardButton.Open) {
                    utility.openWithDefaultApplication(fileToSend)
                    delay(200, function() {
                        sendZipDialog.open()
                    })
                }
            }
        }

        MessageDialog {
            id: sendZipDialogError

            title: qsTr("File Transfer")
            icon: StandardIcon.Warning
            text: ""
            standardButtons: StandardButton.Ok

            visible: false

            onAccepted: visible = false;
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
                icon: typeof(contact.icon) != "undefined" ? contact.icon : ""
            }
            ColumnLayout{
                spacing:0
                Label {
                    text: contact != null ? contact.nickname : ""
                    textFormat: Text.PlainText
                    anchors.topMargin: 15
                    font.pointSize: styleHelper.pointSize * 0.9
                    font.bold: true
                    color: palette.text
                }
                Label {
                    anchors.bottomMargin: 15
                    text: contact != null ? contact.status == 0 ? "online": "offline" : ""
                    textFormat: Text.PlainText
                    font.pointSize: styleHelper.pointSize *0.8
                    opacity: 0.6
                    color: palette.text
                }
            }

            Item {
                Layout.fillWidth: true
                height: 1
            }
            ToolButton {
                id: contactSettings
                implicitHeight: 32
                implicitWidth: 32

                text: "K"

                style: ButtonStyle {
                    background: Rectangle {
                        implicitWidth: 28
                        implicitHeight: 28
                        radius: 5
                        color: "transparent"

                    }
                    label: Text {
                        renderType: Text.NativeRendering
                        font.family: iconFont.name
                        font.pointSize: styleHelper.pointSize * 1.2
                        text: control.text
                        color: control.hovered ? styleHelper.chatIconColorHover : styleHelper.chatIconColor
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                     }
                }

                MouseArea{
                    cursorShape: Qt.PointingHandCursor
                    anchors.fill: parent
                    onClicked: {
                        _openPreferences()
                    }
                }

                Accessible.role: Accessible.Button
                //: Name of the button for opening the conatct settings for accessibility tech like screen readers
                Accessible.name: qsTr("Open Contact Settings")
                //: Description of the 'Open Contact Settings' button for accessibility tech like screen readers
                Accessible.description: qsTr("Shows the contact settings")
            }
            Item {
                width:0
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
                Rectangle { visible: styleHelper.chatBoxBorderColor == "transparent" ? false : true; width: parent.width; height: 1; color: styleHelper.chatBoxBorderColor }
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

            clip: true

            visible: emojiVisible

            color: styleHelper.emojiPickerBackground
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
            height: statusLayout.height + 20
            color: palette.base

            Rectangle {visible: styleHelper.chatBoxBorderColor == "transparent" ? false : true; anchors.top: parent.top; width: parent.width; height: 1; color: styleHelper.chatBoxBorderColor }

            RowLayout {
                id: statusLayout
                width: statusBar.width - 8
                y: 10

                Rectangle {width: 3; height: parent.height; color: "transparent"; }

                Button {
                    tooltip: "Disable rich text editing"

                    style: ButtonStyle {
                        background: Rectangle {
                            implicitWidth: 20
                            implicitHeight: 20
                            radius: 5
                            color: "transparent"
                        }
                        label: Text {
                            text: "J"
                            font.family: iconFont.name
                            font.pixelSize: 20
                            horizontalAlignment: Qt.AlignHCenter
                            renderType: Text.QtRendering
                            color: control.hovered ? styleHelper.chatIconColorHover : styleHelper.chatIconColor
                        }
                    }

                    MouseArea{
                        cursorShape: Qt.PointingHandCursor
                        anchors.fill: parent
                        onClicked: {
                            richTextActive = !richTextActive
                            textInput.text = ""
                        }
                    }
                }
                Button {
                    visible: richTextActive
                    tooltip: "Show emoji menu"

                    style: ButtonStyle {
                        background: Rectangle {
                                implicitWidth: 20
                                implicitHeight: 20
                                radius: 5
                                color: "transparent"
                            }
                          label: Text {
                              text: "Q"
                              font.family: iconFont.name
                              font.pixelSize: 20
                              horizontalAlignment: Qt.AlignHCenter
                              renderType: Text.QtRendering
                              color: control.hovered ? styleHelper.chatIconColorHover : styleHelper.chatIconColor
                          }
                     }

                    MouseArea{
                        cursorShape: Qt.PointingHandCursor
                        anchors.fill: parent
                        onClicked: {
                            emojiVisible = !emojiVisible
                        }
                    }
                }

                TextArea {
                    id: textInput
                    Layout.fillWidth: true
                    y: 0
                    frameVisible: true
                    backgroundVisible: false

                    smooth: true
                    font.hintingPreference: Font.PreferNoHinting

                    // This ridiculous incantation enables an automatically sized TextArea
                    Layout.preferredHeight: mapFromItem(flickableItem, 0, 0).y * 2 +
                                            Math.max(styleHelper.textHeight + 2*edit.textMargin, flickableItem.contentHeight)
                    Layout.maximumHeight: (styleHelper.textHeight * 4) + (2 * edit.textMargin)
                    textMargin: 3
                    wrapMode: TextEdit.Wrap
                    textFormat: richTextActive ? TextEdit.RichText : TextEdit.PlainText

                    //font.pointSize: styleHelper.pointSize * 0.9
                    font.pixelSize: 13
                    font.family: styleHelper.fontFamily
                    textColor: palette.text

                    verticalAlignment: Qt.AlignVCenter
                    horizontalAlignment: Qt.AlignLeft

                    style: TextAreaStyle {
                            frame: Rectangle {
                            radius: 8
                            color: palette.base
                            y:0
                        }
                    }

                    property TextEdit edit
                    property string placeholderText: qsTr("Write a message...")

                    Text {
                        x: 5
                        anchors.verticalCenter: parent.verticalCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 13
                        //font.pointSize: styleHelper.pointSize * 0.9
                        text: textInput.placeholderText
                        color: styleHelper.messageBoxText
                        visible: !textInput.getText(0, textInput.length)
                    }

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
                                    if(richTextActive)
                                        textInput.insert(textInput.cursorPosition, "\n")
                                    else
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
                        conversationModel.sendMessage(emojiPicker.replaceImageWithEmojiCharacter(textInput.text))
                        textInput.remove(0, textInput.length)
                    }

                    onLengthChanged: {
                        if (textInput.length > 6300000)
                            textInput.remove(6300000, textInput.length)
                    }

                    Accessible.role: Accessible.EditableText
                    //: label for accessibility tech like screen readers
                    Accessible.name: qsTr("Message area")
                    //: description of the text area used to send messages for accessibility tech like screen readers
                    Accessible.description: qsTr("Write the message to be sent here. Press enter to send")
                }

                Button {
                    style: ButtonStyle {
                        background: Rectangle {
                            implicitWidth: 20
                            implicitHeight: 20
                            radius: 5
                            color: "transparent"
                        }
                        label: Text {
                            text: "R"
                            font.family: iconFont.name
                            font.pixelSize: 20
                            horizontalAlignment: Qt.AlignHCenter
                            renderType: Text.QtRendering
                            color: control.hovered ? styleHelper.chatIconColorHover : styleHelper.chatIconColor
                        }
                    }

                    tooltip: "Send a file"

                    MouseArea {
                        cursorShape: Qt.PointingHandCursor
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: {
                            if (mouse.button === Qt.RightButton) { // 'mouse' is a MouseEvent argument passed into the onClicked signal handler
                                sendFileContextMenu.popup()
                            } else if (mouse.button === Qt.LeftButton) {
                                sendFile()
                            }
                        }
                    }

                    Menu {
                        id: sendFileContextMenu

                        /* QT automatically sets Accessible.text to MenuItem.text */
                        MenuItem {
                            //: File send context menu command to send a whole folder as a zip archive
                            text: qsTr("Send folder as zip archive")
                            onTriggered: {
                                folderDialog.open();
                            }
                        }
                        MenuItem {
                            //: File send context menu command to send multiple files combined as a zip archive
                            text: qsTr("Send multiple files as zip archive")
                            onTriggered: {
                                multiFileDialog.open();
                            }
                        }
                    }
                }

                Button {
                    id: img1
                    visible: richTextActive
                    tooltip: "Attach a image"

                    style: ButtonStyle {
                        background: Rectangle {
                            implicitWidth: 20
                            implicitHeight: 20
                            radius: 5
                            color: "transparent"
                        }
                        label: Text {
                            text: "P"
                            font.family: iconFont.name
                            font.pixelSize: 20
                            horizontalAlignment: Qt.AlignHCenter
                            renderType: Text.QtRendering
                            color: control.hovered ? styleHelper.chatIconColorHover : styleHelper.chatIconColor
                        }
                    }

                    MouseArea{
                        cursorShape: Qt.PointingHandCursor
                        anchors.fill: parent
                        onClicked: {
                            fileDialog.open()
                        }
                    }
                }
            }
        }
    }
    Rectangle {
        visible: contact.status == 0 || contact.status == 1 ? false : true
        anchors.fill: parent
        color: "transparent"
        Rectangle{
            width:100
            height:140
            color: "transparent"
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            BusyIndicator {
                running: true
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width:100
                height:100
                smooth: true
            }
            Label{
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                text: "Waiting for contact request to be accepted..."
            }
        }
    }
}
