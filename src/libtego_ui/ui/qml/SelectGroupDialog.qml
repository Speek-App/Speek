import QtQuick 2.2
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import im.utility 1.0

ApplicationWindow {
    id: selectGroupDialog
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

    Timer {
        id: timer
        function setTimeout(cb, delayTime) {
            timer.interval = delayTime;
            timer.repeat = false;
            timer.triggered.connect(cb);
            timer.triggered.connect(function release () {
                timer.triggered.disconnect(cb); // This is important
                timer.triggered.disconnect(release); // This is important as well
            });
            timer.start();
        }
    }

    signal closed
    onVisibleChanged: if (!visible) closed()

    function close() {
        visible = false
    }

    function load(){
        for (var i=listview.model.count-1; i>0; i--)
        {
            listview.model.remove(i);
        }
        listview.model.append(utility.getIdentities("/speek-group"))
    }

    Component.onCompleted: {
        load()
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
            text: qsTr("Select a group to launch. Or alternatively, add a new group by clicking on \"Add New Group\".")
            Accessible.role: Accessible.StaticText
            Accessible.name: text
        }
        ListView {
            clip: true
            id: listview
            y: 65
            width: parent.width
            height: parent.height - 120
            model: ListModel {
                ListElement {
                    name: "Name"
                    contacts: "Members"
                    created: "Created"
                }
            }
            footer: Rectangle{
                color: palette.base
                width: infoArea.width
                height: 40
                visible: listview.model.length === 0

                RowLayout{
                    width: parent.width
                    height: parent.height
                    Label{
                        height: parent.height
                        text: qsTr("No groups created")
                        Layout.alignment: Qt.AlignCenter
                    }
                }
            }
            delegate: Rectangle{
                color: ma.hovered === false ? palette.base : palette.alternateBase
                width: infoArea.width
                height: 40
                MouseArea{
                    id: ma
                    anchors.fill: parent
                    onClicked: {
                        if(index !== 0){
                            utility.startGroup(model.name)
                        }
                    }
                    hoverEnabled: index !== 0 ? true : false
                    property bool hovered: false
                    onEntered: hovered = true
                    onExited: hovered = false
                }
                RowLayout{
                    width: parent.width
                    height: parent.height
                    Item{
                        width:20
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
                        text: typeof(model.created) == "undefined" ? "" : model.created
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
            //: button label to add a new identity
            text: qsTr("Add New Group")
            onClicked: {
                var object = createDialog("CreateNewGroupDialog.qml", { }, mainWindow)
                object.visible = true
                //utility.startNewInstance(newIdentityName.text)

                //timer.setTimeout(function(){ load(); }, 1000);
            }

            Accessible.role: Accessible.Button
            Accessible.name: text
            //: description for 'Add' button for accessibility tech like screen readres
            Accessible.description: qsTr("Adds a new identity")
            Accessible.onPressAction: addContactWindow.close()
        }

        Button {
            //: label for button which dismisses a dialog
            text: qsTr("Close")
            onClicked: selectGroupDialog.close()
            Accessible.role: Accessible.Button
            Accessible.name: text
            //: description for 'Close' button accessibility tech like screen readers
            Accessible.description: qsTr("Closes the view other identity window")
            Accessible.onPressAction: selectGroupDialog.close()
        }
    }

    Action {
        shortcut: StandardKey.Close
        onTriggered: selectGroupDialog.close()
    }

    Action {
        shortcut: "Escape"
        onTriggered: selectGroupDialog.close()
    }
}
