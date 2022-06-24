import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Popup {
    property string sent_time: "-"
    property string delivered_time: "-"
    property bool is_file_transfer: false
    anchors.centerIn: Overlay.overlay
    modal: true
    focus: true
    dim: true
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

    background: Rectangle {
        color: palette.base
        border.color: palette.base
        radius: 3
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity";
                from: 0.0;
                to: 1.0;
                duration: 500
            }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity";
                from: 1.0
                to: 0.0;
                duration: 300
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        ColumnLayout {
            spacing: 10
            RowLayout{
                Label{
                    text: "E"
                    height: 16
                    width: 22
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 13
                    font.family: iconFont.name
                    color: styleHelper.chatIconColor
                }
                Text{
                    color: palette.text
                    text: qsTr("Sent")
                }
            }
            Text{
                text: sent_time
                color: palette.text
            }
        }
        Item{
            height:10;width:1
        }
        ColumnLayout {
            spacing: 10
            RowLayout{
                Label{
                    text: "E"
                    height: 16
                    width: 22
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 13
                    font.family: iconFont.name
                    color: Qt.darker(palette.highlight, 1.5)
                }
                Text{
                    color: palette.text
                    text: is_file_transfer ? qsTr("Download Finished") : qsTr("Delivered")
                }
            }
            Text{
                text: delivered_time
                color: palette.text
            }
        }
    }
}
