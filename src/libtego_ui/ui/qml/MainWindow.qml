import QtQuick 2.2
import QtQuick.Window 2.0
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.0
import QtQuick.Controls.Styles 1.4
import im.ricochet 1.0
import Qt.labs.platform 1.1
import im.utility 1.0
import "ContactWindow.js" as ContactWindow

ApplicationWindow {
    id: window
    title: !styleHelper.isGroupHostMode ? "Speek.Chat" : "Speek Group Host"
    visibility: Window.AutomaticVisibility

    property alias searchUserText: toolBar.searchUserText
    property alias systray: systray
    property var contactRequestDialogs: []
    property var contactRequestDialogsLength: 0
    property alias contactRequestSelectionDialog: toolBar.contactRequestSelectionDialog
    property alias drawer: drawer
    property var appNotificationsModel: []
    property alias appNotifications: appNotifications
    property alias stack: stack

    width: !styleHelper.isGroupHostMode ? 1000 : 500
    height: 600
    minimumHeight: 400
    minimumWidth: uiSettings.data.combinedChatWindow && !styleHelper.isGroupHostMode ? 880 : 480

    onMinimumWidthChanged: width = Math.max(width, minimumWidth)

    onVisibilityChanged: {
        if(visibility == 3 && uiSettings.data.minimizeToSystemtray){
            this.visible = false;
        }
    }

    onClosing: {
        Qt.quit()
    }

    Utility {
       id: utility
    }

    Drawer {
        id: drawer
        background: Rectangle{
            color: palette.base
        }

        width: {
            return Math.min(window.width, window.height) / 3 * 2
        }
        Overlay.modal: Rectangle {
            color: Qt.hsla(palette.window.hslHue, palette.window.hslSaturation, palette.window.hslLightness, 0.6)
        }
        height: window.height

        ListView {
            id: drawerListView
            focus: true
            currentIndex: -1
            anchors.fill: parent
            header: Item{width:1;height:20}

            delegate: Button {
                background: Rectangle{
                    color: down ? styleHelper.contactListHover : "transparent"
                }
                contentItem: null
                width: parent.width
                height: 60

                onClicked: {
                    drawer.close()
                    model.triggered()
                }

                RowLayout{
                    anchors.fill: parent
                    spacing: 8
                    Item{height:10;width:10}
                    Image{
                        source: model.img
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                    }
                    Text{
                        text: model.text + (model.showRequests === true && mainWindow.contactRequestDialogsLength > 0 ? " (" + mainWindow.contactRequestDialogsLength + ")" : "")
                        color: styleHelper.chatIconColor
                    }
                    Item{height:10;Layout.fillWidth: true}
                    Text{
                        text: "t"
                        font.pixelSize: 14
                        color: styleHelper.chatIconColor
                        font.family: iconFont.name
                    }
                    Item{height:10;width:10}
                }
            }

            model: ListModel {
                ListElement {
                    //: Context menu entry to open the chat screen in a separate window
                    text: qsTr("Add Contact")
                    showRequests: false
                    triggered: function(){
                        var object = addtoStackView("AddContactDialogMain.qml", { })
                        object.android_finished.connect(function() {
                            back()
                        })
                    }
                    img: "qrc:/icons/android/add_contact.svg"
                }
                ListElement {
                    //: Context menu entry to open a window showing the selected contact's details
                    text: qsTr("View Speek ID")
                    showRequests: false
                    triggered: function(){
                        var object = addtoStackView("ViewIdDialogMain.qml", { })
                    }
                    img: "qrc:/icons/android/view_id.svg"
                }
                ListElement {
                    //: Context menu entry to open the dialog to view all received contact requests
                    text: qsTr("View Contact Requests")
                    showRequests: true
                    triggered: function(){
                        var object = addtoStackView("ContactRequestSelectionDialogMain.qml", { "id": "contactRequestSelectionDialogMain" })
                    }
                    img: "qrc:/icons/android/incoming_contact_requests.svg"
                }
                ListElement {
                    //: Context menu entry to open the settings dialog
                    text: qsTr("Settings")
                    showRequests: false
                    triggered: function(){
                        var object = addtoStackView("PreferencesDialogMain.qml", { })
                    }
                    img: "qrc:/icons/android/settings.svg"
                }
                ListElement {
                    //: Context menu entry to close the speek app
                    text: qsTr("Close Speek!")
                    showRequests: false
                    triggered: function(){window.close()}
                    img: "qrc:/icons/android/close.svg"
                }
            }

            ScrollIndicator.vertical: ScrollIndicator { }
        }
    }

    SystemTrayIcon {
        id: systray
        visible: uiSettings.data.minimizeToSystemtray
        icon.source: styleHelper.isGroupHostMode ? "qrc:/icons/speek-group.png" : "qrc:/icons/speek.png"

        onActivated: {
            window.show()
            window.raise()
            window.requestActivate()
        }

        menu: Menu {
            MenuItem {
                text: qsTr("Quit")
                onTriggered: Qt.quit()
            }
        }
    }

    // OS X Menu
    Loader {
        active: Qt.platform.os == 'osx'
        sourceComponent: MenuBar {
            Menu {
                title: "Speek.Chat"
                MenuItem {
                    text: qsTranslate("QCocoaMenuItem", "Preference")
                    onTriggered: toolBar.preferences.trigger()
                }
            }
        }
    }

    Connections {
        target: userIdentity.contacts
        function onUnreadCountChanged(user, unreadCount) {
            if (unreadCount > 0) {
                if (audioNotifications !== null)
                    audioNotifications.message.play()
                var w = window
                if (!uiSettings.data.combinedChatWindow || ContactWindow.windowExists(user))
                    w = ContactWindow.getWindow(user)
                // On OS X, avoid bouncing the dock icon forever
                if(Qt.platform.os !== "android")
                    w.alert(Qt.platform.os == "osx" ? 1000 : 0)
                if(!window.visible && uiSettings.data.showNotificationSystemtray && Qt.platform.os !== "android"){
                    var systrayMessage = qsTr("You just received a new message from %1").arg(user.nickname)
                    systray.showMessage(qsTr("New Message"), systrayMessage,SystemTrayIcon.Information, 3000)
                }
                else if(Qt.application.state !== Qt.ApplicationActive && uiSettings.data.showNotificationAndroid && Qt.platform.os === "android"){
                    var number_unread_user_messages = userIdentity.contacts.count_contacts_with_unread_message();
                    var androidMessage;
                    if(number_unread_user_messages <= 1)
                        androidMessage = qsTr("New message from %1").arg(user.nickname)
                    else
                        androidMessage = qsTr("New message from %1 and %2 other contact/s").arg(user.nickname).arg(String(number_unread_user_messages-1))

                    notificationClient.newAndroidNotification(qsTr("New Message"), androidMessage)
                }
            }
        }
        function onContactStatusChanged(user, status) {
            if (status === ContactUser.Online && audioNotifications !== null) {
                audioNotifications.contactOnline.play()
            }
        }
    }

    AppNotifications{
        id: appNotifications
        visible: Qt.platform.os !== "android" && model.length > 0
        anchors.right: parent.right
        anchors.top: parent.top
        z: 99
        model: appNotificationsModel
    }

    color: palette.window

    StackView {
        id: stack
        initialItem: Qt.platform.os === "android" ? leftColumn : undefined
        anchors.fill: parent
        visible: Qt.platform.os === "android"

        popEnter: Transition {
                // slide_in_left
                NumberAnimation { property: "x"; from: (stack.mirrored ? -1 : 1) *  -stack.width; to: 0; duration: 1000; easing.type: Easing.OutCubic }
            }

            popExit: Transition {
                // slide_out_right
                NumberAnimation { property: "x"; from: 0; to: (stack.mirrored ? -1 : 1) * stack.width; duration: 1000; easing.type: Easing.OutCubic }
            }

            pushEnter: Transition {
                // slide_in_right
                NumberAnimation { property: "x"; from: (stack.mirrored ? -1 : 1) * stack.width; to: 0; duration: 1000; easing.type: Easing.OutCubic }
            }

            pushExit: Transition {
                // slide_out_left
                NumberAnimation { property: "x"; from: 0; to: (stack.mirrored ? -1 : 1) * -stack.width; duration: 1000; easing.type: Easing.OutCubic }
            }

            replaceEnter: Transition {
                // slide_in_right
                NumberAnimation { property: "x"; from: (stack.mirrored ? -1 : 1) * stack.width; to: 0; duration: 1000; easing.type: Easing.OutCubic }
            }

            replaceExit: Transition {
                // slide_out_left
                NumberAnimation { property: "x"; from: 0; to: (stack.mirrored ? -1 : 1) * -stack.width; duration: 1000; easing.type: Easing.OutCubic }
            }
    }

    RowLayout {
        visible: Qt.platform.os !== "android"
        anchors.fill: parent
        spacing: 0
        Rectangle{
            id: leftColumn
            Layout.preferredWidth: combinedChatView.visible && Qt.platform.os !== "android" ? 220 : 0
            Layout.fillWidth: !combinedChatView.visible
            Layout.fillHeight: true
            ColumnLayout {
                spacing: 0
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: torOnline.visible ? torOnline.top : parent.bottom

                MainToolBar {
                    id: toolBar
                    // Needed to allow bubble to appear over contact list
                    z: 3
    
                    Accessible.role: Accessible.ToolBar
                    //: Name of the main toolbar for accessibility tech like screen readers
                    Accessible.name: qsTr("Main Toolbar")
                    //: Description of the main toolbar for accessibility tech like screen readers
                    Accessible.description: qsTr("Toolbar with connection status, add contact button, and preferences button")
                }

                Item {
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    ContactList {
                        id: contactList
                        anchors.fill: parent
                        opacity: offlineLoader.item !== null ? (1 - offlineLoader.item.opacity) : 1
    
                        onContactActivated: {
                            if (!uiSettings.data.combinedChatWindow) {
                                actions.openWindow()
                            }
                        }
    
                        Accessible.role: Accessible.Pane
                        //: Name of the pane holding the user's contacts for accessibility tech like screen readers
                        Accessible.name: qsTr("Contact pane")
                    }

                    Loader {
                        id: offlineLoader
                        active: torControl.torStatus !== TorControl.TorReady
                        anchors.fill: parent
                        source: Qt.resolvedUrl("OfflineStateItem.qml")
                    }
                }


            }

            Rectangle{
                id: torOnline
                visible: Qt.platform.os === "android" && !toolBar.torstatewidget.visible
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                height:30
                color: palette.window
                Layout.alignment: Qt.AlignRight
                RowLayout{
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        id: connectedIndicator
                        color:styleHelper.chatIconColor
                        text: qsTr("Tor circuit established")
                    }
                    Image{
                        width: 20
                        height: 20
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                        source: "qrc:/icons/android/tor_logo.svg"
                        clip: true
                        fillMode: Image.PreserveAspectFit
                    }
                    Item{height:1;width:2}
                }
            }

            MouseArea {
                  enabled: combinedChatView.visible
                  id: mouseAreaRight
                  cursorShape: Qt.SizeHorCursor

                  property int oldMouseX
                  anchors.right: parent.right
                  anchors.top: parent.top
                  width: 6
                  anchors.bottom: parent.bottom
                  hoverEnabled: true

                  onPressed: {
                      oldMouseX = mouseX
                  }

                  onPositionChanged: {
                      if (pressed) {
                          leftColumn.Layout.preferredWidth = leftColumn.Layout.preferredWidth + (mouseX - oldMouseX)
                          if(leftColumn.Layout.preferredWidth > 300)
                              leftColumn.Layout.preferredWidth = 300
                          else if(leftColumn.Layout.preferredWidth < 220)
                              leftColumn.Layout.preferredWidth = 220
                      }
                  }
            }
        }

        Rectangle {
            visible: combinedChatView.visible && Qt.platform.os !== "android"
            width: 1
            Layout.fillHeight: true
            color: styleHelper.chatBoxBorderColorLeft
        }

        PageView {
            id: combinedChatView
            visible: uiSettings.data.combinedChatWindow && !styleHelper.isGroupHostMode
            Layout.fillWidth: true
            Layout.fillHeight: true

            property QtObject currentContact: (visible && width > 0) ? contactList.selectedContact : null
            onCurrentContactChanged: {
                if (currentContact !== null) {
                    if(Qt.platform.os === "android"){
                        stack.push(combinedChatView)
                    }
                    // remove chat page for user when they are deleted
                    if(typeof currentContact.contactDeletedCallbackAdded === 'undefined') {
                        currentContact.contactDeleted.connect(function(user) {
                            remove(user.contactID);
                        });
                        currentContact.contactDeletedCallbackAdded = true;
                    }
                    show(currentContact.contactID, Qt.resolvedUrl("ChatPage.qml"),
                         { 'contact': currentContact });
                } else {
                    if(Qt.platform.os === "android"){
                        stack.pop(combinedChatView)
                    }
                    currentKey = ""
                }
            }
        }

    }

    property bool inactive: true
    onActiveFocusItemChanged: {
        if(Qt.platform.os !== "android"){
            // Focus current page when window regains focus
            if (activeFocusItem !== null && inactive) {
                inactive = false
                retakeFocus.start()
            } else if (activeFocusItem === null) {
                inactive = true
            }
        }
    }

    Component.onCompleted: {
        if(Qt.platform.os === "android"){
            contentItem.Keys.released.connect(function(event) {
                if (event.key === Qt.Key_Back) {
                    event.accepted = true
                    window.back()
                }
            })
        }
    }

    function back() {
        if(Qt.platform.os === "android"){
            if(stack.depth > 1){
                if(combinedChatView.currentPage !== null)
                    combinedChatView.currentPage.sendMessageButton.forceActiveFocus()
                stack.pop()
            }
            else{
                if(!utility.minimizeAndroid()){
                    window.close()
                }
            }
        }
    }

    Timer {
        id: retakeFocus
        interval: 1
        onTriggered: {
            if (combinedChatView.currentPage !== null)
                combinedChatView.currentPage.forceActiveFocus()
        }
    }

    Action {
        shortcut: StandardKey.Close
        onTriggered: window.close()
    }

}

