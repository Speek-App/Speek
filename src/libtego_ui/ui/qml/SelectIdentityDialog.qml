import QtQuick 2.2
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import im.utility 1.0

ApplicationWindow {
    id: selectIdentityDialog
    width: 740
    height: 400
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

    function close() {
        visible = false
    }

    Component.onCompleted: {
        listview.model.append(utility.getIdentities())
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

        Label {
            id: label1
            Layout.columnSpan: 2
            Layout.fillWidth: true
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignTop
            wrapMode: Text.Wrap
            text: qsTr("Select an Id to start onother instance of Speek with")
            Accessible.role: Accessible.StaticText
            Accessible.name: text
        }
        ListView {
            id: listview
            y: 45
            width: parent.width
            height: parent.height - 50
            model: ListModel {
                ListElement {
                    name: "Name"
                    contacts: "Contacts"
                    created: "Created"
                }
            }
            delegate: Rectangle{
                color: ma.hovered === false ? palette.base : palette.alternateBase
                width: parent.width
                height: 40
                MouseArea{
                    id: ma
                    anchors.fill: parent
                    onClicked: {
                        console.log(model.name)
                        console.log(model.sid)
                        if(model.sid !== "Contacts")
                            utility.startNewInstance(model.name)
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
                        Layout.minimumWidth: parent.width / 4
                        height: parent.height
                        verticalAlignment: Qt.AlignVCenter
                        text: model.name
                        horizontalAlignment: Qt.AlignLeft
                    }
                    Label{
                        Layout.minimumWidth: parent.width / 4
                        height: parent.height
                        verticalAlignment: Qt.AlignVCenter
                        text: model.contacts
                    }
                    Label{
                        Layout.minimumWidth: parent.width / 4 * 2
                        height: parent.height
                        verticalAlignment: Qt.AlignVCenter
                        text: model.created
                    }
                }
            }
        }
        Rectangle{
            Layout.fillHeight: true
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
