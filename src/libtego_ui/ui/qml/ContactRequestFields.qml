import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.0
import im.ricochet 1.0

GridLayout {
    id: contactFields
    columns: 2

    property bool readOnly
    property ContactIDField contactId: contactIdField
    property TextField name: nameField
    property TextArea message: messageField
    property bool hasValidRequest: contactIdField.acceptableInput && nameField.text.length

    Label {
        //: Label for the contact id text box in the 'add new contact' window
        text: qsTr("ID:")
        Layout.alignment: Qt.platform.os === "android" ? Qt.AlignVCenter | Qt.AlignLeft : Qt.AlignVCenter | Qt.AlignRight
        Accessible.role: Accessible.StaticText
        Accessible.name: text
    }

    ContactIDField {
        id: contactIdField
        Layout.fillWidth: true
        readOnly: contactFields.readOnly
        showCopyButton: contactFields.readOnly
    }

    /*
    Rectangle{visible: !readOnly && Qt.platform.os === "android";width:50;height:16;color:"transparent"}

    Button{
        visible: !readOnly && Qt.platform.os === "android"
        text: qsTr("Scan ID as QR-Code")
        onClicked: {
            var object = createDialog("qrcode/ScannerPage.qml", { "textInput": contactIdField.textField, "nameInput": nameField })
            object.visible = true
        }
    }
*/
    Label {
        //: Label for the contact nickname text box in the 'add new contact' window
        text: qsTr("Name:")
        Layout.alignment: Qt.platform.os === "android" ? Qt.AlignVCenter | Qt.AlignLeft : Qt.AlignVCenter | Qt.AlignRight
        Accessible.role: Accessible.StaticText
        Accessible.name: text
    }

    TextField {
        text: qsTr("Contact Name")
        id: nameField
        Layout.fillWidth: true
        //readOnly: contactFields.readOnly

        validator: RegExpValidator{regExp: /^[a-zA-Z0-9\-_, ]+$/}

        Accessible.role: Accessible.Dialog
        Accessible.name: text
        //: Description of textbox for setting a contact's nickname for accessibility tech like screen readers
        Accessible.description: qsTr("Field for the contact's nickname")
    }

    Label {
        //: Label for the contact greeting message text box in the 'add new contact' window
        text: qsTr("Message:")
        Layout.alignment: Qt.platform.os === "android" ? Qt.AlignVCenter | Qt.AlignLeft : Qt.AlignVCenter | Qt.AlignRight
        Accessible.role: Accessible.StaticText
        Accessible.name: text
    }

    ScrollView {
        Layout.fillHeight: true
        Layout.fillWidth: true

        background: Rectangle { color: palette.base;radius:4;visible:Qt.platform.os !== "android" }
        TextArea {
            id: messageField
            Layout.fillWidth: true
            Layout.fillHeight: true
            textFormat: TextEdit.PlainText
            readOnly: contactFields.readOnly
            Accessible.role: Accessible.Dialog
            Accessible.name: text
            //: Description of textbox for setting a new contact's initial greeting message for accessibility tech like screen readers
            Accessible.description: qsTr("Field for the contact's greeting message")
        }
    }
}
