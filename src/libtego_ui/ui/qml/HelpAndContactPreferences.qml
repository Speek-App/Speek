import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import QtQuick.Dialogs 1.0
import im.utility 1.0
import im.ricochet 1.0

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
            text: qsTr("Please let us know if you are experiencing any issues, bugs or abuse. You can contact us via email (contact@speek.network) or open a github issue (https://github.com/Speek-App/Speek/issues).\n\nAbusive Users\nTo remove and block an abusive user you can right click them and click on \"Remove\". With this action all message from this user are deleted and the offending user isn't able to contact you anymore. You can remove a single received message by right clicking it and clicking \"Remove Message\". Alternatively, by closing this application you can get rid of all messages (sent and received) without removing/blocking a contact.")
            Layout.fillWidth: true
            Accessible.role: Accessible.StaticText
            Accessible.name: text
            wrapMode: Text.WordWrap
        }
    }

    Item {
        Layout.fillHeight: true
        Layout.fillWidth: true
    }
}
