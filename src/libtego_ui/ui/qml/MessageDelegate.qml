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

    Rectangle {
        //Drop Shadow
        Rectangle {
            x: 1
            y: 1
            width: parent.width + 1
            height:parent.height + 1
            color: "black"
            opacity: 0.4
            radius: 6
        }
        Rectangle {
            x: 1
            y: 1
            width: parent.width
            height:parent.height
            color: "black"
            opacity: 0.4
            radius: 6
        }
        Rectangle {
            x: 1
            y: 1
            width: parent.width - 1
            height:parent.height - 1
            color: "black"
            opacity: 0.4
            radius: 6
        }
        // - Drop Shadow

        id: background
        width: Math.max(30, message.width + 12)
        height: message.height + 12
        x: model.isOutgoing ? parent.width - width - 11 : 10
        radius: 5
        border.color: "transparent"

        property int __maxWidth: parent.width * 0.8

        color: (model.status === ConversationModel.Error) ? "#ffdcc4" : ( model.isOutgoing ? styleHelper.outgoingMessageColor : styleHelper.incomingMessageColor )
        Behavior on color { ColorAnimation { } }

        Rectangle {
            rotation: 45
            width: 10
            height: 10
            x: model.isOutgoing ? parent.width - 20 : 10
            y: model.isOutgoing ? parent.height - 5 : -5
            color: parent.color
        }

        Rectangle {
            anchors.fill: parent
            radius: 5
            anchors.margins: 0
            visible: opacity > 0
            color: parent.color
        }
        Label{
            text: "E"
            //height: 14
            width: 16
            font.pixelSize: 13
            font.family: iconFont.name
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            opacity: (model.status === ConversationModel.Sending || model.status === ConversationModel.Queued || model.status === ConversationModel.Error) || (!model.isOutgoing) ? 0 : 1
            visible: opacity > 0
            color: styleHelper.darkMode ? palette.highlight : Qt.darker(palette.highlight, 1.5)

            Behavior on opacity { NumberAnimation { } }
        }

        Rectangle
        {
            id: message
            radius: 5

            property Item childItem: {
                if (model.type == "text")
                {
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

            // text message

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
                //font.pointSize: styleHelper.pointSize * 0.9
                font.pixelSize: 13
                font.family: styleHelper.fontFamily

                wrapMode: TextEdit.Wrap
                readOnly: true
                selectByMouse: true
                text: model.text != "" ? model.text : model.prep_text

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
                visible: textField.selectedText.length == 0
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
                visible: textField.selectedText.length > 0
                action: copySelectionAction
            }

            MenuItem {
                //: Context menu quote message
                text: qsTr("Quote")
                onTriggered: {
                    textInputMain.insert(textInputMain.cursorPosition, '<table style="margin:10px;margin-left:10px;padding-left:6px;color:grey;"><tr><td width=3 bgcolor="grey"/><td>' + textField.text + "</td></tr></table><br />")
                }
            }

            MenuItem {
                //: Context menu quote message
                text: qsTr("Save Image")
                visible: copy_selected_image != "" ? true : false
                onTriggered: {
                    const regex = '<a href="' + copy_selected_image + '"><img.* src="data:image/([a-zA-Z]+);base64,([A-Za-z0-9+/=]+)';
                    const found = textField.text.match(regex);
                    utility.saveBase64(found[2],"1",found[1])
                }
            }
            MenuItem {
                //: Context menu quote message
                text: qsTr("View Image")
                visible: copy_selected_image != "" ? true : false
                onTriggered: {
                    const regex = '<a href="' + copy_selected_image + '"><img.* src="data:image/([a-zA-Z]+);base64,([A-Za-z0-9+/=]+)';
                    const found = textField.text.match(regex);
                    var object = createDialog("ImageViewerDialog.qml", { "imageData": found[2] }, window)
                    object.visible = true
                }
            }

            MenuItem {
                //: Text for context menu command to copy selected text to clipboard
                text: qsTr("Remove Message")
                visible: !model.isOutgoing
                onTriggered: {
                    textField.text = "Removed"
                }
            }
        }
    }
}
