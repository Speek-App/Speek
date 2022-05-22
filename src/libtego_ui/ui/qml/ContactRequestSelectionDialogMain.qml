import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4
import im.utility 1.0

Rectangle{
    id: infoArea
    color: palette.window
    property alias listview: listview
    z: 2

    signal contactRequestDialogsChangedAndroid
    onContactRequestDialogsChangedAndroid: {
        listview.model = mainWindow.contactRequestDialogs
    }

    ColumnLayout {
        anchors.fill: parent

        ListView {
            clip: true
            id: listview
            y: Qt.platform.os === "android" ? 10 : 25
            width: parent.width
            height: Qt.platform.os === "android" ? parent.height - 40 : parent.height - 80
            header: Rectangle{
                color: palette.base
                width: infoArea.width
                height: 40

                RowLayout{
                    width: parent.width
                    height: parent.height
                    Item{
                        width:Qt.platform.os === "android" ? 8 : 20
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
                    Item{
                        width:Qt.platform.os === "android" ? 8 : 20
                    }
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
                        text: qsTr("No contact requests available")
                        Layout.alignment: Qt.AlignCenter
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
                    Item{
                        width:Qt.platform.os === "android" ? 8 : 20
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
                    Item{
                        width:Qt.platform.os === "android" ? 8 : 20
                    }
                }
            }
        }
        Rectangle{
            Layout.fillHeight: true
        }
    }
}
