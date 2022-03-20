import QtQuick 2.2
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import im.utility 1.0

ApplicationWindow {
    id: contactRequestSelectionDialog
    width: 740
    height: 430
    minimumWidth: width
    maximumWidth: width
    minimumHeight: height
    maximumHeight: height
    flags: styleHelper.dialogWindowFlags
    modality: Qt.WindowModal
    title: mainWindow.title

    Utility {
       id: utility
    }

    signal closed
    onVisibleChanged: if (!visible) closed()

    signal contactRequestDialogsChanged

    function close() {
        visible = false
        console.log(mainWindow.contactRequestDialogs[0].request)
    }

    onContactRequestDialogsChanged: {
        listview.model = mainWindow.contactRequestDialogs
    }

    ColumnLayout {
        id: infoArea
        z: 2
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            topMargin: 8
            leftMargin: 16
            rightMargin: 16
        }

        ListView {
            clip: true
            id: listview
            y: 25
            width: parent.width
            height: parent.height - 120
            header: Rectangle{
                color: palette.base
                width: infoArea.width
                height: 40

                RowLayout{
                    width: parent.width
                    height: parent.height
                    Rectangle{
                        width:20
                        height:1
                        color:"transparent"
                    }
                    Label{
                        Layout.minimumWidth: (parent.width - 40) / 4
                        height: parent.height
                        verticalAlignment: Qt.AlignVCenter
                        text: qsTr("Name")
                        horizontalAlignment: Qt.AlignLeft
                    }
                    Label{
                        Layout.minimumWidth: (parent.width - 40) / 4
                        height: parent.height
                        verticalAlignment: Qt.AlignVCenter
                        text: qsTr("Message")
                    }
                    Label{
                        Layout.minimumWidth: (parent.width - 40) / 4 * 2
                        height: parent.height
                        verticalAlignment: Qt.AlignVCenter
                        text: qsTr("Speek ID")
                    }
                    Rectangle{
                        width:20
                        height:1
                        color:"transparent"
                    }
                }
            }
            model: mainWindow.contactRequestDialogs
            delegate: Rectangle{
                color: ma.hovered === false ? palette.base : palette.alternateBase
                width: infoArea.width
                height: 40
                MouseArea{
                    id: ma
                    anchors.fill: parent
                    onClicked: {
                        mainWindow.contactRequestDialogs[index].visible = true
                    }
                    hoverEnabled: true
                    property bool hovered: false
                    onEntered: hovered = true
                    onExited: hovered = false
                }
                RowLayout{
                    width: parent.width
                    height: parent.height
                    Rectangle{
                        width:20
                        height:1
                        color:"transparent"
                    }
                    Label{
                        Layout.minimumWidth: (parent.width - 40) / 4
                        Layout.preferredWidth: (parent.width - 40) / 4
                        height: parent.height
                        verticalAlignment: Qt.AlignVCenter
                        text: mainWindow.contactRequestDialogs[index].nameRequest.text
                        horizontalAlignment: Qt.AlignLeft
                        elide: Text.ElideRight
                    }
                    Label{
                        Layout.minimumWidth: (parent.width - 40) / 4
                        Layout.preferredWidth: (parent.width - 40) / 4
                        height: parent.height
                        verticalAlignment: Qt.AlignVCenter
                        text: mainWindow.contactRequestDialogs[index].messageRequest.text.replace(/(\r\n|\n|\r)/gm, " ")
                        elide: Text.ElideMiddle
                    }
                    Label{
                        Layout.minimumWidth: (parent.width - 40) / 4 * 2
                        Layout.preferredWidth: (parent.width - 40) / 4 * 2
                        height: parent.height
                        verticalAlignment: Qt.AlignVCenter
                        text: mainWindow.contactRequestDialogs[index].contactIdRequest.text
                        elide: Text.ElideMiddle
                    }
                    Rectangle{
                        width:20
                        height:1
                        color:"transparent"
                    }
                }
            }
        }
        Rectangle{
            Layout.fillHeight: true
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
            onClicked: contactRequestSelectionDialog.close()
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
