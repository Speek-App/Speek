import QtQuick 2.0
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.0
import QtQuick.Window 2.0
import Qt.labs.platform 1.1
import QtQuick.Controls.Material 2.15
import im.ricochet 1.0
import "ContactWindow.js" as ContactWindow

// Root non-graphical object providing window management and other logic.
QtObject {
    id: root
    property bool showMainWindow: false
    Material.theme: styleHelper.darkMode ? Material.Dark : Material.Light

    property MainWindow mainWindow: MainWindow {
        //onVisibleChanged: if (!visible) Qt.quit()
    }

    function addtoStackView(component, properties) {
        if (typeof(component) === "string")
            component = Qt.createComponent(component)
        if (component.status !== Component.Ready)
            console.log("addtoStackView:", component.errorString())
        var object = component.createObject(mainWindow.stack, (properties !== undefined) ? properties : { })
        if (!object)
            console.log("addtoStackView:", component.errorString())
        mainWindow.stack.push(object)
        return object
    }

    function createDialog(component, properties, parent) {
        if (typeof(component) === "string")
            component = Qt.createComponent(component)
        if (component.status !== Component.Ready)
            console.log("openDialog:", component.errorString())
        var object = component.createObject(parent ? parent : null, (properties !== undefined) ? properties : { })
        if (!object)
            console.log("openDialog:", component.errorString())
        object.closed.connect(function() {
            object.destroy();
        })
        return object
    }

    function createDialogRequest(component, properties, parent) {
        if (typeof(component) === "string")
            component = Qt.createComponent(component)
        if (component.status !== Component.Ready)
            console.log("openDialog:", component.errorString())
        var object = component.createObject(parent ? parent : null, (properties !== undefined) ? properties : { })
        if (!object)
            console.log("openDialog:", component.errorString())
        object.closed.connect(function() {
            mainWindow.contactRequestDialogs.splice(mainWindow.contactRequestDialogs.indexOf(object), 1);

            if(mainWindow.appNotificationsModel.indexOf(object) != -1){
                mainWindow.appNotificationsModel.splice(mainWindow.appNotificationsModel.indexOf(object), 1);
                mainWindow.appNotifications.model = mainWindow.appNotificationsModel
            }

            object.destroy();

            mainWindow.contactRequestDialogsLength = mainWindow.contactRequestDialogs.length;
            if(typeof(mainWindow.contactRequestSelectionDialog) != "undefined" && mainWindow.contactRequestSelectionDialog != null)
                mainWindow.contactRequestSelectionDialog.contactRequestDialogsChanged();
            if(Qt.platform.os === "android"){
                if(mainWindow.stack.currentItem.contactRequestDialogsChangedAndroid != "undefined" && mainWindow.stack.currentItem.contactRequestDialogsChangedAndroid != null)
                    mainWindow.stack.currentItem.contactRequestDialogsChangedAndroid()
            }
        })
        return object
    }

    property QtObject preferencesDialog
    function openPreferences(page, properties) {
        if (preferencesDialog == null) {
            preferencesDialog = createDialog("PreferencesDialog.qml",
                {
                    'initialPage': page,
                    'initialPageProperties': properties
                }
            )
            preferencesDialog.closed.connect(function() { preferencesDialog = null })
        }

        preferencesDialog.visible = true
        preferencesDialog.raise()
        preferencesDialog.requestActivate()
    }

    function hexToBase64(hexstring) {
        return bytesArrToBase64(hexToBytes(hexstring))
    }

    function bytesArrToBase64(arr) {
        const abc = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        const bin = n => n.toString(2).padStart(8,0);
        const l = arr.length
        let result = '';

        for(let i=0; i<=(l-1)/3; i++) {
            let c1 = i*3+1>=l;
            let c2 = i*3+2>=l;
            let chunk = bin(arr[3*i]) + bin(c1? 0:arr[3*i+1]) + bin(c2? 0:arr[3*i+2]);
            let r = chunk.match(/.{1,6}/g).map((x,j)=> j==3&&c2 ? '=' :(j==2&&c1 ? '=':abc[+('0b'+x)]));
            result += r.join('');
        }

        return result;
    }

    function hexToBytes(hexString) {
        return hexString.match(/.{1,2}/g).map(x=> +('0x'+x));
    }

    property QtObject audioNotifications: audioNotificationLoader.item

    Component.onCompleted: {
        ContactWindow.createWindow = function(user) {
            var re = createDialog("ChatWindow.qml", { 'contact': user }, root.mainWindow)
            re.x = mainWindow.x + mainWindow.width + 10
            re.y = mainWindow.y + (mainWindow.height / 2) - (re.height / 2)

            var screens = uiMain.screens
            if ((mainWindow.Screen !== undefined) && (mainWindow.Screen.name in screens)) {
                var currentScreen = screens[mainWindow.Screen.name]
                var offsetX = currentScreen.left
                var offsetY = currentScreen.top
                re.x = re.x - offsetX + re.width <= currentScreen.width ? re.x : mainWindow.x - re.width - 10
                re.y = re.y - offsetY + re.height <= currentScreen.height ? re.y : currentScreen.height + offsetY - re.height - 10
            }

            re.visible = true
            return re
        }

        if (torInstance.configurationNeeded) {
            var object = createDialog("NetworkSetupWizard.qml")
            object.show()
            object.networkReady.connect(function() {
                mainWindow.visible = true
                object.visible = false
            })

        } else {
            mainWindow.visible = true
        }
    }

    property list<QtObject> data: [
        Connections {
            target: userIdentity
            function onRequestAdded(request) {
                if(mainWindow.contactRequestDialogs.length > 300){
                    return;
                }
                var object = createDialogRequest("ContactRequestDialog.qml", { 'request': request })
                mainWindow.contactRequestDialogs.push(object)
                mainWindow.contactRequestDialogsLength = mainWindow.contactRequestDialogs.length

                if(request.message.length > 0 && mainWindow.appNotificationsModel.length <= 3){
                    mainWindow.appNotificationsModel.push(object)
                    mainWindow.appNotifications.model = mainWindow.appNotificationsModel
                }

                if(!mainWindow.visible && uiSettings.data.showNotificationSystemtray){
                    mainWindow.systray.showMessage(qsTr("New Contact Request"), ("You just received a new contact request"),SystemTrayIcon.Information, 3000)
                }
            }
        },

        Connections {
            target: torInstance
            function onConfigurationNeededChanged() {
                if (torInstance.configurationNeeded) {
                    var object = createDialog("NetworkSetupWizard.qml", { 'modality': Qt.ApplicationModal }, mainWindow)
                    object.networkReady.connect(function() { object.visible = false })
                    object.visible = true
                }
            }
        },

        Connections {
            target: Qt.application
            function onStateChanged() {
                if(Qt.platform.os === "android"){
                    if(Qt.application.state === Qt.ApplicationActive){
                        notificationClient.clearNotifications()
                    }
                    else if(Qt.application.state !== Qt.ApplicationInactive){
                        notificationClient.newAndroidNotification(qsTr("Background Task"), qsTr("Speek is now running in background"))
                    }
                }
            }
        },

        Settings {
            id: uiSettings
            path: "ui"
        },

        SystemPalette {
            id: palette
        },

        FontLoader {
            id: iconFont
            source: "qrc:/icons/speek-icons.ttf"
        },

        FontLoader {
            id: notoFont
            source: "qrc:/fonts/NotoSans-Regular.ttf"
        },

        FontLoader {
            id: notoBoldFont
            source: "qrc:/fonts/NotoSans-Bold.ttf"
        },

        Item {
            id: styleHelper
            visible: false
            Label { id: fakeLabel }
            Label { id: fakeLabelSized; font.pointSize: styleHelper.pointSize > 0 ? styleHelper.pointSize : 1 }

            property int androidIconSize: 26
            property int defaultPointSize: (Qt.platform.os === "windows") ? 10 : (Qt.platform.os === "osx")  || (Qt.platform.os === "android") ? 14 : 12
            property int defaultPixelSize: {
                if(Qt.platform.os === "windows")
                    return 13
                else if(Qt.platform.os === "osx")
                    return 13
                else if(Qt.platform.os === "android")
                    return 13
                else
                    return 13
            }
            property int pointSize: defaultPointSize * uiSettings.read("fontSizeMultiplier", 1)
            property int pixelSize: defaultPixelSize * uiSettings.read("fontSizeMultiplier", 1)
            property int textHeight: fakeLabelSized.height
            property int dialogWindowFlags: Qt.Dialog | Qt.WindowSystemMenuHint | Qt.WindowTitleHint | Qt.WindowCloseButtonHint
            property string fontFamily: "Noto Sans"
            property bool darkMode: uiMain ? uiMain.themeColor.darkMode == "true" ? true : false : false
            property bool isGroupHostMode : uiMain ? uiMain.isGroupHostMode : false
            property var borderColor: uiMain ? uiMain.themeColor.borderColor : "#ffffff"
            property var chatIconColor: uiMain ? uiMain.themeColor.chatIconColor : "#ffffff"
            property var borderColor2: uiMain ? uiMain.themeColor.borderColor2 : "#ffffff"
            property var emojiPickerBackground: uiMain ? uiMain.themeColor.emojiPickerBackground : "#ffffff"
            property var outgoingMessageColor: uiMain ? uiMain.themeColor.outgoingMessageColor : "#ffffff"
            property var incomingMessageColor: uiMain ? uiMain.themeColor.incomingMessageColor : "#ffffff"
            property var chatIconColorHover: uiMain ? uiMain.themeColor.chatIconColorHover : "#ffffff"
            property var unreadCountBadge: uiMain ? uiMain.themeColor.unreadCountBadge : "#ffffff"
            property var scrollBar: uiMain ? uiMain.themeColor.scrollBar : "#ffffff"
            property var searchBoxText: uiMain ? uiMain.themeColor.searchBoxText : "#ffffff"
            property var messageBoxText: uiMain ? uiMain.themeColor.messageBoxText : "#ffffff"
            property var chatBoxBorderColor: uiMain ? uiMain.themeColor.chatBoxBorderColor : "#ffffff"
            property var chatBoxBorderColorLeft: uiMain ? uiMain.themeColor.chatBoxBorderColorLeft : "#ffffff"
            property var notificationBackground: uiMain ? uiMain.themeColor.notificationBackground : "#ffffff"
            property var contactListHover: uiMain ? uiMain.themeColor.contactListHover : "#ffffff"
            property var textColor: uiMain ? palette.text : "#ffffff"
        },

        Loader {
            id: audioNotificationLoader
            active: uiSettings.data.playAudioNotification || false
            source: "AudioNotifications.qml"
        }
    ]
}
