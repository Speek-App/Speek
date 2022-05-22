import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    visible: contact.status == 0 || contact.status == 1 ? false : true
    anchors.fill: parent
    color: "transparent"

    Rectangle{
        width:100
        height: Qt.platform.os === "android" ? 240 : 140
        color: "transparent"
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        BusyIndicator {
            running: true
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: Qt.platform.os === "android" ? 150 : 100
            height: Qt.platform.os === "android" ? 150 : 100
            smooth: true
        }
        Label{
            id: waitingLabel
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            text: "Waiting for contact request to be accepted..."
        }
        Button {
            visible: Qt.platform.os === "android"
            anchors.top: waitingLabel.bottom
            anchors.topMargin: 10
            //: Label for button which removes a contact from the contact list
            text: qsTr("Contact Settings")
            onClicked: {
                chatFocusScope._openPreferences()
            }
            Accessible.role: Accessible.Button
            Accessible.name: text
            //: Description of button opens the contact settings for accessibility tech like screen readers
            Accessible.description: qsTr("Open Contact Settings")
        }
    }
}
