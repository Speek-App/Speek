import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.0
import im.utility 1.0

ApplicationWindow {
    id: contactRequestSelectionDialog
    width: Qt.platform.os == "android" ? undefined : 740
    height: Qt.platform.os == "android" ? undefined : 430
    minimumWidth: width
    maximumWidth: width
    minimumHeight: height
    maximumHeight: height
    flags: Qt.platform.os == "android" ? undefined : styleHelper.dialogWindowFlags
    modality: Qt.platform.os == "android" ? undefined : Qt.WindowModal
    title: mainWindow.title

    Utility {
       id: utility
    }

    color: palette.window

    signal closed
    onVisibleChanged: if (!visible) closed()

    signal contactRequestDialogsChanged

    function close() {
        visible = false
    }

    onContactRequestDialogsChanged: {
        infoArea.listview.model = mainWindow.contactRequestDialogs
    }

    ContactRequestSelectionDialogMain{
        id: infoArea

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: buttonRow.top
            topMargin: 8
            leftMargin: Qt.platform.os === "android" ? 4 : 16
            rightMargin: Qt.platform.os === "android" ? 4 : 16
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
            onClicked: contactRequestSelectionDialog.close()
            Layout.fillWidth: Qt.platform.os === "android" ? true : false
            Component.onCompleted: {if(Qt.platform.os !== "android")contentItem.color = palette.text}
            Accessible.role: Accessible.Button
            Accessible.name: text
            //: description for 'Close' button accessibility tech like screen readers
            Accessible.description: qsTr("Closes the view other identity window")
            Accessible.onPressAction: selectIdentityDialog.close()
        }
    }

    Action {
        shortcut: StandardKey.Close
        onTriggered: contactRequestSelectionDialog.close()
    }

    Action {
        shortcut: "Escape"
        onTriggered: contactRequestSelectionDialog.close()
    }
}
