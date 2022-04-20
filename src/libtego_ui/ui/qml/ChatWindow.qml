import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.0
import im.ricochet 1.0

ApplicationWindow {
    id: chatWindow
    width: 500
    height: 400
    flags: Qt.Window
    modality: Qt.WindowModal
    title: contact !== null ? contact.nickname : ""

    property alias contact: chatPage.contact
    signal closed

    onVisibleChanged: {
        if (!visible)
            closed()
    }

    onClosed: {
        console.log("closed chat window")
        // If not also in combined window mode, clear chat history when closing
        if (!uiSettings.data.combinedChatWindow && Qt.platform.os !== "android")
            chatPage.conversationModel.clear()
    }

    property bool inactive: true
    onActiveFocusItemChanged: {
        if(Qt.platform.os !== "android"){
            // Focus text input when window regains focus
            if (activeFocusItem !== null && inactive) {
                inactive = false
                retakeFocus.start()
            } else if (activeFocusItem === null) {
                inactive = true
            }
        }
    }

    Timer {
        id: timer_delay
        function setTimeout(cb, delayTime) {
            timer_delay.interval = delayTime;
            timer_delay.repeat = false;
            timer_delay.triggered.connect(cb);
            timer_delay.triggered.connect(function release () {
                timer_delay.triggered.disconnect(cb); // This is important
                timer_delay.triggered.disconnect(release); // This is important as well
            });
            timer_delay.start();
        }
    }
/*
    Connections {
        target: Qt.application
        onStateChanged:
            if(Qt.platform.os === "android"){
                if(Qt.application.state === Qt.ApplicationActive) {
                    console.log("ACTIVE")
                    console.log(visible)
                    chatWindow.raise()
                    chatWindow.requestActivate()
                    timer_delay.setTimeout(function(){
                        chatWindow.raise()
                        chatWindow.requestActivate()
                    },5000)
                }
                else if(Qt.application.state === Qt.ApplicationSuspended) {
                     console.log("ISUSPENDED")
                }
            }
    }
*/
    ChatPage {
        id: chatPage
        anchors.fill: parent
    }

    Action {
        shortcut: StandardKey.Close
        onTriggered: chatWindow.close()
    }
}

