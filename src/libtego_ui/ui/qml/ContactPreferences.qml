import QtQuick 2.0
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.0
import QtQuick.Dialogs 1.1
import QtQuick.Controls.Styles 1.2
import QtQuick.Controls.Material 2.15
import im.utility 1.0
import im.ricochet 1.0

Item {
    property alias selectedContact: contacts.selectedContact

    RowLayout {
        Utility {
           id: utility
        }

        FileDialog {
            id: folderDialog
            selectFolder: true
            onAccepted: {
                var path = folderDialog.folder.toString()
                path = path.replace(/^(file:\/{2})/,"")
                path = decodeURIComponent(path);
                autoDownloadDir.text = path
            }
        }

        MessageDialog {
            id: fileSizeWarningDialog
            title: "File size limit exceeded"
            text: "The size of the selected file is too large. Please select a different one."
            onAccepted: {
                visible = false
            }
        }

        FileDialog {
            id: fileDialog
            nameFilters: ["Images (*.png *.jpg *.jpeg)"]
            onAccepted: {
                handleContactIconImage(fileDialog.fileUrl.toString(), 50)
            }

            function handleContactIconImage(fileLocation, quality){
                var b = utility.toBase64_JPG(fileLocation, 300, 300, quality);
                if(b.length < 25000){
                    contactInfo.contact.icon = b
                    if(typeof(contactPreferencesWindow) != "undefined")
                        contactPreferencesWindow.close()
                }
                else if(quality > 30){
                    handleContactIconImage(fileLocation, 30)
                }
                else if(quality > 20){
                    handleContactIconImage(fileLocation, 20)
                }
                else if(quality > 10){
                    handleContactIconImage(fileLocation, 10)
                }
                else if(quality > 5){
                    handleContactIconImage(fileLocation, 5)
                }
                else if(quality > 0){
                    handleContactIconImage(fileLocation, 0)
                }
                else{
                    fileSizeWarningDialog.visible = true
                    if(typeof(contactPreferencesWindow) != "undefined")
                        contactPreferencesWindow.close()
                }
            }
        }

        anchors {
            fill: parent
            margins: 8
        }

        ContactList {
            visible: Qt.platform.os !== "android"
            id: contacts
            Layout.preferredWidth: 210
            Layout.minimumWidth: 150
            Layout.fillHeight: true
            startIndex: 0

            Accessible.role: Accessible.List
            //: Description of the list of contacts for accessibility tech like screen readers
            Accessible.name: qsTr("Contact list")
        }

        data: [
            ContactActions {
                id: contactActions
                contact: contacts.selectedContact
            }
        ]

        ColumnLayout {
            id: contactInfo
            visible: contact !== null
            Layout.fillHeight: true
            Layout.fillWidth: true

            property QtObject contact: contacts.selectedContact
            property QtObject request: (contact !== null) ? contact.contactRequest : null

            Item { height: 1; width: 1 }

            Rectangle{
                width: Qt.platform.os === "android" ? 160 : 80
                height: Qt.platform.os === "android" ? 160 : 80
                Layout.alignment: Qt.AlignCenter
                color: "transparent"

                ColorLetterCircle {
                    width: parent.width
                    height: parent.height
                    name: visible ? contactInfo.contact.nickname : ""
                    icon: visible ? typeof(contactInfo.contact.icon) !== "undefined" ? contactInfo.contact.icon : "" : ""
                }
                Button{
                    id: button2
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    width: Qt.platform.os === "android" ? 50 : 35
                    height: Qt.platform.os === "android" ? 50 : 35

                    background: Rectangle {
                        implicitWidth: Qt.platform.os === "android" ? 50 : 35
                        implicitHeight: Qt.platform.os === "android" ? 50 : 35
                        radius: Qt.platform.os === "android" ? 25 : 18
                        color: palette.base
                        border.color: styleHelper.borderColor2
                        border.width: 1
                    }
                    contentItem: Text {
                        text: "I"
                        font.family: iconFont.name
                        font.pixelSize: Qt.platform.os === "android" ? 24 : 18
                        horizontalAlignment: Qt.AlignHCenter
                        verticalAlignment: Qt.AlignVCenter
                        renderType: Text.QtRendering
                        color: button2.hovered ? palette.text : styleHelper.chatIconColor
                    }

                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        signal pressAndHold()

                        onPressAndHold: {
                            if (Qt.platform.os === "android") {
                                profilePictureContextMenu.popup()
                            }
                        }

                        Timer {
                            id: longPressTimer

                            interval: 2000
                            repeat: false
                            running: false

                            onTriggered: {
                                ma.pressAndHold()
                            }
                        }


                        onPressedChanged: {
                            if ( pressed ) {
                                longPressTimer.running = true;
                            } else {
                                longPressTimer.running = false;
                            }
                        }

                        onClicked: {
                            if (mouse.button === Qt.RightButton) { // 'mouse' is a MouseEvent argument passed into the onClicked signal handler
                                profilePictureContextMenu.popup()
                            } else if (mouse.button === Qt.LeftButton) {
                                if(profilePictureContextMenu.visible === false)
                                    fileDialog.open()
                            }
                        }
                    }

                    Menu {
                        id: profilePictureContextMenu

                        /* QT automatically sets Accessible.text to MenuItem.text */
                        MenuItem {
                            //: Profile picture context menu command to remove the image and reset to the default
                            text: qsTr("Remove Picture")
                            onTriggered: {
                                contactInfo.contact.icon = ""
                            }
                        }
                    }
                }
            }




            RowLayout {
                id: nicknameLayout
                property bool renameMode
                property Item renameItem
                onRenameModeChanged: {
                    if (renameMode && renameItem === null) {
                        renameItem = renameComponent.createObject(nickname)
                        renameItem.forceActiveFocus()
                        renameItem.selectAll()
                    } else if (!renameMode && renameItem !== null) {
                        renameItem.focus = false
                        renameItem.visible = false
                        renameItem.destroy()
                        renameItem = null
                    }
                }

                spacing: 0
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignCenter

                Label {
                    id: nickname
                    Layout.fillWidth: nicknameLayout.renameMode
                    text: visible && !nicknameLayout.renameMode ? contactInfo.contact.nickname : ""
                    textFormat: Text.PlainText
                    horizontalAlignment: Qt.AlignHCenter
                    Layout.alignment: Qt.AlignCenter
                    font.pointSize: styleHelper.pointSize + 1

                    Component {
                        id: renameComponent

                        TextField {
                            id: nameField
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                            }
                            text: contactInfo.contact.nickname
                            horizontalAlignment: nickname.horizontalAlignment
                            font.pointSize: nickname.font.pointSize
                            onEditingFinished: {
                                contactInfo.contact.nickname = text
                            }
                        }
                    }
                }

                Button {
                    id: button1
                    Layout.alignment: Qt.AlignTop
                    onClicked: nicknameLayout.renameMode = !nicknameLayout.renameMode

                    background: Rectangle {
                        implicitWidth: 14
                        implicitHeight: 14
                        color: "transparent"
                    }
                    contentItem: Text {
                        text: nicknameLayout.renameMode ? "h" : "A"
                        font.family: iconFont.name
                        font.pixelSize: 14
                        horizontalAlignment: Qt.AlignLeft
                        renderType: Text.QtRendering
                        color: button1.hovered ? styleHelper.textColor : styleHelper.chatIconColor
                    }
                }
            }


            Item { height: 1; width: 1 }

            ContactIDField {
                Layout.fillWidth: true
                Layout.minimumWidth: 100
                readOnly: true
                text: visible ? contactInfo.contact.contactID : ""

                Accessible.role: Accessible.StaticText
                //: Description of text box containing a contact's contact id for accessibility tech like screen readers
                Accessible.name: qsTr("Contact ID for ") +
                                 visible ?
                                 nickname.text :
                //: A placeholder name for a contact whose name we do not know
                                 qsTr("Unknown user")
                Accessible.description: text
            }

            Item { height: 1; width: 1 }

            RowLayout {
                Layout.fillWidth: true

                Item { Layout.fillWidth: true; height: 1 }

                Button {
                    //: Label for button which removes a contact from the contact list
                    text: qsTr("Remove")
                    onClicked: {
                        contactActions.removeContact()
                    }
                    Component.onCompleted: {if(Qt.platform.os !== "android")contentItem.color = palette.text}
                    Accessible.role: Accessible.Button
                    Accessible.name: text
                    //: Description of button which removes a user from the contact list for accessibility tech like screen readers
                    Accessible.description: qsTr("Removes this contact")
                    Material.background: Material.Red
                }
            }

            SettingsSwitch{
                visible: !uiMain.isGroupHostMode
                //: Text description of an option to always save the conversation with a user and restore ist after a restart
                text: qsTr("Always save conversations with this user")
                position: contactInfo.contact.save_messages || false
                switchIcon: "qrc:/icons/android/settings_android/settings_rich_text.svg"
                triggered: function(checked){
                    contactInfo.contact.save_messages = checked
                }
            }

            SettingsSwitch{
                visible: contactInfo.contact.save_messages && !uiMain.isGroupHostMode || false
                //: Text description of an option to send the saved undelivered messages after restarting
                text: qsTr("Try to send undelivered messages after a restart")
                position: contactInfo.contact.send_undelivered_messages_after_resume || false
                switchIcon: "qrc:/icons/android/settings_android/settings_rich_text.svg"
                triggered: function(checked){
                    contactInfo.contact.send_undelivered_messages_after_resume = checked
                }
            }

            SettingsSwitch{
                visible: Qt.platform.os !== "android" && Qt.platform.os !== "macos" && !uiMain.isGroupHostMode && !contactInfo.contact.is_a_group
                //: Text description of an option to always automatically download files from a user
                text: qsTr("Always automatically accept and download files")
                position: contactInfo.contact.auto_download_files || false
                switchIcon: "qrc:/icons/android/settings_android/settings_rich_text.svg"
                triggered: function(checked){
                    contactInfo.contact.auto_download_files = checked
                }
            }

            RowLayout {
                visible: contactInfo.contact.auto_download_files && !uiMain.isGroupHostMode && Qt.platform.os !== "android" && Qt.platform.os !== "macos" && !contactInfo.contact.is_a_group || false
                TextField {
                    id: autoDownloadDir

                    text: contactInfo.contact.auto_download_dir !== "" ? contactInfo.contact.auto_download_dir : "~/Downloads"
                    Layout.minimumWidth: 80
                    Layout.maximumHeight: Qt.platform.os === "android" ? 50 : 33
                    Layout.fillWidth: true

                    onTextChanged: {
                        contactInfo.contact.auto_download_dir = autoDownloadDir.text
                    }

                    Accessible.role: Accessible.EditableText
                    //: Name of the text input used to set the auto download directory
                    Accessible.name: qsTr("Custom chat area background input field")
                    //: Description of what the auto download directory input is for accessibility tech like screen readers
                    Accessible.description: qsTr("Where the automatically downloaded files should be stored")
                }
                Button {
                    //: Label for button which allows the selecting of the auto download location
                    text: qsTr("Select Folder")
                    onClicked: folderDialog.open()
                    Component.onCompleted: {if(Qt.platform.os !== "android")contentItem.color = palette.text}
                    Accessible.role: Accessible.Button
                    Accessible.name: text
                    //: Description of button which allows the selection auto download directory for accessibility tech like screen readers
                    Accessible.description: qsTr("Select a folder to store automatically downloaded files")
                }
                Item{width:5;height:1}
            }

            Item {
                Layout.fillHeight: true
                width: 1
            }

            Accessible.role: Accessible.Window
            //: Description of the contents of the 'Contacts' window for accessibility tech like screen readers
            Accessible.name: qsTr("Preferences for contact ") +
                             visible ?
                             nickname.text :
                             //: A placeholder name for a contact whose name we do not know
                             qsTr("Unknown user")
        }
    }
    Accessible.role: Accessible.Window
    //: Name of the contact preferences window for accessibility tech like screen readers
    Accessible.name: qsTr("Contact Preferences Window")
    //: Description of what user can do in the contact preferences window for accessibility tech like screen readers
    Accessible.description: qsTr("A list of all your contacts, with their Speek IDs, and options such as renaming and removing")
}
