import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.0
import com.scythestudio.scodes 1.0

ApplicationWindow {
    id: viewIdDialog_
    width: 740
    height: 500
    minimumWidth: width
    maximumWidth: width
    minimumHeight: height
    maximumHeight: height
    flags: Qt.platform.os == "android" ? undefined : styleHelper.dialogWindowFlags
    modality: Qt.platform.os == "android" ? undefined : Qt.WindowModal
    title: mainWindow.title

    signal closed
    onVisibleChanged: if (!visible) closed()

    function close() {
        visible = false
    }

    ViewIdDialogMain{
        anchors.fill: parent
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

