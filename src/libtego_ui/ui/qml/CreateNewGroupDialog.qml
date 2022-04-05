import QtQuick 2.2
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import im.utility 1.0

ApplicationWindow {
    id: createNewGroupDialog
    width: 840
    height: 560
    minimumWidth: width
    maximumWidth: width
    minimumHeight: height
    maximumHeight: height
    flags: styleHelper.dialogWindowFlags
    modality: Qt.WindowModal
    title: mainWindow.title

    signal closed
    onVisibleChanged: if (!visible) closed()

    function close() {
        visible = false
    }

    Utility {
       id: utility
    }

    function accept() {
        if (!groupFields.hasValidRequest)
            return

        utility.startGroup(groupFields.name.text, groupFields.name.text, groupFields.message.text, userAddGroup.showHideElements)
        close()
    }

    ColumnLayout {
        id: infoArea
        z: 2
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: 8
            leftMargin: 16
            rightMargin: 16
        }

        Label {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            horizontalAlignment: Qt.AlignHCenter
            wrapMode: Text.Wrap
            //: tells the user to get the Speek ID of their friends to add them as contacts
            text: qsTr("Create a new group and automatically send a invite to the selected contacts.")
            Accessible.role: Accessible.StaticText
            Accessible.name: text
        }
    }



    GridLayout {
        anchors {
            left: parent.left
            right: parent.right
            top: infoArea.bottom
            margins: 8
            leftMargin: 16
            rightMargin: 16
        }

        id: groupFields
        columns: 2

        property bool readOnly
        property TextField name: nameField
        property TextArea message: messageField
        property bool hasValidRequest: nameField.text.length && messageField.text.length

        Label {
            //: Label for the group name text box in the 'create new group' window
            text: qsTr("Group Name:")
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            Accessible.role: Accessible.StaticText
            Accessible.name: text
        }

        TextField {
            text: qsTr("Group Name")
            id: nameField
            Layout.fillWidth: true

            validator: RegExpValidator{regExp: /^[a-zA-Z0-9\-_, ]+$/}

            Accessible.role: Accessible.Dialog
            Accessible.name: text
            //: Description of textbox for setting the group name for accessibility tech like screen readers
            Accessible.description: qsTr("Field for the new groups name")
        }

        Label {
            //: Label for the group invite message text box in the 'create new group' window
            text: qsTr("Group Invite Message:")
            Layout.alignment: Qt.AlignTop | Qt.AlignRight
            Accessible.role: Accessible.StaticText
            Accessible.name: text
        }

        TextArea {
            id: messageField
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            textFormat: TextEdit.PlainText
            Accessible.role: Accessible.Dialog
            Accessible.name: text
            //: Description of textbox for setting a new groups invite greeting message for accessibility tech like screen readers
            Accessible.description: qsTr("Field for the group invite greeting message")
        }
    }
    ColumnLayout{
        anchors {
            left: parent.left
            right: parent.right
            top: groupFields.bottom
            bottom: buttonRow.top
            margins: 8
            leftMargin: 16
            rightMargin: 16
        }
        Label {
            //: Label for the group member to invite selection area
            text: qsTr("Group Member:")
            Layout.alignment: Qt.AlignTop | Qt.AlignRight
            Accessible.role: Accessible.StaticText
            Accessible.name: text
            Layout.fillWidth: true
        }
        RowLayout{
            id: userAddGroup
            property var showHideElements: []
            Layout.fillHeight: true
            Layout.fillWidth: true

            ContactList {
                id: contacts
                Layout.minimumWidth: 300
                Layout.fillHeight: true
                startIndex: 0
                showHide: "hide"

                Accessible.role: Accessible.List
                //: Description of the list of contacts for accessibility tech like screen readers
                Accessible.name: qsTr("Contact list")
            }
            Button{
                text: "add"
                onClicked: {
                    if(contacts.contactListView.currentIndex !== -1){
                        userAddGroup.showHideElements.push(contacts.selectedContact.contactID+";"+contacts.selectedContact.nickname)
                        contacts.showHideElements = userAddGroup.showHideElements
                        contactsSelected.showHideElements = userAddGroup.showHideElements
                    }
                }
            }
            Button{
                text: "remove"
                onClicked: {
                    if(contacts.contactListView.currentIndex !== -1){
                        const index = userAddGroup.showHideElements.indexOf(contactsSelected.selectedContact.contactID+";"+contactsSelected.selectedContact.nickname)
                        if (index > -1) {
                            userAddGroup.showHideElements.splice(index, 1)
                            contacts.showHideElements = userAddGroup.showHideElements
                            contactsSelected.showHideElements = userAddGroup.showHideElements
                        }
                    }
                }
            }
            ContactList {
                id: contactsSelected
                Layout.minimumWidth: 300
                Layout.fillHeight: true
                startIndex: 0
                showHide: "show"

                Accessible.role: Accessible.List
                //: Description of the list of contacts for accessibility tech like screen readers
                Accessible.name: qsTr("Contact list")

                onSelectedContactChanged: {
                }
            }
        }
    }

    RowLayout {
        id: buttonRow
        anchors {
            right: parent.right
            bottom: parent.bottom
            rightMargin: 16
            bottomMargin: 8
        }

        Button {
            //: label for button which dismisses a dialog
            text: qsTr("Cancel")
            onClicked: createNewGroupDialog.close()
            Accessible.role: Accessible.Button
            Accessible.name: text
            //: description for 'Cancel' button accessibility tech like screen readers
            Accessible.description: qsTr("Closes the contact add window")
            Accessible.onPressAction: createNewGroupDialog.close()
        }

        Button {
            //: button label to finish adding a contact/friend
            text: qsTr("Add")
            isDefault: true
            enabled: groupFields.hasValidRequest
            onClicked: createNewGroupDialog.accept()

            Accessible.role: Accessible.Button
            Accessible.name: text
            //: description for 'Add' button for accessibility tech like screen readres
            Accessible.description: qsTr("Adds the contact to your contact list")
            Accessible.onPressAction: createNewGroupDialog.close()
        }
    }

    Action {
        shortcut: StandardKey.Close
        onTriggered: createNewGroupDialog.close()
    }

    Action {
        shortcut: "Escape"
        onTriggered: addContactWindow.close()
    }
}

