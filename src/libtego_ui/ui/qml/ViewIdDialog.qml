import QtQuick 2.2
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0

ApplicationWindow {
    id: viewIdDialog_
    width: 740
    height: 290
    minimumWidth: width
    maximumWidth: width
    minimumHeight: height
    maximumHeight: height
    flags: styleHelper.dialogWindowFlags
    modality: Qt.WindowModal
    title: mainWindow.title

    signal closed
    onVisibleChanged: if (!visible) closed()

    function close() {
        visible = false
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
            text: qsTr("Close")
            onClicked: viewIdDialog_.close()
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

