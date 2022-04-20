import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.0
import QtQuick.Controls.Styles 1.2
import im.utility 1.0

ApplicationWindow {
    id: sendImageDialog
    flags: Qt.platform.os == "android" ? null : Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    modality: Qt.platform.os == "android" ? undefined : Qt.WindowModal
    width: minimumWidth
    height: 160 + baseImage.paintedHeight
    minimumWidth: 350
    maximumWidth: minimumWidth
    minimumHeight: 300
    title: "Speek.Chat"
    x: Qt.platform.os == "android" ? 0 : mainWindow.x + ((mainWindow.width - width) / 2)
    y: Qt.platform.os == "android" ? 0 : mainWindow.y + ((mainWindow.height - height) / 2)

    property string imageBase64: ""
    property string imageBase64_send: ""
    property var conversationModel: null

    signal closed
    onVisibleChanged: if (!visible) closed()

    color: Qt.platform.os === "android" ? palette.window : "transparent"

    function close() {
        visible = false
    }

    Utility {
       id: utility
    }

    Rectangle{
        radius: 5
        anchors.fill: parent
        color: Qt.platform.os === "android" ? palette.window : "transparent"
        Rectangle {
            x: 3
            y: 3
            visible: Qt.platform.os !== "android"
            width: parent.width - 5
            height:parent.height - 5
            color: "black"
            opacity: 0.4
            radius: 6
        }
        Rectangle {
            x: 3
            y: 3
            visible: Qt.platform.os !== "android"
            width: parent.width - 4
            height:parent.height - 4
            color: "black"
            opacity: 0.4
            radius: 6
        }
        Rectangle {
            x: 3
            y: 3
            visible: Qt.platform.os !== "android"
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
                    Layout.minimumHeight: Qt.platform.os === "android" ? 50 : 33

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
                    Component.onCompleted: {if(Qt.platform.os !== "android")contentItem.color = palette.text}
                    onClicked: {
                        var msg = imageBase64_send.replace("%Name%", caption.text)
                        if(conversationModel.contact.is_a_group){
                            var obj = {};
                            obj["message"] = msg
                            obj["name"] = typeof(uiSettings.data.username) !== "undefined" ? uiSettings.data.username : "Anonymous" + chatFocusScope.groupIdentifier
                            obj["id"] = utility.toHash(userIdentity.contactID)
                            msg = JSON.stringify(obj)
                        }
                        conversationModel.sendMessage(msg)

                        sendImageDialog.close()
                    }
                    Layout.fillWidth: Qt.platform.os === "android" ? true : false

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
                    Component.onCompleted: {if(Qt.platform.os !== "android")contentItem.color = palette.text}
                    Layout.fillWidth: Qt.platform.os === "android" ? true : false
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

    Component.onCompleted: {
        if(Qt.platform.os === "android"){
            contentItem.Keys.released.connect(function(event) {
                if (event.key === Qt.Key_Back) {
                    event.accepted = true
                    sendImageDialog.back()
                }
            })
        }
    }

    function back() {
        sendImageDialog.close()
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
