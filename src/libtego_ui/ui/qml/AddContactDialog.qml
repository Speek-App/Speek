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

    function close() {
        visible = false
    }

    AddContactDialogMain{
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

