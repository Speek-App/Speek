import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import QtQuick.Controls.Styles 1.2
import im.ricochet 1.0
import im.utility 1.0

ToolBar {
    id: mainToolBar
    Layout.minimumWidth: 200
    Layout.fillWidth: true
    // Necessary to avoid oversized toolbars, e.g. OS X with Qt 5.4.1
    implicitHeight: toolBarLayout.height + __style.padding.top + __style.padding.bottom

    property Action addContact: addContactAction
    property Action preferences: preferencesAction
    property alias searchUserText: searchUser.text

    style: ToolBarStyle {
        panel: Rectangle {
            color: palette.base
        }
    }

    Utility {
       id: utility
    }

    data: [
        Action {
            id: addContactAction
            //: Tooltip text for the button that launches the dialog box for adding a new contact
            text: qsTr("Add Contact")
            onTriggered: {
                var object = createDialog("AddContactDialog.qml", { }, window)
                object.visible = true
            }
        },

        Action {
            id: viewIdAction
            //: Tooltip text for the button that launches the dialog box for adding a new contact
            text: qsTr("View Id")
            onTriggered: {
                var object = createDialog("ViewIdDialog.qml", { }, window)
                object.visible = true
            }
        },

        Action {
            id: preferencesAction
            //: Tooltip text for the button that launches program preferences window
            text: qsTr("Preferences")
            onTriggered: root.openPreferences()
        }
    ]

    Component {
        id: iconButtonStyle

        ButtonStyle {
            background: Item { }
            label: Text {
                text: control.text
                font.family: iconFont.name
                font.pixelSize: height
                horizontalAlignment: Qt.AlignHCenter
                renderType: Text.QtRendering
                color: "black"
            }
        }
    }

    RowLayout {
        id: toolBarLayout
        width: parent.width
        spacing: 0
        height: 50

        TorStateWidget {
            id:torstatewidget
            Layout.alignment: Qt.AlignVCenter
            visible: text === qsTr("Online") ? false : true
        }

        ToolButton {
            visible: !torstatewidget.visible
            id: contextMenuButton
            implicitHeight: 32
            implicitWidth: 42

            onClicked: {
                action: mainContextMenu.popup()
            }

            text: "F"

            style: ButtonStyle {
                background: Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    border.color: control.hovered ? "#dddddd" : "transparent"
                    border.width: 1
                    radius: 5
                    color: "transparent"

                }
                label: Text {
                    renderType: Text.NativeRendering
                    font.family: iconFont.name
                    font.pointSize: styleHelper.pointSize * 1.1
                    font.bold: true
                    text: control.text
                    color: palette.text
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                 }
            }

            Loader {
                id: emptyState
                active: contactList.view.count == 0
                sourceComponent: Bubble {
                    horizontalAlignment: Qt.AlignLeft
                    x: -3
                    target: contextMenuButton
                    maximumWidth: toolBarLayout.width
                    //: Tooltip that displays on first launch indicating how to add a new contact
                    text: qsTr("Click to add contacts")
                }
            }

            Accessible.role: Accessible.Button
            //: Name of the button for adding a new contact for accessibility tech like screen readers
            Accessible.name: qsTr("Add Contact")
            //: Description of the 'Add Contact' button for accessibility tech like screen readers
            Accessible.description: qsTr("Shows the add contact dialogue")
        }

        SearchBox {
            id: searchUser

            visible: !torstatewidget.visible
            text: ""
            Layout.fillWidth: true
            Layout.maximumHeight: 34

            Accessible.role: Accessible.EditableText
            //: Name of the text input used to filter the contacts
            Accessible.name: qsTr("Contact search")
            //: Description of what the contact search filter is for accessibility tech like screen readers
            Accessible.description: qsTr("Which contact to find")
        }

        Menu {
            id: mainContextMenu

            /* QT automatically sets Accessible.text to MenuItem.text */
            MenuItem {
                //: Context menu command to open the chat screen in a separate window
                text: qsTr("Add Contact")
                onTriggered: addContactAction.trigger()
            }
            MenuItem {
                //: Context menu command to open a window showing the selected contact's details
                text: qsTr("View Speek ID")
                onTriggered: viewIdAction.trigger()
            }
            MenuSeparator { }
            MenuItem {
                visible: !(Qt.platform.os == 'osx')
                //: Context menu command to remove a contact from the contact list
                text: qsTr("Open other Identity")
                onTriggered: {
                    var object = createDialog("SelectIdentityDialog.qml", { }, window)
                    object.visible = true
                }
            }
            MenuItem {
                //: Context menu command to open the settings dialog
                text: qsTr("Settings")
                onTriggered: preferencesAction.trigger()
            }
        }
    }
}
