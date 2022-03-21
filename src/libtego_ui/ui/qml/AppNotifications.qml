import QtQuick 2.2
import QtQuick.Window 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import QtQuick.Controls.Styles 1.2

ListView {
    clip: true
    id: listview
    spacing: 5
    width: 210
    height: parent.height/2
    visible: model.length > 0

    header: Item{
        width: 5
        height: 8
    }

    delegate: Rectangle{
        width: 200
        height: 60
        color: styleHelper.notificationBackground//"#383838"
        opacity: 0.85
        radius: 5
        ColumnLayout{
            width: parent.width
            spacing: 3
            Item{
                height: 1
            }
            RowLayout{
                Item{
                    width: 5
                    height: 1
                }
                Text{
                    text: "New Contact Request"
                    color: styleHelper.chatIconColorHover
                }
            }
            Item{
                Layout.fillHeight: true
            }
            RowLayout{
                width: parent.width
                Item{
                    Layout.fillWidth: true
                }
                Button {
                    text: qsTr("Dismiss")
                    onClicked: {
                        var object = mainWindow.appNotificationsModel[index];
                        if(mainWindow.appNotificationsModel.indexOf(object) != -1){
                            mainWindow.appNotificationsModel.splice(mainWindow.appNotificationsModel.indexOf(object), 1);
                            mainWindow.appNotifications.model = mainWindow.appNotificationsModel
                        }
                    }

                    Accessible.role: Accessible.Button
                    Accessible.name: text
                    Accessible.onPressAction: {
                        var object = mainWindow.appNotificationsModel[index];
                        if(mainWindow.appNotificationsModel.indexOf(object) != -1){
                            mainWindow.appNotificationsModel.splice(mainWindow.appNotificationsModel.indexOf(object), 1);
                            mainWindow.appNotifications.model = mainWindow.appNotificationsModel
                        }
                    }
                    style: ButtonStyle {
                        background: Rectangle {
                            color: "transparent"
                        }
                        label: Text {
                            renderType: Text.NativeRendering
                            text: control.text
                            color: control.hovered ? styleHelper.chatIconColorHover : styleHelper.chatIconColor
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                         }
                    }
                }
                Item{
                    width: 5
                }
                Button {
                    text: qsTr("View")
                    onClicked: mainWindow.appNotificationsModel[index].visible = true

                    Accessible.role: Accessible.Button
                    Accessible.name: text
                    Accessible.onPressAction: {
                        mainWindow.appNotificationsModel[index].visible = true
                    }
                    style: ButtonStyle {
                        background: Rectangle {
                            color: "transparent"
                        }
                        label: Text {
                            renderType: Text.NativeRendering
                            text: control.text
                            color: control.hovered ? styleHelper.chatIconColorHover : styleHelper.chatIconColor
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                         }
                    }
                }
                Item{
                    width: 5
                }
            }
        }
    }

    Item{
        Layout.fillHeight: true
    }
}
