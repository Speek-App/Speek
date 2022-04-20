import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4
import QtQuick.Controls.Styles 1.2
import im.utility 1.0

ApplicationWindow {
    id: window
    width: Qt.platform.os == "android" ? undefined : minimumWidth
    height: Qt.platform.os == "android" ? undefined : minimumHeight
    minimumWidth: Qt.platform.os == "android" ? undefined : 600
    maximumWidth: Qt.platform.os == "android" ? undefined : minimumWidth
    minimumHeight: Qt.platform.os == "android" ? undefined : visibleItem.height + 16
    maximumHeight: Qt.platform.os == "android" ? undefined : minimumHeight

    title: "Speek.Chat"

    color: palette.window

    signal networkReady
    signal closed

    onVisibleChanged: if (!visible) closed()

    Utility {
       id: utility
    }

    property Item visibleItem: configPage.visible ? configPage : pageLoader.item

    function back() {
        if (pageLoader.visible) {
            pageLoader.visible = false
            configPage.visible = true
        } else {
            openBeginning()
        }
    }

    function openBeginning() {
        configPage.visible = false
        configPage.reset()
        pageLoader.sourceComponent = firstPage
        pageLoader.visible = true
    }

    function openConfig() {
        pageLoader.visible = false
        configPage.visible = true
    }

    function openBootstrap() {
        configPage.visible = false
        pageLoader.source = Qt.resolvedUrl("TorBootstrapStatus.qml")
        pageLoader.visible = true
    }

    Loader {
        id: pageLoader
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 8
        }
        sourceComponent: firstPage
    }

    TorConfigurationPage {
        id: configPage
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 8
        }
        visible: false
    }

    StartupStatusPage {
        id: statusPage
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 8
        }
        visible: false

        onHasErrorChanged: {
            if (hasError) {
                if (visibleItem)
                    visibleItem.visible = false
                pageLoader.visible = false
                statusPage.visible = true
                visibleItem = statusPage
            }
        }
    }

    Component {
        id: firstPage
        Rectangle{
            color: "transparent"
            anchors.fill: parent
            Rectangle{
                visible: Qt.platform.os === "android" ? true : false
                width: Math.max(parent.width, parent.height) * 2
                height: Math.max(parent.width, parent.height) * 2
                radius: Math.max(parent.width, parent.height)
                anchors.bottom: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                color: palette.base
            }
        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            Item{
                width:1
                Layout.fillHeight: Qt.platform.os === "android"
            }
            Rectangle{
                visible: !uiMain.appstore_compliant
                width: Qt.platform.os === "android" ? 180 : 150
                height: Qt.platform.os === "android" ? 180 : 150
                radius: 20
                color: Qt.platform.os === "android" ? "transparent" : palette.base
                anchors.horizontalCenter: parent.horizontalCenter
                Image{
                    source: "qrc:/icons/speeklogo2.png"
                    width: Qt.platform.os === "android" ? 180 : 110
                    height: Qt.platform.os === "android" ? 180 : 110
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item{
                width: 1
                height: Qt.platform.os === "android" ? parent.height*0.17 : 0
            }
            TextArea {
                visible: uiMain.appstore_compliant
                Layout.fillWidth: true
                Layout.fillHeight: true
                width: parent.width

                readOnly: true
                text: uiMain.eulaText
                textFormat: TextEdit.PlainText
                wrapMode: TextEdit.Wrap

                Accessible.description: qsTr("The EULA of Speek")
                Accessible.name: qsTr("EULA")
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                //: Label for button to connect to the Tor network
                text: uiMain.appstore_compliant ? qsTr("I have read and agree to the above EULA and Launch Speek!") : qsTr("Launch Speek! with default settings")
                //isDefault: true
                onClicked: {
                    // Reset to defaults and proceed to bootstrap page
                    configPage.reset()
                    configPage.save()
                    if(uiMain.appstore_compliant)
                        uiSettings.write("eulaAccepted", "true")
                    if(Qt.platform.os === "android"){
                        utility.android_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS()
                    }
                }
                Component.onCompleted: {if(Qt.platform.os !== "android")contentItem.color = palette.text}
                Accessible.role: Accessible.Button
                Accessible.name: text
                Accessible.onPressAction: {
                    configPage.reset()
                    configPage.save()
                    uiSettings.write("eulaAccepted", "true")
                }
                highlighted: Qt.platform.os === "android"
            }
            Item{
                width:1
                Layout.fillHeight: Qt.platform.os === "android"
            }
            Item{
                width: 1
                height: Qt.platform.os === "android" ? parent.height*0.05 : 0
            }

            Button {
                id: advancedNetworkConfiguration
                visible: !uiMain.appstore_compliant
                anchors.horizontalCenter: parent.horizontalCenter
                //: Label for button to configure the Tor daemon beore connecting to the Tor network
                text: qsTr("Advanced Network Configuration")
                onClicked: window.openConfig()

                Accessible.role: Accessible.Button
                Accessible.name: text
                Accessible.onPressAction: {
                    window.openConfig()
                }

                background: Rectangle {
                    color: "transparent"
                }
                contentItem: Text {
                    renderType: Text.NativeRendering
                    text: advancedNetworkConfiguration.text
                    color: advancedNetworkConfiguration.hovered ? styleHelper.chatIconColorHover : styleHelper.chatIconColor
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
            }
            Item{
                width:1
                height: Qt.platform.os === "android" ? 10 : 0
            }
        }
        }
    }

    Action {
        shortcut: StandardKey.Close
        onTriggered: window.close()
    }
}
