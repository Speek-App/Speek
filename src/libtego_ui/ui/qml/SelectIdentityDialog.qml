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
        listview.model.append(utility.getIdentities())
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
            text: qsTr("Select an Id to start another instance of Speek.Chat with. Or alternatively, add a new one by entering a name into the text input at the bottom.")
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

    RowLayout {
        id: buttonRow
        anchors {
            right: parent.right
            bottom: parent.bottom
            rightMargin: 16
            bottomMargin: 8
        }

        TextArea {
            selectByMouse: true
            id: newIdentityName
            text: ""

            enabled: true
            Layout.minimumWidth: 150
            Layout.maximumHeight: 33

            Accessible.role: Accessible.EditableText
            //: Name of the text input used to add a new identity
            Accessible.name: qsTr("Add new identity text input field")
            //: Description of what the add new identity text input is for accessibility tech like screen readers
            Accessible.description: qsTr("How the new identity should be named")
        }

        Button {
            //: button label to add a new identity
            text: qsTr("Add")
            enabled: newIdentityName.text.length > 0
            onClicked: {
                utility.startNewInstance(newIdentityName.text)

                timer.setTimeout(function(){ load(); }, 1000);
            }

            Accessible.role: Accessible.Button
            Accessible.name: text
            //: description for 'Add' button for accessibility tech like screen readres
            Accessible.description: qsTr("Adds a new identity")
            Accessible.onPressAction: addContactWindow.close()
        }
    }

    Action {
        shortcut: StandardKey.Close
        onTriggered: selectIdentityDialog.close()
    }

    Action {
        shortcut: "Escape"
        onTriggered: selectIdentityDialog.close()
    }
}
