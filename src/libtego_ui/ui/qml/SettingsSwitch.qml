import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

RowLayout{
    id: settingsSwitch
    property string text: ""
    property var triggered: function(checked){}
    property int position: 0
    property string switchIcon: ""
    spacing: 0

    RowLayout{
        visible: Qt.platform.os === "android"
        Layout.maximumWidth: Qt.platform.os === "android" ? 1500 : 400

        Image{
            visible: switchIcon !== ""
            source: switchIcon
            Layout.preferredWidth: styleHelper.androidIconSize
            Layout.preferredHeight: styleHelper.androidIconSize
        }
        Item{width:2;visible: switchIcon !== ""}
        Label {
            text: settingsSwitch.text
            Accessible.role: Accessible.StaticText
            Accessible.name: text
            Layout.fillWidth: true
        }
        Switch{
            checked: settingsSwitch.position
            onCheckedChanged: settingsSwitch.triggered(checked)

            Accessible.role: Accessible.CheckBox
            Accessible.name: text
            Accessible.onPressAction: settingsSwitch.triggered(checked)
        }
    }
    CheckBox {
        visible: Qt.platform.os !== "android"
        text: settingsSwitch.text
        checked: settingsSwitch.position
        onCheckedChanged: settingsSwitch.triggered(checked)

        Accessible.role: Accessible.CheckBox
        Accessible.name: text
        Accessible.onPressAction: settingsSwitch.triggered(checked)
    }
}
