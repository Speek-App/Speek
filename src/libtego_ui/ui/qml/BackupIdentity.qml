import QtQuick 2.0
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.0
import QtQuick.Dialogs 1.0
import im.utility 1.0
import im.ricochet 1.0
import QtQuick.Controls.Material 2.15

ColumnLayout {
    width: parent.width

    Utility {
           id: utility
        }

    anchors {
        fill: parent
        margins: 8
    }

    RowLayout {
        z: 2
        width: parent.width - 10
        Label {
            text: qsTr("Below you can export your whole user data including all contacts as a zip archive. Please consider the backup like a private key and therefore keep the backup in a safe place. Also don't, under any cirumstances, share it with other people. Remember we will never ask you for your user data.")
            Layout.fillWidth: true
            Accessible.role: Accessible.StaticText
            Accessible.name: text
            wrapMode: Text.WordWrap
        }
    }

    RowLayout {
        Layout.fillWidth: Qt.platform.os === "android" ? true : false
        z: 2
        Button {
            //: Label for button which allows the exporting of the current identity
            text: qsTr("Export Identity")
            Layout.minimumWidth: 200
            Layout.fillWidth: Qt.platform.os === "android" ? true : false
            Component.onCompleted: {if(Qt.platform.os !== "android")contentItem.color = palette.text}
            onClicked: {
                if(Qt.platform.os === "android"){
                    if(!utility.requestPermissionAndroid("android.permission.WRITE_EXTERNAL_STORAGE"))
                        return
                    utility.exportBackupCallback(typeof(uiSettings.data.username) !== "undefined" ? uiSettings.data.username : "Speek_User", function(res) {
                        console.log("done: backup")
                    })
                }
                else{
                    utility.exportBackup(typeof(uiSettings.data.username) !== "undefined" ? uiSettings.data.username : "Speek_User")
                }
            }
            Accessible.role: Accessible.Button
            Accessible.name: text
            //: Description of button which allows the exporting of the current identity for accessibility tech like screen readers
            Accessible.description: qsTr("Create a backup of the current identity")
        }
    }

    RowLayout {
        z: 2
        Button {
            visible: Qt.platform.os !== "android"
            //: Label for button which allows the exporting of the current identity
            text: qsTr("Show data location")
            Layout.minimumWidth: 200
            Component.onCompleted: {if(Qt.platform.os !== "android")contentItem.color = palette.text}
            onClicked: utility.openUserDataLocation()
            Accessible.role: Accessible.Button
            Accessible.name: text
            //: Description of button which allows the opening of the user data folder via the native file explorer
            Accessible.description: qsTr("Shows the user data location")
        }
    }

    Item {
        Layout.fillHeight: true
        Layout.fillWidth: true
    }
}
