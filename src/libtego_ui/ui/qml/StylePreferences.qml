import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import QtQuick.Dialogs 1.0
import im.utility 1.0
import im.ricochet 1.0

ColumnLayout {
    Utility {
           id: utility
        }

    FileDialog {
        id: fileDialog
        nameFilters: ["Images (*.png *.jpg *.jpeg)"]
        onAccepted: {
            var b = utility.platformPath(fileDialog.fileUrl.toString());
            customChatAreaBackgroundText.text = b;
        }
    }

    anchors {
        fill: parent
        margins: 8
    }

    CheckBox {
        //: Text description of an option to use one single program window for the contact list and the chats
        text: qsTr("Use a single window for conversations")
        checked: uiSettings.data.combinedChatWindow || false
        onCheckedChanged: {
            uiSettings.write("combinedChatWindow", checked)
        }

        Accessible.role: Accessible.CheckBox
        Accessible.name: text
        Accessible.onPressAction: {
            uiSettings.write("combinedChatWindow", checked)
        }
    }

    CheckBox {
        //: Text description of an option to activate a light mode theme
        text: qsTr("Activate light mode (restart required)")
        checked: uiSettings.data.lightMode || false
        onCheckedChanged: {
            uiSettings.write("lightMode", checked)
        }

        Accessible.role: Accessible.CheckBox
        Accessible.name: text
        Accessible.onPressAction: {
            uiSettings.write("lightMode", checked)
        }
    }

    CheckBox {
        //: Text description of an option to play audio notifications when contacts log in, log out, and send messages
        text: qsTr("Use custom chat area background")
        checked: uiSettings.data.UseCustomChatAreaBackground || false
        onCheckedChanged: {
            uiSettings.write("UseCustomChatAreaBackground", checked)
        }

        Accessible.role: Accessible.CheckBox
        Accessible.name: text
        Accessible.onPressAction: {
            uiSettings.write("UseCustomChatAreaBackground", checked)
        }
    }

    RowLayout {
        visible: typeof(uiSettings.data.UseCustomChatAreaBackground) !== "undefined" ? !uiSettings.data.UseCustomChatAreaBackground : true
        z: 2
        Label {
            //: Label for combobox where users can specify the Background for the chat area
            text: qsTr("Chat Area Background")
            Accessible.role: Accessible.StaticText
            Accessible.name: text
        }

        ComboBox {
            id: backgroundBox
            currentIndex: typeof(uiSettings.data.chatBackground) !== "undefined" ? model.indexOf(uiSettings.data.chatBackground) : 0
            Layout.minimumWidth: 200
            model: [
                "Blue",
                "Purple",
                "Purple2",
                "Purple-Blue",
                "Purple-Wave",
            ]

            onActivated: {
                var back = model[index]
                uiSettings.write("chatBackground", back)
            }

            Accessible.role: Accessible.ComboBox
            //: Name of the combobox used to select UI langauge for accessibility tech like screen readers
            Accessible.name: qsTr("Chat Area Background")
            //: Description of what the language combox is for for accessibility tech like screen readers
            Accessible.description: qsTr("What background the Chat Area uses")
        }
    }

    RowLayout {
        visible: typeof(uiSettings.data.UseCustomChatAreaBackground) !== "undefined" ? uiSettings.data.UseCustomChatAreaBackground : false
        z: 2
        Label {
            //: Label for text input for custom chat area background
            text: qsTr("Custom Chat Area Background")
            Accessible.role: Accessible.StaticText
            Accessible.name: text
        }

        TextArea {
            id: customChatAreaBackgroundText

            text: typeof(uiSettings.data.customChatAreaBackground) !== "undefined" ? uiSettings.data.customChatAreaBackground : ""
            Layout.minimumWidth: 300
            Layout.maximumHeight: 33

            onTextChanged: {
                uiSettings.write("customChatAreaBackground", customChatAreaBackgroundText.text)
            }

            Accessible.role: Accessible.EditableText
            //: Name of the text input used to set a custom chat area background
            Accessible.name: qsTr("Custom chat area background input field")
            //: Description of what the Custom chat area background input is for accessibility tech like screen readers
            Accessible.description: qsTr("What the custom chat area background should be")
        }

        Button {
            //: Label for button which allows the selecting of a custom chat area background
            text: qsTr("Select Image")
            onClicked: fileDialog.open()
            Accessible.role: Accessible.Button
            Accessible.name: text
            //: Description of button which allows the selection of a custom chat area background for accessibility tech like screen readers
            Accessible.description: qsTr("Select a custom chat area background image")
        }
    }

    Item {
        Layout.fillHeight: true
        Layout.fillWidth: true
    }
}
