import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import QtQuick.Dialogs 1.0
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
                var b = utility.toBase64_PNG(fileDialog.fileUrl.toString(), 100, 100);
                if(b.length < 36000)
                    contactInfo.contact.icon = b
            }
        }

        anchors {
            fill: parent
            margins: 8
        }

        ContactList {
            id: contacts
            Layout.preferredWidth: 200
            Layout.minimumWidth: 150
            Layout.fillHeight: true

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

            ColorLetterCircle {
                width: 80
                height: 80
                name: visible ? contactInfo.contact.nickname : ""
                icon: visible ? typeof(contactInfo.contact.icon) !== "undefined" ? contactInfo.contact.icon : "" : ""
                Layout.alignment: Qt.AlignCenter
            }

            Label {
                id: nickname
                Layout.fillWidth: true
                text: visible ? contactInfo.contact.nickname : ""
                textFormat: Text.PlainText
                horizontalAlignment: Qt.AlignHCenter
                font.pointSize: styleHelper.pointSize + 1

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

                MouseArea { anchors.fill: parent; onDoubleClicked: nickname.renameMode = true }

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
                            nickname.renameMode = false
                        }
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
            Rectangle {
                color: palette.mid
                height: 1
                Layout.fillWidth: true
            }

            RowLayout {
                z: 2
                Label {
                    //: Label for text input where users can specify their username
                    text: qsTr("Profile Picture: ")
                    Accessible.role: Accessible.StaticText
                    Accessible.name: text
                }

                Button {
                    //: Label for button which allows the changing of an user profile picture
                    text: qsTr("Select Picture")
                    onClicked: fileDialog.open()
                    Accessible.role: Accessible.Button
                    Accessible.name: text
                    //: Description of button which allows the selection of a profile picture for an user for accessibility tech like screen readers
                    Accessible.description: qsTr("Select icon for this contact")
                }
                Button {
                    //: Label for button which allows the removal of a profile picture
                    text: qsTr("Remove Picture")
                    onClicked: {
                        contactInfo.contact.icon = ""
                    }
                    Accessible.role: Accessible.Button
                    Accessible.name: text
                    //: Description of button which allows the removal of a profile picture for an user for accessibility tech like screen readers
                    Accessible.description: qsTr("Remove icon for this contact")
                }
            }

            Item { height: 1; width: 1 }

            RowLayout {
                Layout.fillWidth: true

                Button {
                    //: Label for button which allows renaming of a contact
                    text: qsTr("Rename")
                    onClicked: nickname.renameMode = !nickname.renameMode
                    Accessible.role: Accessible.Button
                    Accessible.name: text
                    //: Description of button which renames a contact for accessibility tech like screen readers
                    Accessible.description: qsTr("Renames this contact")
                }

                Item { Layout.fillWidth: true; height: 1 }

                Button {
                    //: Label for button which removes a contact from the contact list
                    text: qsTr("Remove")
                    onClicked: contactActions.removeContact()
                    Accessible.role: Accessible.Button
                    Accessible.name: text
                    //: Description of button which removes a user from the contact list for accessibility tech like screen readers
                    Accessible.description: qsTr("Removes this contact")
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
