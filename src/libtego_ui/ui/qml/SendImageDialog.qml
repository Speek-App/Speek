import QtQuick 2.2
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import QtQuick.Controls.Styles 1.2

ApplicationWindow {
    id: sendImageDialog
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    modality: Qt.WindowModal
    width: minimumWidth
    height: 160 + baseImage.paintedHeight
    minimumWidth: 350
    maximumWidth: minimumWidth
    minimumHeight: 300
    title: "Speek.Chat"
    x: mainWindow.x + ((mainWindow.width - width) / 2)
    y: mainWindow.y + ((mainWindow.height - height) / 2)

    property var imageBase64: ""
    property var imageBase64_send: ""
    property var conversationModel: null

    signal closed
    onVisibleChanged: if (!visible) closed()

    function close() {
        visible = false
    }

    color: "transparent"
    Rectangle{
        radius: 5
        anchors.fill: parent
        color: "transparent"
        Rectangle {
            x: 3
            y: 3
            width: parent.width - 5
            height:parent.height - 5
            color: "black"
            opacity: 0.4
            radius: 6
        }
        Rectangle {
            x: 3
            y: 3
            width: parent.width - 4
            height:parent.height - 4
            color: "black"
            opacity: 0.4
            radius: 6
        }
        Rectangle {
            x: 3
            y: 3
            width: parent.width-6
            height:parent.height-6
            color: palette.window
            radius: parent.radius
        }
        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            Item{
                height: 23
            }

            Image{
                id: baseImage
                Layout.preferredWidth: 300
                Layout.preferredHeight: paintedHeight
                source: "image://base64n/" + imageBase64
                fillMode: Image.PreserveAspectFit
                Layout.alignment: Qt.AlignHCenter
            }

            Item{
                height: 1
            }

            ColumnLayout {
                spacing: 1
                Layout.minimumWidth: 300
                Layout.alignment: Qt.AlignHCenter
                Label {
                    //: Label for text input where users can specify the caption of a sent image
                    text: qsTr("Caption")
                    Accessible.role: Accessible.StaticText
                    Accessible.name: text
                }

                TextField {
                    id: caption
                    text: ""
                    validator: RegExpValidator{regExp: /^[A-Za-z0-9-_. ]+$/}
                    Layout.minimumWidth: 300

                    onTextChanged: {
                        if (length > 39) remove(39, length);
                    }

                    Accessible.role: Accessible.EditableText
                    //: Name of the text input used to enter a caption for a sent image
                    Accessible.name: qsTr("Image caption input field")
                    //: Description of what the image caption input field text input is for accessibility tech like screen readers
                    Accessible.description: qsTr("What the image caption should be")
                }
            }
            Item{
                Layout.fillHeight: true
            }
            RowLayout {
                id: buttonRow

                Item{
                    Layout.fillWidth: true
                }

                Button {
                    //: button label to send a image
                    text: qsTr("Send")
                    onClicked: {
                        conversationModel.sendMessage(imageBase64_send.replace("%Name%", caption.text))
                        sendImageDialog.close()
                    }

                    Accessible.role: Accessible.Button
                    Accessible.name: text
                    //: description for 'Send' button for accessibility tech like screen readres
                    Accessible.description: qsTr("Sends the image")
                    Accessible.onPressAction: addContactWindow.close()
                }

                Button {
                    //: label for button which dismisses a dialog
                    text: qsTr("Close")
                    onClicked: sendImageDialog.close()
                    Accessible.role: Accessible.Button
                    Accessible.name: text
                    //: description for 'Close' button accessibility tech like screen readers
                    Accessible.description: qsTr("Closes the send image dialog")
                    Accessible.onPressAction: selectIdentityDialog.close()
                }
                Item{
                    width: 10
                }
            }
            Item{
                height: 10
            }
        }
    }


    Action {
        shortcut: StandardKey.Close
        onTriggered: sendImageDialog.close()
    }

    Action {
        shortcut: "Escape"
        onTriggered: sendImageDialog.close()
    }
}
