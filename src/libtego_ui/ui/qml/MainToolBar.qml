import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import QtQuick.Controls.Styles 1.0
import im.ricochet 1.0

ToolBar {
    Layout.minimumWidth: 200
    Layout.fillWidth: true
    // Necessary to avoid oversized toolbars, e.g. OS X with Qt 5.4.1
    implicitHeight: toolBarLayout.height + __style.padding.top + __style.padding.bottom

    property Action addContact: addContactAction
    property Action preferences: preferencesAction

    style: ToolBarStyle {
        panel: Rectangle {
            color: palette.base
        }
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
/*
        Item {
            Layout.fillWidth: true
            height: 1
        }
*/

        Label {
            visible: !torstatewidget.visible

            anchors{
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }
            id: label_speekers
            y: 2

            font.pointSize: styleHelper.pointSize
            font.bold: true
            font.capitalization: Font.SmallCaps
            textFormat: Text.PlainText
            color: palette.text//"#3f454a"
            font.family: "Helvetica"
            text: "Speekers"
            Layout.alignment: Qt.AlignHCenter
        }

        ToolButton {
            anchors{
                right: parent.right
                verticalCenter: parent.verticalCenter
            }

            //visible: !torstatewidget.visible
            id: contextMenuButton
            implicitHeight: 32
            implicitWidth: 32
            onClicked: {
                action: mainContextMenu.popup()
            }
            //action: mainContextMenu.popup()
            //style: iconButtonStyle
            text: "☰"
            style: ButtonStyle {
            background: Rectangle {

                    implicitWidth: 28
                    implicitHeight: 28
                    border.color: control.hovered ? "#dddddd" : "transparent"
                    border.width: 1
                    radius: 5
                    color: "transparent"
                }
            /*label: Image {
                height: 32
                width: 32
                        source: palette.base == "#2a2a2a" ? "qrc:/icons/guest-add-svgrepo-com-white.png" : "qrc:/icons/guest-add-svgrepo-com.png"
                        fillMode: Image.PreserveAspectFit  // ensure it fits
                        Layout.preferredHeight: 32
                            Layout.preferredWidth: 32
                            smooth: true
                            antialiasing: true
                            sourceSize: Qt.size(width*2,height*2)
                    }*/
            }

            Loader {
                id: emptyState
                active: contactList.view.count == 0
                sourceComponent: Bubble {
                    target: addContactButton
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
                onTriggered: addContactAction.trigger()
            }
            MenuSeparator { }
            MenuItem {
                //: Context menu command to remove a contact from the contact list
                text: qsTr("Settings")
                onTriggered: preferencesAction.trigger()
            }
        }
/*
        ToolButton {
            visible: !torstatewidget.visible
            id: addContactButton
            implicitHeight: 32
            implicitWidth: 32
            action: addContactAction
            //style: iconButtonStyle
            //text: "\ue810" // iconFont plus symbol
            style: ButtonStyle {
            background: Rectangle {

                    implicitWidth: 28
                    implicitHeight: 28
                    border.color: control.hovered ? "#dddddd" : "transparent"
                    border.width: 1
                    radius: 5
                    color: "transparent"
                }
            label: Image {
                height: 32
                width: 32
                        source: palette.base == "#2a2a2a" ? "qrc:/icons/guest-add-svgrepo-com-white.png" : "qrc:/icons/guest-add-svgrepo-com.png"
                        fillMode: Image.PreserveAspectFit  // ensure it fits
                        Layout.preferredHeight: 32
                            Layout.preferredWidth: 32
                            smooth: true
                            antialiasing: true
                            sourceSize: Qt.size(width*2,height*2)
                    }
            }

            Loader {
                id: emptyState
                active: contactList.view.count == 0
                sourceComponent: Bubble {
                    target: addContactButton
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

        ToolButton {
            action: preferencesAction
            implicitHeight: 32
            implicitWidth: 32
            //style: iconButtonStyle
            //text: "\ue803" // iconFont gear

            style: ButtonStyle {
            background: Rectangle {

                    implicitWidth: 28
                    implicitHeight: 28
                    border.color: control.hovered ? "#dddddd" : "transparent"
                    border.width: 1
                    radius: 5
                    color: "transparent"
                }
            label: Image {
                height: 32
                width: 32
                        source: palette.base == "#2a2a2a" ? "qrc:/icons/table-settings-svgrepo-com-white.png" : "qrc:/icons/table-settings-svgrepo-com.png"
                        fillMode: Image.PreserveAspectFit  // ensure it fits
                        Layout.preferredHeight: 32
                            Layout.preferredWidth: 32
                            smooth: true
                            antialiasing: true
                            sourceSize: Qt.size(width*2,height*2)
                    }
            }

            Accessible.role: Accessible.Button
            //: Name of the button for launching the preferences window for accessibility tech like screen readres
            Accessible.name: qsTr("Preferences")
            //: Description of the 'Preferences' button for accessibility tech like screen readers
            Accessible.description: qsTr("Shows the preferences dialogue") // todo: translation
        }*/
    }
}
