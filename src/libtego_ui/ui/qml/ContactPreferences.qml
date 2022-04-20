import QtQuick 2.0
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.0
import QtQuick.Dialogs 1.0
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
            id: fileDialog
            nameFilters: ["Images (*.png *.jpg *.jpeg)"]
            onAccepted: {
                var b = utility.toBase64_PNG(fileDialog.fileUrl.toString(), 300, 300);
                if(b.length < 55000){
                    contactInfo.contact.icon = b
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
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: {
                            if (mouse.button === Qt.RightButton) { // 'mouse' is a MouseEvent argument passed into the onClicked signal handler
                                profilePictureContextMenu.popup()
                            } else if (mouse.button === Qt.LeftButton) {
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

                    MouseArea { anchors.fill: parent; onDoubleClicked: nicknameLayout.renameMode = true }

                    Component {
                        id: renameComponent

                        TextField {
                            /*
                            background: Rectangle{
                                color: palette.base
                            }*/
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
                                nicknameLayout.renameMode = false
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
                    onClicked: contactActions.removeContact()
                    Component.onCompleted: {if(Qt.platform.os !== "android")contentItem.color = palette.text}
                    Accessible.role: Accessible.Button
                    Accessible.name: text
                    //: Description of button which removes a user from the contact list for accessibility tech like screen readers
                    Accessible.description: qsTr("Removes this contact")
                    Material.background: Material.Red
                }
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
