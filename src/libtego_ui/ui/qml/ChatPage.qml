import QtQuick 2.15
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
    property var groupIdentifier: String(getRandomInt(1000))
    property var pinnedMessageVisible: false
    property var sendMessageButton: sendMessageButton

    function getRandomInt(max) {
      return Math.floor(Math.random() * max);
    }

    function forceActiveFocus() {
        if(Qt.platform.os !== "android")
            textField.forceActiveFocus()
    }

    function sendFile() {
        contact.sendFile();
    }

    function sendFileWithPath(path) {
        contact.sendFile(path);
    }

    function _openPreferences() {
        if(Qt.platform.os === "android"){
            var object = createDialog("ContactSettingWindow.qml", { 'selectedContact': contact })
            object.visible = true
            object.forceActiveFocus()
        }
        else
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

    Timer {
        id: timer_delay
        function setTimeout(cb, delayTime) {
            timer_delay.interval = delayTime;
            timer_delay.repeat = false;
            timer_delay.triggered.connect(cb);
            timer_delay.triggered.connect(function release () {
                timer_delay.triggered.disconnect(cb); // This is important
                timer_delay.triggered.disconnect(release); // This is important as well
            });
            timer_delay.start();
        }
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

    function parse_image(p){
        var b = utility.toBase64(p);
        var regex = "^<html><head><meta name=\"qrichtext\"></head><body><img name=\"[A-Za-z0-9-_. %]{0,40}\" width=\"(\\d{1,4})\" height=\"(\\d{1,4})\" src=\"data:((?:\\w+\/(?:(?!;).)+)?)((?:;[\\w\\W]*?[^;])*),(.+)\" /></body></html>$";
        const found = b.match(regex);
        if(found){
            var object = createDialog("SendImageDialog.qml", { "imageBase64": found[5], "conversationModel": conversationModel, "imageBase64_send": b, "groupIdentifier": chatFocusScope.groupIdentifier }, Qt.platform.os === "android" ? null : window)
            object.visible = true
        }
    }

    FocusScope {
        visible: contact.status == 0 || contact.status == 1 ? true : false

        anchors.fill: parent
        id: chatPage

        FileDialog {
            id: fileDialog
            nameFilters: ["Images (*.png *.jpg *.jpeg)"]
            onAccepted: {
                if(Qt.platform.os === "android")
                    timer_delay.setTimeout(function(){chatFocusScope.parse_image(fileDialog.fileUrl.toString())}, 1000)
                else
                    parse_image(fileDialog.fileUrl.toString())
            }
        }

        FileDialog {
            id: multiFileDialog
            selectMultiple: true
            onAccepted: {
                var files_list = [];
                for(var i = 0; i < multiFileDialog.fileUrls.length; i++){
                    files_list.push(String(multiFileDialog.fileUrls[i]))
                }

                var b = utility.makeTempZipFromMultipleFiles(files_list);
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
                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        if (mouse.button === Qt.LeftButton) {
                            _openPreferences()
                        }
                    }
                }
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
                    text: contact != null ? contact.status == 0 ? "online (P2P connected)": "offline" : ""
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
                implicitHeight: 32
                implicitWidth: 32

                text: "r"

                visible: conversationModel.contact.is_a_group && conversationModel.pinned_message != "" && typeof(conversationModel.pinned_message) != "undefined"

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
                        if (mouse.button === Qt.RightButton) {
                        } else if (mouse.button === Qt.LeftButton) {
                            pinnedMessageVisible = !pinnedMessageVisible
                        }
                    }
                }

                Accessible.role: Accessible.Button
                //: Name of the button for opening the group pinned message
                Accessible.name: qsTr("Open group pinned message")
                //: Description of the 'Open group pinned message' button for accessibility tech like screen readers
                Accessible.description: qsTr("Shows the pinned message of the group")
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
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: {
                        if (mouse.button === Qt.RightButton) { // 'mouse' is a MouseEvent argument passed into the onClicked signal handler
                            chatPageContactContextMenu.popup()
                        } else if (mouse.button === Qt.LeftButton) {
                            _openPreferences()
                        }
                    }
                }

                Menu {
                    id: chatPageContactContextMenu

                    /* QT automatically sets Accessible.text to MenuItem.text */
                    MenuItem {
                        //: Chat page context menu command to clear all messages
                        text: qsTr("Clear all messages")
                        onTriggered: {
                            conversationModel.clear()
                        }
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

        Rectangle{
            anchors {
                top: infoBar.bottom
                left: parent.left
                leftMargin: 6
                right: parent.right
                rightMargin: 8
                topMargin: 8
            }
            visible: pinnedMessageVisible && conversationModel.contact.is_a_group && conversationModel.pinned_message != "" && typeof(conversationModel.pinned_message) != "undefined"
            height: 100
            color: palette.base
            z: 90
            radius: 6

            TextArea {
                x: 3
                y: 3
                textMargin: 5
                id: pinnedTextMessageField
                height: parent.height - 6
                width: parent.width - 6

                style: TextAreaStyle {
                    textColor: palette.text
                    frame: Rectangle {
                        color: palette.base
                    }
                }

                textFormat: conversationModel.pinned_message.includes("<html><head><meta name=\"qrichtext\"") ? TextEdit.RichText : TextEdit.PlainText
                font.pixelSize: 13
                font.family: styleHelper.fontFamily

                wrapMode: TextEdit.Wrap
                readOnly: true
                selectByMouse: true
                text: conversationModel.pinned_message
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
                    visible: Qt.platform.os !== "android"
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
                            emojiVisible = false
                            richTextActive = !richTextActive
                            textInput.text = ""
                        }
                    }
                }
                Button {
                    id: emojiActivateButton
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
                        text: textInput.placeholderText
                        color: styleHelper.messageBoxText
                        visible: Qt.platform.os === "android" ? (!textInput.getText(0, textInput.length) && !textInput.activeFocus) : !textInput.getText(0, textInput.length)
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
                                        textInput.insert(textInput.cursorPosition, "<br>")
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
                        if(textInput.length > 0){
                            var msg = emojiPicker.replaceImageWithEmojiCharacter(textInput.text)
                            if(conversationModel.contact.is_a_group){
                                var obj = {};
                                obj["message"] = msg
                                obj["name"] = typeof(uiSettings.data.username) !== "undefined" ? uiSettings.data.username : "Anonymous" + chatFocusScope.groupIdentifier
                                obj["id"] = utility.toHash(userIdentity.contactID)
                                msg = JSON.stringify(obj)
                            }
                            conversationModel.sendMessage(msg)
                            textInput.remove(0, textInput.length)
                        }
                    }

                    onLengthChanged: {
                        if (textInput.length > 251900)
                            textInput.remove(251900, textInput.length)
                    }

                    Accessible.role: Accessible.EditableText
                    //: label for accessibility tech like screen readers
                    Accessible.name: qsTr("Message area")
                    //: description of the text area used to send messages for accessibility tech like screen readers
                    Accessible.description: qsTr("Write the message to be sent here. Press enter to send")
                }

                Button {
                    id: sendMessageButton
                    visible: Qt.platform.os === "android" ? textInput.getText(0, textInput.length) || textInput.activeFocus : false
                    tooltip: "Send Message"

                    style: ButtonStyle {
                        background: Rectangle {
                            implicitWidth: 20
                            implicitHeight: 20
                            radius: 5
                            color: "transparent"
                        }
                        label: Text {
                            text: "q"
                            font.family: iconFont.name
                            font.pixelSize: 20
                            horizontalAlignment: Qt.AlignHCenter
                            renderType: Text.QtRendering
                            color: palette.highlight
                        }
                    }

                    MouseArea{
                        cursorShape: Qt.PointingHandCursor
                        anchors.fill: parent
                        onClicked: {
                            Qt.inputMethod.reset();

                            textInput.send();
                        }
                    }
                }



                Button {
                    visible: !conversationModel.contact.is_a_group && Qt.inputMethod.keyboardRectangle.height<10

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
                        id: ma
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
                    visible: {
                        if(!richTextActive)
                            return false
                        if(Qt.inputMethod.keyboardRectangle.height>10)
                            return false
                        return true
                    }
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
