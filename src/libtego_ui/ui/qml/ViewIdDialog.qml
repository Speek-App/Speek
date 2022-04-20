import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.0
import com.scythestudio.scodes 1.0

ApplicationWindow {
    id: viewIdDialog_
    width: Qt.platform.os == "android" ? undefined : 740
    height: Qt.platform.os == "android" ? undefined : 340
    minimumWidth: Qt.platform.os == "android" ? undefined : width
    maximumWidth: Qt.platform.os == "android" ? undefined : width
    minimumHeight: Qt.platform.os == "android" ? undefined : height
    maximumHeight: Qt.platform.os == "android" ? undefined : height
    flags: Qt.platform.os == "android" ? undefined : styleHelper.dialogWindowFlags
    modality: Qt.platform.os == "android" ? undefined : Qt.WindowModal
    title: mainWindow.title

    property bool addUsernameToQR: true

    signal closed
    onVisibleChanged: if (!visible) closed()

    function close() {
        visible = false
    }

    function generate_qr_code(){
        barcodeGenerator.setFormat("QRCode")
        var str = userIdentity.contactID
        if(addUsernameToQR)
            str += ";"+nameField.text
        console.log(str)
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
            topMargin: Qt.platform.os === "android" ? 45 : 8
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
            /*
            Image {
                height: 150
                width: 150
                source: "qrc:/icons/speeklogo2.png"
                smooth: true
                antialiasing: true
            }*/
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
            text: qsTr("Close")
            onClicked: viewIdDialog_.close()
            Layout.fillWidth: Qt.platform.os === "android" ? true : false
            Component.onCompleted: {if(Qt.platform.os !== "android")contentItem.color = palette.text}
            Accessible.role: Accessible.Button
            Accessible.name: text
            //: description for 'Close' button accessibility tech like screen readers
            Accessible.description: qsTr("Closes the view speek id window")
            Accessible.onPressAction: viewIdDialog_.close()
        }
    }

    Action {
        shortcut: StandardKey.Close
        onTriggered: viewIdDialog_.close()
    }

    Action {
        shortcut: "Escape"
        onTriggered: viewIdDialog_.close()
    }
}

