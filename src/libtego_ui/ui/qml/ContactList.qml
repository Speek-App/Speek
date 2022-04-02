import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import im.ricochet 1.0

Rectangle {
    id: scroll
    color: palette.base
    property var startIndex: -1

    data: [
        ContactsModel {
            id: contactsModel
        }
    ]

    Rectangle {
        id: scrollBar
        width: 5
        height: contactListView.visibleArea.heightRatio * (contactListView.height - 10)
        y: 5 + contactListView.visibleArea.yPosition * (contactListView.height - 10)
        x: parent.width - width - 3
        z: 1000
        visible: contactListView.visibleArea.heightRatio < 1
        color: styleHelper.scrollBar
        radius: 14
    }

    property QtObject selectedContact
    property ListView view: contactListView

    // Emitted for double click on a contact
    signal contactActivated(ContactUser contact, Item actions)

    onSelectedContactChanged: {
        if (selectedContact !== contactsModel.contact(contactListView.currentIndex)) {
            contactListView.currentIndex = contactsModel.rowOfContact(selectedContact)
        }
    }

    ListView {
        clip: true
        id: contactListView
        model: contactsModel
        currentIndex: startIndex


        pixelAligned: true
        boundsBehavior: Flickable.StopAtBounds
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: {
                wheel.accepted = true
                if (wheel.pixelDelta.y !== 0) {
                    contactListView.contentY = Math.max(contactListView.originY, Math.min(contactListView.originY + contactListView.contentHeight - contactListView.height, contactListView.contentY - wheel.pixelDelta.y))
                } else if (wheel.angleDelta.y !== 0) {
                    contactListView.flick(0, wheel.angleDelta.y * 5)
                }
            }
        }

        signal contactActivated(ContactUser contact, Item actions)
        onContactActivated: scroll.contactActivated(contact, actions)

        onCurrentIndexChanged: {
            // Not using a binding to allow writes to selectedContact
            scroll.selectedContact = contactsModel.contact(contactListView.currentIndex)
        }

        data: [
            MouseArea {
                anchors.fill: parent
                z: -100
                onClicked: contactListView.currentIndex = -1
            }
        ]

        section.property: "section"
        section.delegate: Row {
            width: parent.width - x
            height: label.height + 8
            x: 8
            spacing: 6

            Label {
                id: label
                y: 8

                font.pointSize: styleHelper.pointSize * 0.8
                textFormat: Text.PlainText
                color: palette.text
                opacity: 0.8

                text: {
                    // Translation strings are uppercase for legacy reasons, and because they
                    // should correctly be capitalized. We go lowercase only because it looks nicer
                    switch (section) {
                        //: Section header in the contact list for users which are online
                        case "online": return qsTr("Online").toLowerCase()
                        //: Section header in the contact list for users which are offline
                        case "offline": return qsTr("Offline").toLowerCase()
                        //: Section header in the contact list for users requesting to be added to the user's contact list
                        case "request": return qsTr("Requests").toLowerCase()
                        //: Section header in the contact list for users that have rejected the user's request to be added to their contact list
                        case "rejected": return qsTr("Rejected").toLowerCase()

                        //: Section header in the contact list for groups which are online
                        case "group-online": return qsTr("Group (Online)").toLowerCase()
                        //: Section header in the contact list for groups which are offline
                        case "group-offline": return qsTr("Group (Offline)").toLowerCase()
                        //: Section header in the contact list for groups requesting to be added to the user's contact list
                        case "group-request": return qsTr("Group (Request)").toLowerCase()
                    }
                }

                Accessible.role: Accessible.StaticText
                Accessible.name: text
                //: Description of the section header for accessibility tech like screen readers
                Accessible.description: qsTr("Status for the given contacts")
            }
        }

        delegate: ContactListDelegate { }
    }
}
