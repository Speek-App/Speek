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

    FileDialog {
        id: fileDialogTheme
        onAccepted: {
            var path = fileDialogTheme.fileUrl.toString();
            path = path.replace(/^(file:\/{2})/,"");
            path = decodeURIComponent(path);
            customTheme.text = path;
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

    RowLayout {
        visible: typeof(uiSettings.data.useCustomTheme) !== "undefined" ? !uiSettings.data.useCustomTheme : true
        z: 2
        Label {
            //: Label for combobox where users can specify the color theme
            text: qsTr("Theme")
            Accessible.role: Accessible.StaticText
            Accessible.name: text
        }

        ComboBox {
            currentIndex: typeof(uiSettings.data.theme) !== "undefined" ? model.indexOf(uiSettings.data.theme) : 0
            Layout.minimumWidth: 200
            model: [
                "Dark-Blue",
                "Dark",
                "Light",
            ]

            onActivated: {
                var back = model[index]
                uiSettings.write("theme", back)
                uiMain.reloadTheme()
            }

            Accessible.role: Accessible.ComboBox
            //: Name of the combobox used to select the color theme for accessibility tech like screen readers
            Accessible.name: qsTr("Color Theme")
            //: Description of what the theme is for for accessibility tech like screen readers
            Accessible.description: qsTr("Which theme speek uses")
        }
    }

    CheckBox {
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
                "Blue-Squares",
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
            Accessible.description: qsTr("Which background the Chat Area uses")
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

    RowLayout {
        z: 2
        Label {
            //: Label for combobox where users can specify the used emoji font
            text: qsTr("Emoji Font")
            Accessible.role: Accessible.StaticText
            Accessible.name: text
        }

        ComboBox {
            id: emojiBox
            currentIndex: typeof(uiSettings.data.emojiFont) !== "undefined" ? model.indexOf(uiSettings.data.emojiFont) : 0
            Layout.minimumWidth: 200
            model: ["Noto-Emoji",
                    "Twemoji",
                    "Emojitwo"
            ]

            onActivated: {
                var semoji = model[index]
                uiSettings.write("emojiFont", semoji)
            }

            Accessible.role: Accessible.ComboBox
            //: Name of the combobox used to select the current emoji font for accessibility tech like screen readers
            Accessible.name: qsTr("Current Emoji Font")
            //: Description of what the emoji font combox is for for accessibility tech like screen readers
            Accessible.description: qsTr("Which emoji font the application uses")
        }
    }

    Item{
        height: 10
    }

    RowLayout {
        z: 2
        Label {
            //: Label for the advanced style options
            text: qsTr("Advanced Options:")
            Accessible.role: Accessible.StaticText
            Accessible.name: text
        }
    }

    CheckBox {
        text: qsTr("Use custom theme")
        checked: uiSettings.data.useCustomTheme || false
        onCheckedChanged: {
            uiSettings.write("useCustomTheme", checked)
        }

        Accessible.role: Accessible.CheckBox
        Accessible.name: text
        Accessible.onPressAction: {
            uiSettings.write("useCustomTheme", checked)
        }
    }

    RowLayout {
        visible: typeof(uiSettings.data.useCustomTheme) !== "undefined" ? uiSettings.data.useCustomTheme : false
        z: 2
        Label {
            //: Label for a custome theme
            text: qsTr("Custom Theme")
            Accessible.role: Accessible.StaticText
            Accessible.name: text
        }

        TextArea {
            id: customTheme

            text: typeof(uiSettings.data.customTheme) !== "undefined" ? uiSettings.data.customTheme : ""
            Layout.minimumWidth: 300
            Layout.maximumHeight: 33

            onTextChanged: {
                uiSettings.write("customTheme", customTheme.text)
            }

            Accessible.role: Accessible.EditableText
            //: Name of the text input used to set a custom theme
            Accessible.name: qsTr("Custom theme input field")
            //: Description of what the Custom theme input is for accessibility tech like screen readers
            Accessible.description: qsTr("What the custom theme should be")
        }

        Button {
            //: Label for button which allows the selecting of a custom theme
            text: qsTr("Select Theme")
            onClicked: fileDialogTheme.open()
            Accessible.role: Accessible.Button
            Accessible.name: text
            //: Description of button which allows the selection of a custom theme for accessibility tech like screen readers
            Accessible.description: qsTr("Select a custom theme file")
        }

        Button {
            //: Label for button which allows the creation of a new custom theme
            text: qsTr("Create New Theme")
            tooltip: qsTr("Create a new theme based on the currently selected color scheme")
            onClicked: utility.createNewTheme(uiSettings.data.lightMode ? "light" : "dark")
            Accessible.role: Accessible.Button
            Accessible.name: text
            //: Description of button which allows the creation of a new custom theme for accessibility tech like screen readers
            Accessible.description: qsTr("Create a new custom theme file")
        }

        Button {
            //: Label for button which reloads the theme
            text: qsTr("Reload Theme")
            onClicked: uiMain.reloadTheme()
            Accessible.role: Accessible.Button
            Accessible.name: text
            //: Description of button which reloads the theme for accessibility tech like screen readers
            Accessible.description: qsTr("Reload the theme")
        }
    }

    Item {
        Layout.fillHeight: true
        Layout.fillWidth: true
    }
}
