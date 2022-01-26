import QtQuick 2.2
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0

ApplicationWindow {
    id: addContactWindow
    width: 740
    height: 400
    minimumWidth: width
    maximumWidth: width
    minimumHeight: height
    maximumHeight: height
    flags: styleHelper.dialogWindowFlags
    modality: Qt.WindowModal
    title: mainWindow.title

    signal closed
    onVisibleChanged: if (!visible) closed()

    property string staticContactId: fields.contactId.text

    function close() {
        visible = false
    }

    function accept() {
        if (!fields.hasValidRequest)
            return

        userIdentity.contacts.createContactRequest(fields.contactId.text, fields.name.text, yourNameField.text.length > 0 ? yourNameField.text : "Speek User", fields.message.text)
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

        Rectangle {
            color: "transparent"
            width: 150
            height: 160
            Layout.alignment: Qt.AlignCenter
            Image {
                height: 150
                width: 150
                source: "qrc:/icons/speeklogo2.png"
                smooth: true
                antialiasing: true
            }
        }

        Label {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            horizontalAlignment: Qt.AlignHCenter
            wrapMode: Text.Wrap
            //: tells the user to get the Speek ID of their friends to add them as contacts
            text: qsTr("Get the Speek ID of your Friends to add them as contacts. Please, be aware that a request generally takes ~10-20 seconds to arrive.")
            Accessible.role: Accessible.StaticText
            Accessible.name: text
        }
    }

    ContactRequestFields {
        id: fields
        anchors {
            left: parent.left
            right: parent.right
            top: infoArea.bottom
            bottom: buttonRow.top
            margins: 8
            leftMargin: 16
            rightMargin: 16
        }

        Label {
            //: Label for the recommended username (own username) text box in the 'add new contact' window
            text: qsTr("Your Username:")
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            Accessible.role: Accessible.StaticText
            Accessible.name: text
        }

        TextField {
            text: typeof(uiSettings.data.username) !== "undefined" ? uiSettings.data.username : "Speek User"
            id: yourNameField
            Layout.fillWidth: true

            Accessible.role: Accessible.Dialog
            Accessible.name: text
            //: Description of textbox for setting a your nickname for accessibility tech like screen readers
            Accessible.description: qsTr("Field for your nickname")
        }

        Component.onCompleted: {
            if (staticContactId.length > 0) {
                fields.contactId.text = staticContactId
                fields.contactId.readOnly = true
                fields.name.focus = true
            } else {
                fields.contactId.focus = true
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
            onClicked: addContactWindow.close()
            Accessible.role: Accessible.Button
            Accessible.name: text
            //: description for 'Cancel' button accessibility tech like screen readers
            Accessible.description: qsTr("Closes the contact add window")
            Accessible.onPressAction: addContactWindow.close()
        }

        Button {
            //: button label to finish adding a contact/friend
            text: qsTr("Add")
            isDefault: true
            enabled: fields.hasValidRequest
            onClicked: addContactWindow.accept()

            Accessible.role: Accessible.Button
            Accessible.name: text
            //: description for 'Add' button for accessibility tech like screen readres
            Accessible.description: qsTr("Adds the contact to your contact list")
            Accessible.onPressAction: addContactWindow.close()
        }
    }

    Action {
        shortcut: StandardKey.Close
        onTriggered: addContactWindow.close()
    }

    Action {
        shortcut: "Escape"
        onTriggered: addContactWindow.close()
    }
}

