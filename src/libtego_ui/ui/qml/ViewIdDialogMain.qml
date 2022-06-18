import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.0
import com.scythestudio.scodes 1.0

Rectangle {
    property bool addUsernameToQR: true

    function generate_qr_code(){
        barcodeGenerator.setFormat("QRCode")
        var str = userIdentity.contactID
        if(addUsernameToQR && nameField.text.length > 0)
            str += ";"+nameField.text
        barcodeGenerator.generate(str)
    }

    Component.onCompleted: {
        barcodeGenerator.setFormat("QRCode")
        generate_qr_code()
    }

    color: palette.window

    SBarcodeGenerator {
        id: barcodeGenerator

        onGenerationFinished: {
            if (error == "") {
                qrcode.source = ""
                qrcode.source = "file:///" + barcodeGenerator.filePath
            } else {

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
            topMargin: Qt.platform.os === "android" ? 45 : Qt.platform.os === "osx" ? 20 : 8
            leftMargin: 16
            rightMargin: 16
        }

        Rectangle {
            color: "transparent"
            width: 200
            height: 210
            Layout.alignment: Qt.AlignCenter
            Image{
                id: qrcode
                height: 200
                width: 200
                sourceSize.width: 200
                sourceSize.height: 200
                cache: false
            }
        }

        Label {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            horizontalAlignment: Qt.AlignHCenter
            wrapMode: Text.Wrap
            //: tells the user the purpose of their Speek ID, which is basically a username
            text: qsTr("Share your Speek ID to allow connection requests")
            Accessible.role: Accessible.StaticText
            Accessible.name: text
        }

        ContactIDField {
            id: localId
            Layout.fillWidth: true
            readOnly: true
            text: userIdentity.contactID
            horizontalAlignment: Qt.AlignLeft
        }

        Item{
            width:1
            height: 20
        }

        SettingsSwitch{
            //: Text description of an option to add the username to the qr-code
            text: qsTr("Add username to QR-Code")
            position: addUsernameToQR
            triggered: function(checked){
                addUsernameToQR = checked
                generate_qr_code()
            }
        }

        Label {
            text: qsTr("Username:")
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            Accessible.role: Accessible.StaticText
            Accessible.name: text
        }

        TextField {
            text: typeof(uiSettings.data.username) !== "undefined" ? uiSettings.data.username : ""
            id: nameField
            Layout.fillWidth: true
            onTextChanged: generate_qr_code()

            validator: RegExpValidator{regExp: /^[a-zA-Z0-9\-_, ]+$/}

            Accessible.role: Accessible.Dialog
            Accessible.name: text
            Accessible.description: qsTr("Field for your nickname")
        }
    }
}
