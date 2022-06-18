import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0

Rectangle {
    id: scroll
    clip: true
    color: palette.base

    property alias model: messageView.model

    Image {
        id: image2
        anchors.fill: parent
        source: {
            if(typeof(uiSettings.data.UseCustomChatAreaBackground) !== "undefined" && uiSettings.data.UseCustomChatAreaBackground === true)
                return uiSettings.data.customChatAreaBackground
            else
                if(typeof(uiSettings.data.chatBackground) !== "undefined")
                    return "qrc:/backgrounds/" + uiSettings.data.chatBackground.toLowerCase() + ".jpg"
                else
                    return "qrc:/backgrounds/blue.jpg"
        }
        fillMode: Image.PreserveAspectCrop
        smooth: true
        antialiasing: true
    }

    /* As of Qt 5.5.0, ScrollView is too buggy to use. It often fails to keep the
     * view scrolled to the bottom, and moves erratically on wheel events. */
    Rectangle {
        id: scrollBar
        width: 5
        height: messageView.visibleArea.heightRatio * (messageView.height - 10)
        y: 5 + messageView.visibleArea.yPosition * (messageView.height - 10)
        x: parent.width - width - 3
        z: 1000
        visible: messageView.visibleArea.heightRatio < 1
        color: styleHelper.scrollBar
        radius: 14
    }

    ListView {
        id: messageView
        spacing: 12
        pixelAligned: true
        boundsBehavior: Flickable.StopAtBounds
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            preventStealing: true
            onWheel: {
                wheel.accepted = true
                if (wheel.pixelDelta.y !== 0) {
                    messageView.contentY = Math.max(messageView.originY, Math.min(messageView.originY + messageView.contentHeight - messageView.height, messageView.contentY - wheel.pixelDelta.y))
                } else if (wheel.angleDelta.y !== 0) {
                    messageView.flick(0, wheel.angleDelta.y * 5)
                }
            }

            propagateComposedEvents: true

            property real velocity: 0.0
            property int xStart: 0
            property int xPrev: 0
            property bool tracing: false
            onPressed: {
                //remove focus from textarea
                emojiActivateButton.forceActiveFocus()
                if(!tracing){
                    xStart = mouse.x
                    xPrev = mouse.x
                    velocity = 0
                    tracing = true
                }

                mouse.accepted = false;
            }
            onPositionChanged: {
                if ( !tracing ) return
                var currVel = (mouse.x-xPrev)
                velocity = (velocity + currVel)/2.0
                xPrev = mouse.x
                if ( velocity > 15 && mouse.x > parent.width*0.5 ) {
                    tracing = false
                }
                mouse.accepted = false;
            }
            onReleased: {
                tracing = false
                if ( velocity > 15 && mouse.x > parent.width*0.5 ) {
                    if(Qt.platform.os === "android"){
                        if(uiSettings.data.combinedChatWindow)
                            if(stack.depth > 1){
                                stack.pop()
                                //remove focus from textarea
                                emojiActivateButton.forceActiveFocus()
                            }
                        else
                            chatWindow.close()
                    }
                }
                mouse.accepted = false;
            }
        }

        header: Item { width: 1; height: messageView.spacing }
        footer: Item { width: 1; height: messageView.spacing }
        delegate: MessageDelegate { }

        verticalLayoutDirection: ListView.BottomToTop
    }
}

