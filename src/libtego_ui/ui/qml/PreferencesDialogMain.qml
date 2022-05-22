import QtQuick 2.2
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.0
import im.ricochet 1.0
import QtQuick.Controls.Styles 1.4

TabView {
    id: tabs
    anchors.fill: Qt.platform.os === "android" ? undefined : parent
    anchors.margins: Qt.platform.os === "android" ? 0 : 8

    Accessible.role: Accessible.MenuBar
    //: Name of the tab bar for accessibility tech like screen readers
    Accessible.name: qsTr("Menu Tabs")

    style: TabViewStyle {
        frameOverlap: 1
        tab: Rectangle {
            color: styleData.selected ? palette.window : palette.base
            implicitWidth: Qt.platform.os === "android" ? tabs.width/5+1 : Math.max(text.width + 16, 80)
            implicitHeight: Qt.platform.os === "android" ? 50 : 30
            radius: 2
            ColumnLayout{
                anchors.fill: Qt.platform.os !== "android" ? undefined : parent
                anchors.centerIn: Qt.platform.os === "android" ? undefined : parent
                Item {
                    visible: Qt.platform.os === "android" ? true : false
                    width: 1
                    height: 1
                }
                Text {
                    visible: Qt.platform.os === "android" ? true : false
                    renderType: Text.NativeRendering
                    font.family: iconFont.name
                    font.pixelSize: 16
                    font.bold: true
                    text: {
                        switch(styleData.index){
                            case 0: return "l";
                            case 1: return "k";
                            case 2: return "j";
                            case 3: return "m";
                            case 4: return "n";
                            default: return ""
                        }
                    }
                    color: styleHelper.chatIconColor
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    id: text
                    //anchors.centerIn: Qt.platform.os === "android" ? undefined : parent
                    text: styleData.title
                    color: Qt.platform.os === "android" ? styleHelper.chatIconColor : palette.text
                    Layout.alignment: Text.AlignHCenter
                }
            }
            border.color: styleHelper.borderColor2
            border.width: 1
        }
        frame: Rectangle { color: palette.window; border.color: styleHelper.borderColor2; border.width: 1 }
    }

    tabPosition: Qt.platform.os === "android" ? Qt.BottomEdge : Qt.TopEdge

    /* QT will automatically set Accessible.text, also tabs fail to load if
     * you set any accessibility properties */
    Tab {
        //: Title of the general settings tab
        title: qsTr("General")
        source: Qt.resolvedUrl("GeneralPreferences.qml")
    }

    Tab {
        parent: !uiMain.isGroupHostMode ? parent : null
        //: Title of the general settings tab
        title: qsTr("Style")
        source: Qt.resolvedUrl("StylePreferences.qml")
    }

    Tab {
        parent: Qt.platform.os !== "android" ? parent : null
        //: Title of the contacts list tab
        title: qsTr("Contacts")
        source: Qt.resolvedUrl("ContactPreferences.qml")
    }

    Tab {
        //: Title of the tor tab, contains tor settings and logs
        title: qsTr("Tor")
        source: Qt.resolvedUrl("TorPreferences.qml")
    }

    Tab {
        //: Title of the backup tab
        title: qsTr("Backup")
        source: Qt.resolvedUrl("BackupIdentity.qml")
    }

    Tab {
        parent: !uiMain.isGroupHostMode ? parent : null
        //: Title of the about tab, contains license information and speek version
        title: qsTr("About")
        source: Qt.resolvedUrl("AboutPreferences.qml")
    }

    Tab {
        parent: uiMain.appstore_compliant ? parent : null
        //: Title of the about tab, contains help and contact information
        title: qsTr("Help&Contact")
        source: Qt.resolvedUrl("HelpAndContactPreferences.qml")
    }
}
