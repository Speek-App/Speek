import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.0
import QtQuick.Controls.Material 2.15

ApplicationWindow {
    id: addContactWindow
    width: Qt.platform.os == "android" ? undefined : 840
    height: Qt.platform.os == "android" ? undefined : 460
    minimumWidth: 300
    maximumWidth: 1440
    minimumHeight: 300
    maximumHeight: 2000
    flags: Qt.platform.os == "android" ? undefined : styleHelper.dialogWindowFlags
    modality: Qt.platform.os == "android" ? Qt.NonModal : Qt.WindowModal
    title: mainWindow.title

    color: palette.window

    signal closed
    onVisibleChanged: if (!visible) closed()
    onOpacityChanged: closed()

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

    Item{
        width: 50
        height: 50
        visible: Qt.platform.os === "android"
        Button {
            id: qrScanButton
            anchors.centerIn: parent
            hoverEnabled: true

            ToolTip.visible: Qt.platform.os === "android" ? pressed : hovered
            ToolTip.text: qsTr("Add a contact by scanning a QR-Code")

            onClicked: {
                var object = createDialog("qrcode/ScannerPage.qml", { "textInput": fields.contactId.textField, "nameInput": fields.name })
                object.visible = true
            }

            background: Rectangle {
                implicitWidth: 30
                implicitHeight: 30
                color: "transparent"
            }
            contentItem: Text {
                text: "u"
                font.family: iconFont.name
                font.pixelSize: 30
                horizontalAlignment: Qt.AlignLeft
                renderType: Text.QtRendering
                color: {
                    return qrScanButton.hovered ? palette.text : styleHelper.chatIconColor
                }
            }
        }
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
            text: uiMain.isGroupHostMode ? qsTr("Get the Speek ID of your friends to add them to this group.") : qsTr("Get the Speek ID of your Friends to add them as contacts. Please, be aware that a request generally takes ~10-20 seconds to arrive.")
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
            margins: Qt.platform.os === "android" ? 4 : 8
            leftMargin: Qt.platform.os === "android" ? 4 : 16
            rightMargin: Qt.platform.os === "android" ? 4 : 16
        }

        Image{
            visible: Qt.platform.os === "android"
            source: "qrc:/icons/android/settings_android/settings_username.svg"
            Layout.preferredWidth: styleHelper.androidIconSize
            Layout.preferredHeight: styleHelper.androidIconSize
        }

        Label {
            //: Label for the recommended username (own username) text box in the 'add new contact' window
            text: uiMain.isGroupHostMode ? qsTr("Your Group Name:") : qsTr("Your Name:")
            Layout.alignment: Qt.platform.os === "android" ? Qt.AlignVCenter | Qt.AlignLeft : Qt.AlignVCenter | Qt.AlignRight
            Accessible.role: Accessible.StaticText
            Accessible.name: text
        }

        TextField {
            text: typeof(uiSettings.data.username) !== "undefined" ? uiSettings.data.username : "Speek User"
            id: yourNameField
            Layout.fillWidth: true
            //implicitHeight: 24

            validator: RegExpValidator{regExp: /^[a-zA-Z0-9\-_, ]+$/}

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
                if(Qt.platform.os != "android")
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
            leftMargin: Qt.platform.os === "android" ? 16 : undefined
            left: Qt.platform.os === "android" ? parent.left : undefined
        }

        Button {
            //: label for button which dismisses a dialog
            text: qsTr("Cancel")
            width: Qt.platform.os === "android" ? undefined : 100
            height: 50
            onClicked: addContactWindow.close()
            Component.onCompleted: {if(Qt.platform.os !== "android")contentItem.color = palette.text}
            Layout.fillWidth: Qt.platform.os === "android" ? true : false
            Accessible.role: Accessible.Button
            Accessible.name: text
            //: description for 'Cancel' button accessibility tech like screen readers
            Accessible.description: qsTr("Closes the contact add window")
            Accessible.onPressAction: addContactWindow.close()
        }

        Button {
            //: button label to finish adding a contact/friend
            text: qsTr("Add")
            enabled: fields.hasValidRequest
            onClicked: addContactWindow.accept()

            //palette.buttonText seems broken (see https://bugreports.qt.io/browse/QTBUG-79881)
            contentItem: Label {
                text: parent.text
                color: palette.text
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Layout.fillWidth: Qt.platform.os === "android"
            highlighted: Qt.platform.os === "android"

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

