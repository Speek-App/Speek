import QtQuick 2.15
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import im.ricochet 1.0
import im.utility 1.0

Column {
    id: delegate
    width: parent.width
    property string selected_image;
    property string copy_selected_image;
    property alias messageChildItem: message.childItem
    property var emojiRegex: /\ud83d\udc68\u200d\u2764\ufe0f\u200d\ud83d\udc8b\u200d\ud83d\udc68|\ud83d\udc68\u200d\ud83d\udc68\u200d\ud83d\udc66\u200d\ud83d\udc66|\ud83d\udc68\u200d\ud83d\udc68\u200d\ud83d\udc67\u200d\ud83d[\udc66\udc67]|\ud83d\udc68\u200d\ud83d\udc69\u200d\ud83d\udc66\u200d\ud83d\udc66|\ud83d\udc68\u200d\ud83d\udc69\u200d\ud83d\udc67\u200d\ud83d[\udc66\udc67]|\ud83d\udc69\u200d\u2764\ufe0f\u200d\ud83d\udc8b\u200d\ud83d[\udc68\udc69]|\ud83d\udc69\u200d\ud83d\udc69\u200d\ud83d\udc66\u200d\ud83d\udc66|\ud83d\udc69\u200d\ud83d\udc69\u200d\ud83d\udc67\u200d\ud83d[\udc66\udc67]|\ud83d\udc68\u200d\u2764\ufe0f\u200d\ud83d\udc68|\ud83d\udc68\u200d\ud83d\udc68\u200d\ud83d[\udc66\udc67]|\ud83d\udc68\u200d\ud83d\udc69\u200d\ud83d[\udc66\udc67]|\ud83d\udc69\u200d\u2764\ufe0f\u200d\ud83d[\udc68\udc69]|\ud83d\udc69\u200d\ud83d\udc69\u200d\ud83d[\udc66\udc67]|\ud83d\udc41\u200d\ud83d\udde8|(?:[\u0023\u002a\u0030-\u0039])\ufe0f?\u20e3|(?:(?:[\u261d\u270c])(?:\ufe0f|(?!\ufe0e))|\ud83c[\udf85\udfc2-\udfc4\udfc7\udfca\udfcb]|\ud83d[\udc42\udc43\udc46-\udc50\udc66-\udc69\udc6e\udc70-\udc78\udc7c\udc81-\udc83\udc85-\udc87\udcaa\udd75\udd90\udd95\udd96\ude45-\ude47\ude4b-\ude4f\udea3\udeb4-\udeb6\udec0]|\ud83e\udd18|[\u26f9\u270a\u270b\u270d])(?:\ud83c[\udffb-\udfff]|)|\ud83c\udde6\ud83c[\udde8-\uddec\uddee\uddf1\uddf2\uddf4\uddf6-\uddfa\uddfc\uddfd\uddff]|\ud83c\udde7\ud83c[\udde6\udde7\udde9-\uddef\uddf1-\uddf4\uddf6-\uddf9\uddfb\uddfc\uddfe\uddff]|\ud83c\udde8\ud83c[\udde6\udde8\udde9\uddeb-\uddee\uddf0-\uddf5\uddf7\uddfa-\uddff]|\ud83c\udde9\ud83c[\uddea\uddec\uddef\uddf0\uddf2\uddf4\uddff]|\ud83c\uddea\ud83c[\udde6\udde8\uddea\uddec\udded\uddf7-\uddfa]|\ud83c\uddeb\ud83c[\uddee-\uddf0\uddf2\uddf4\uddf7]|\ud83c\uddec\ud83c[\udde6\udde7\udde9-\uddee\uddf1-\uddf3\uddf5-\uddfa\uddfc\uddfe]|\ud83c\udded\ud83c[\uddf0\uddf2\uddf3\uddf7\uddf9\uddfa]|\ud83c\uddee\ud83c[\udde8-\uddea\uddf1-\uddf4\uddf6-\uddf9]|\ud83c\uddef\ud83c[\uddea\uddf2\uddf4\uddf5]|\ud83c\uddf0\ud83c[\uddea\uddec-\uddee\uddf2\uddf3\uddf5\uddf7\uddfc\uddfe\uddff]|\ud83c\uddf1\ud83c[\udde6-\udde8\uddee\uddf0\uddf7-\uddfb\uddfe]|\ud83c\uddf2\ud83c[\udde6\udde8-\udded\uddf0-\uddff]|\ud83c\uddf3\ud83c[\udde6\udde8\uddea-\uddec\uddee\uddf1\uddf4\uddf5\uddf7\uddfa\uddff]|\ud83c\uddf4\ud83c\uddf2|\ud83c\uddf5\ud83c[\udde6\uddea-\udded\uddf0-\uddf3\uddf7-\uddf9\uddfc\uddfe]|\ud83c\uddf6\ud83c\udde6|\ud83c\uddf7\ud83c[\uddea\uddf4\uddf8\uddfa\uddfc]|\ud83c\uddf8\ud83c[\udde6-\uddea\uddec-\uddf4\uddf7-\uddf9\uddfb\uddfd-\uddff]|\ud83c\uddf9\ud83c[\udde6\udde8\udde9\uddeb-\udded\uddef-\uddf4\uddf7\uddf9\uddfb\uddfc\uddff]|\ud83c\uddfa\ud83c[\udde6\uddec\uddf2\uddf8\uddfe\uddff]|\ud83c\uddfb\ud83c[\udde6\udde8\uddea\uddec\uddee\uddf3\uddfa]|\ud83c\uddfc\ud83c[\uddeb\uddf8]|\ud83c\uddfd\ud83c\uddf0|\ud83c\uddfe\ud83c[\uddea\uddf9]|\ud83c\uddff\ud83c[\udde6\uddf2\uddfc]|\ud83c[\udccf\udd8e\udd91-\udd9a\udde6-\uddff\ude01\ude32-\ude36\ude38-\ude3a\ude50\ude51\udf00-\udf21\udf24-\udf84\udf86-\udf93\udf96\udf97\udf99-\udf9b\udf9e-\udfc1\udfc5\udfc6\udfc8\udfc9\udfcc-\udff0\udff3-\udff5\udff7-\udfff]|\ud83d[\udc00-\udc41\udc44\udc45\udc51-\udc65\udc6a-\udc6d\udc6f\udc79-\udc7b\udc7d-\udc80\udc84\udc88-\udca9\udcab-\udcfd\udcff-\udd3d\udd49-\udd4e\udd50-\udd67\udd6f\udd70\udd73\udd74\udd76-\udd79\udd87\udd8a-\udd8d\udda5\udda8\uddb1\uddb2\uddbc\uddc2-\uddc4\uddd1-\uddd3\udddc-\uddde\udde1\udde3\udde8\uddef\uddf3\uddfa-\ude44\ude48-\ude4a\ude80-\udea2\udea4-\udeb3\udeb7-\udebf\udec1-\udec5\udecb-\uded0\udee0-\udee5\udee9\udeeb\udeec\udef0\udef3]|\ud83e[\udd10-\udd17\udd80-\udd84\uddc0]|[\u2328\u23cf\u23e9-\u23f3\u23f8-\u23fa\u2602-\u2604\u2618\u2620\u2622\u2623\u2626\u262a\u262e\u262f\u2638\u2692\u2694\u2696\u2697\u2699\u269b\u269c\u26b0\u26b1\u26c8\u26ce\u26cf\u26d1\u26d3\u26e9\u26f0\u26f1\u26f4\u26f7\u26f8\u2705\u271d\u2721\u2728\u274c\u274e\u2753-\u2755\u2763\u2795-\u2797\u27b0\u27bf\ue50a]|(?:\ud83c[\udc04\udd70\udd71\udd7e\udd7f\ude02\ude1a\ude2f\ude37]|[\u00a9\u00ae\u203c\u2049\u2122\u2139\u2194-\u2199\u21a9\u21aa\u231a\u231b\u24c2\u25aa\u25ab\u25b6\u25c0\u25fb-\u25fe\u2600\u2601\u260e\u2611\u2614\u2615\u2639\u263a\u2648-\u2653\u2660\u2663\u2665\u2666\u2668\u267b\u267f\u2693\u26a0\u26a1\u26aa\u26ab\u26bd\u26be\u26c4\u26c5\u26d4\u26ea\u26f2\u26f3\u26f5\u26fa\u26fd\u2702\u2708\u2709\u270f\u2712\u2714\u2716\u2733\u2734\u2744\u2747\u2757\u2764\u27a1\u2934\u2935\u2b05-\u2b07\u2b1b\u2b1c\u2b50\u2b55\u3030\u303d\u3297\u3299])(?:\ufe0f|(?!\ufe0e))/g

    Loader {
        active: {
            if (model.section === "offline")
                return true

            // either this is the first message, or the message was a long time ago..
            if ((model.timespan === -1 ||
                 model.timespan > 3600 /* one hour */))
                return true

            return false
        }

        sourceComponent: Rectangle{
            x: delegate.width / 2 - 100
            y: -3
            width: 200
            height: 31
            color: styleHelper.outgoingMessageColor
            radius: 6
            opacity: 0.8

            Label {
                anchors.centerIn: parent
                //: %1 nickname
                text: {
                    if (model.section === "offline")
                        return qsTr("%1 is offline").arg(contact !== null ? contact.nickname : "")
                    else
                        return Qt.formatDateTime(model.timestamp, Qt.DefaultLocaleShortDate)
                }
                textFormat: Text.PlainText
                width: parent.width
                elide: Text.ElideRight
                horizontalAlignment: Qt.AlignHCenter
                color: palette.text
                height: 28
                font.pointSize: styleHelper.pointSize * 0.8
                verticalAlignment: Qt.AlignVCenter
            }
        }
    }
    Item{
        width: parent.width
        height: background.height

    Image {
        id: groupUserIcon
        visible: !model.isOutgoing && model.group_user_id_hash !== ""
        width: 25
        height: 25
        sourceSize.height: height
        sourceSize.width: width
        x: 5
        clip: true
        fillMode: Image.PreserveAspectFit
        source: "image://jazzicon/" + model.group_user_id_hash.replace(/[^a-fA-F0-9]/g,'')

        MouseArea {
            anchors.fill: parent
        }
    }

    Rectangle {
        //Drop Shadow
        Rectangle {
            x: 1
            y: 1
            width: parent.width + 1
            height:parent.height + 1
            color: messageChildItem == imageField ? "transparent" : "black"
            opacity: 0.4
            radius: 6
        }
        Rectangle {
            x: 1
            y: 1
            width: parent.width
            height:parent.height
            color: messageChildItem == imageField ? "transparent" : "black"
            opacity: 0.4
            radius: 6
        }
        Rectangle {
            x: 1
            y: 1
            width: parent.width - 1
            height:parent.height - 1
            color: messageChildItem == imageField ? "transparent" : "black"
            opacity: 0.4
            radius: 6
        }
        // - Drop Shadow

        id: background
        width: Math.max(30, message.width + 12)
        height: message.height + 12
        x: model.isOutgoing ? parent.width - width - 11 : model.group_user_id_hash !== "" ? 35 : 10
        radius: 5
        border.color: "transparent"

        property int __maxWidth: parent.width * 0.8

        color: messageChildItem == imageField ? "transparent" : (model.status === ConversationModel.Error) ? "#ffdcc4" : ( model.isOutgoing ? styleHelper.outgoingMessageColor : styleHelper.incomingMessageColor )
        Behavior on color { ColorAnimation { } }

        Rectangle {
            rotation: 45
            width: 10
            height: 10
            x: model.isOutgoing ? parent.width - 20 : 10
            y: model.isOutgoing ? parent.height - 5 : -5
            color: messageChildItem == imageField ? "transparent" : parent.color
        }

        Rectangle {
            anchors.fill: parent
            radius: 5
            anchors.margins: 0
            visible: opacity > 0
            color: messageChildItem == imageField ? "transparent" : parent.color
        }
        Label{
            text: "E"
            height: 14
            width: 16
            font.pixelSize: 13
            font.family: iconFont.name
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            opacity: {
                return (model.status === ConversationModel.Sending || model.status === ConversationModel.Queued || model.status === ConversationModel.Error) || (!model.isOutgoing) ? 0 : 1
            }
            visible: opacity > 0
            color: styleHelper.darkMode ? Qt.darker(palette.highlight, 1.5) : Qt.darker(palette.highlight, 1.5)

            Behavior on opacity { NumberAnimation { } }
        }

        Rectangle
        {
            id: message
            radius: 5

            property Item childItem: {
                if (model.type == "text")
                {
                    if(model.text !== "" && model.text.indexOf("\n") === -1 && model.text.indexOf("\r") === -1){
                        const found = model.text.match("^<img name=([A-Za-z0-9-_. ]{0,40}) width=(\\d{1,4}) height=(\\d{1,4}) src=data:((?:\\w+\/(?:(?!;).)+)?)((?:;[\\w\\W]*?[^;])*),(.+)>$");
                        if(found){
                            imageField.source =  "image://base64r/" + found[6]
                            imageCaption.text = found[1]
                            return imageField;
                        }
                    }
                    return textField;
                }
                else if (model.type =="transfer")
                {
                    return transferField;
                }
            }

            width: childItem.width
            height: childItem.height
            x: Math.round((background.width - width) / 2)
            y: 6

            color: "transparent"

            TextEdit {
                id: textField
                visible: parent.childItem === this
                width: Math.min(implicitWidth, background.__maxWidth)
                height: contentHeight

                renderType: Text.NativeRendering
                textFormat: text.includes("<html><head><meta name=\"qrichtext\"") ? TextEdit.RichText : TextEdit.PlainText
                color: palette.text
                onLinkHovered: {
                    selected_image = link
                }
                selectionColor: !model.isOutgoing ? styleHelper.outgoingMessageColor : styleHelper.incomingMessageColor
                selectedTextColor: palette.highlightedText
                font.pixelSize: 13
                font.family: styleHelper.fontFamily

                wrapMode: TextEdit.Wrap
                readOnly: true
                selectByMouse: true
                text: {
                    if(model.text != ""){
                        if(typeof(model.group_user_nickname) != "undefined" && model.group_user_nickname.length > 0){
                            return "<p style=\"color:#308cc6;font-weight:700;margin-bottom:5px;\">" + model.group_user_nickname.replace(/[^a-zA-Z0-9\-_, ]/g,'') + " (" + hexToBase64(model.group_user_id_hash.replace(/[^a-fA-F0-9]/g,'')) + ")" + "</p>" + model.text.replace(emojiRegex, emojiPicker.replaceEmojiWithImage)
                        }
                        else
                            return model.text.replace(emojiRegex, emojiPicker.replaceEmojiWithImage)
                    }
                    else
                        return model.prep_text
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton

                    onClicked: delegate.showContextMenu()
                }
            }

            Image {
                id: imageField
                visible: parent.childItem === this
                width: Math.min(Math.min(implicitWidth, background.__maxWidth*0.6), 450)
                clip: true
                fillMode: Image.PreserveAspectFit

                Rectangle{
                    visible: imageCaption.text != "" && typeof(imageCaption) != "undefined"
                    color: palette.base
                    opacity: 0.85
                    radius: 3
                    TextField{
                        width: imageField.width
                        id: imageCaption
                        text: ""
                        readOnly: true
                        validator: RegExpValidator{regExp: /^[A-Za-z0-9-_. ]+$/}
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton

                    onClicked: delegate.showContextMenu()
                }
            }

            // sending file transfer
            Rectangle {
                id: transferField
                visible: parent.childItem === this

                width: 256
                height: transferDisplay.height

                color: "transparent"

                Row {
                    x: 0
                    y: 0
                    width: parent.width
                    height: parent.height
                    spacing: 6

                    Column {
                        id: transferDisplay

                        width: parent.width - (acceptButton.visible ? (acceptButton.width + parent.spacing) : 0) - parent.spacing - cancelButton.width
                        spacing: 6

                        Text {
                            id: filename

                            width: parent.width
                            height: styleHelper.pointSize * 1.5
                            color: palette.text

                            text: model.transfer ? model.transfer.file_name : ""
                            font.bold: true
                            font.pointSize: styleHelper.pointSize
                            elide: Text.ElideMiddle
                            Accessible.role: Accessible.StaticText
                            Accessible.name: text
                            //: Description of the text displaying the filename of a file transfer, used by accessibility tech like screen readres
                            Accessible.description: qsTr("File transfer file name");
                        }

                        ProgressBar {
                            id: progressBar

                            width: parent.width
                            height: visible ? 8 : 0

                            visible: model.transfer ?
                                    (model.transfer.status === ConversationModel.Pending ||
                                     model.transfer.status === ConversationModel.InProgress ||
                                     model.transfer.status === ConversationModel.Accepted) : false

                            indeterminate: model.transfer ? (model.transfer.status === ConversationModel.Pending) : true
                            value: model.transfer ? model.transfer.progressPercent : 0

                            Accessible.role: Accessible.ProgressBar
                            //: Description of progress bar displaying the file transfer progress, used by accessibility tech like screen readers
                            Accessible.description: qsTr("File transfer progress");
                        }

                        Label {
                            id: transferStatus

                            width: parent.width
                            height: styleHelper.pointSize * 1.5

                            text: model.transfer ? model.transfer.statusString : ""
                            font.pointSize: filename.font.pointSize * 0.8;
                            color: Qt.lighter(filename.color, 1.5)
                            Accessible.role: Accessible.StaticText
                            Accessible.name: text
                            //: Description of label displaying the current status of a file transfer, used by accessibility tech like screen readers
                            Accessible.description: qsTr("File transfer status")
                        }
                    }

                    Action {
                        id: downloadAction
                        text: qsTr("Download '%1'").arg(filename.text);
                        onTriggered: {
                            contact.conversation.tryAcceptFileTransfer(model.transfer.id);
                        }
                    }

                    Button {
                        id: acceptButton

                        visible: model.transfer ? (model.transfer.status === ConversationModel.Pending && model.transfer.direction === ConversationModel.Downloading) : false

                        width: visible ? transferDisplay.height : 0
                        height: visible ? transferDisplay.height : 0

                        text: ""
                        Accessible.role: Accessible.Button
                        //: Label for file transfer 'Download' button for accessibility tech like screen readers
                        Accessible.name: qsTr("Download")
                        //: Description of what the file transfer 'Download' button does for accessibility tech like screen readers
                        Accessible.description: qsTr("Download file")

                        style: ButtonStyle {
                            background: Rectangle {
                                implicitWidth: cancelButton.width
                                implicitHeight: cancelButton.height
                                radius: cancelButton.width / 2
                                color: Qt.lighter(( !model.isOutgoing ? styleHelper.outgoingMessageColor : styleHelper.incomingMessageColor ), control.hovered ? 1.3 : 1)
                            }
                        }
                        Label {
                            text: "C"
                            anchors.centerIn: parent
                            font.pointSize: 20
                            color: palette.text
                            horizontalAlignment: Qt.AlignHCenter
                            verticalAlignment: Qt.AlignVCenter
                            font.family: iconFont.name
                        }
                        action: downloadAction
                    }

                    Action {
                        id: rejectFileTransferAction
                        text: qsTr("Reject file transfer");
                        onTriggered: {
                            contact.conversation.rejectFileTransfer(model.transfer.id);
                        }
                    }

                    Action {
                        id: cancelFileTransferAction
                        text: qsTr("Cancel file transfer");
                        onTriggered: {
                            contact.conversation.cancelFileTransfer(model.transfer.id);
                        }
                    }

                    Button {
                        id: cancelButton
                        visible: model.transfer ?
                                (model.transfer.status === ConversationModel.Pending ||
                                 model.transfer.status === ConversationModel.InProgress ||
                                 model.transfer.status === ConversationModel.Accepted) : false

                        width: visible ? transferDisplay.height : 0
                        height: visible ? transferDisplay.height : 0

                        text: ""
                        Accessible.role: Accessible.Button
                        //: Label for file transfer 'Cancel' button for accessibility tech like screen readers
                        Accessible.name: qsTr("Cancel or reject")
                        //: Description of what the file transfer 'Cancel' button does for accessibility tech like screen readers
                        Accessible.description: qsTr("Cancels or rejects a file transfer")

                        style: ButtonStyle {
                            background: Rectangle {
                                implicitWidth: cancelButton.width
                                implicitHeight: cancelButton.height
                                radius: cancelButton.width / 2
                                color: Qt.lighter(( !model.isOutgoing ? styleHelper.outgoingMessageColor : styleHelper.incomingMessageColor ), control.hovered ? 1.3 : 1)
                            }
                        }

                        action: acceptButton.visible ? rejectFileTransferAction : cancelFileTransferAction
                        Label {
                            text: "T"
                            anchors.centerIn: parent
                            font.pointSize: 20
                            color: palette.text
                            horizontalAlignment: Qt.AlignHCenter
                            verticalAlignment: Qt.AlignVCenter
                            font.family: iconFont.name
                        }
                    }
                }
            }
        }
    }
    }

    function showContextMenu() {
        copy_selected_image = selected_image
        var object = rightClickContextMenu.createObject(delegate, { })
        object.popupVisibleChanged.connect(function() { if (!object.visible) object.destroy(1000) })
        object.popup()
    }

    Component {
        id: rightClickContextMenu

        Menu {
            MenuItem {
                //: Text for context menu command to copy an entire message to clipboard
                text: qsTr("Copy Message")
                visible: messageChildItem == textField && textField.selectedText.length == 0
                onTriggered: {
                    Clipboard.copyText(textField.getText(0, textField.length))
                }
            }

            Action {
                id: copySelectionAction
                text: qsTr("Copy Selection")
                shortcut: StandardKey.Copy
                onTriggered: textField.copy()
            }

            MenuItem {
                //: Text for context menu command to copy selected text to clipboard
                text: qsTr("Copy Selection")
                visible: messageChildItem == textField && textField.selectedText.length > 0
                action: copySelectionAction
            }

            MenuItem {
                //: Context menu quote message
                visible: messageChildItem == textField
                text: qsTr("Quote")
                onTriggered: {
                    textInputMain.insert(textInputMain.cursorPosition, '<table style="margin:10px;margin-left:10px;padding-left:6px;color:grey;"><tr><td width=3 bgcolor="grey"/><td>' + textField.text + "</td></tr></table><br />")
                }
            }

            MenuItem {
                //: Context menu quote message
                text: qsTr("Save Image")
                visible: copy_selected_image != "" || messageChildItem == imageField ? true : false
                onTriggered: {
                    if(messageChildItem == textField){
                        const regex = '<a href="' + copy_selected_image + '"><img.* src="data:image/([a-zA-Z]+);base64,([A-Za-z0-9+/=]+)';
                        const found = textField.text.match(regex);
                        utility.saveBase64(found[2],"1",found[1])
                    }
                    else if(messageChildItem == imageField){
                        const found = model.text.match("^<img name=([A-Za-z0-9-_. ]{0,40}) width=(\\d{1,4}) height=(\\d{1,4}) src=data:((?:\\w+\/(?:(?!;).)+)?)((?:;[\\w\\W]*?[^;])*),(.+)>$");
                        if(found){
                            var cap = found[1].replace("./g","")
                            if(cap == "")
                                cap = "Image"
                            utility.saveBase64(found[6],cap,"jpg")
                        }
                    }
                }
            }
            MenuItem {
                //: Context menu quote message
                text: qsTr("View Image")
                visible: copy_selected_image != "" || messageChildItem == imageField ? true : false
                onTriggered: {
                    if(messageChildItem == textField){
                        const regex = '<a href="' + copy_selected_image + '"><img.* src="data:image/([a-zA-Z]+);base64,([A-Za-z0-9+/=]+)';
                        const found = textField.text.match(regex);
                        var object = createDialog("ImageViewerDialog.qml", { "imageData": found[2] }, window)
                        object.visible = true
                    }
                    else if(messageChildItem == imageField){
                        const found = model.text.match("^<img name=([A-Za-z0-9-_. ]{0,40}) width=(\\d{1,4}) height=(\\d{1,4}) src=data:((?:\\w+\/(?:(?!;).)+)?)((?:;[\\w\\W]*?[^;])*),(.+)>$");
                        if(found){
                            var object = createDialog("ImageViewerDialog.qml", { "imageData": found[6] }, window)
                            object.visible = true
                        }
                    }
                }
            }

            MenuItem {
                //: Text for context menu command to copy selected text to clipboard
                text: qsTr("Remove Message")
                visible: messageChildItem == textField && !model.isOutgoing
                onTriggered: {
                    textField.text = "Removed"
                }
            }
        }
    }
}
