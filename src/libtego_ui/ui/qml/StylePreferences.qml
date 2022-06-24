import QtQuick 2.0
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.0
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.15
import im.utility 1.0
import im.ricochet 1.0

Item{
    anchors {
        fill: parent
        margins: 8
    }

    ColumnLayout {
        anchors.fill: parent

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

        SettingsSwitch{
            visible: Qt.platform.os !== "android"
            //: Text description of an option to use one single program window for the contact list and the chats
            text: qsTr("Use a single window for conversations")
            position: uiSettings.data.combinedChatWindow || false
            triggered: function(checked){
                uiSettings.write("combinedChatWindow", checked)
            }
        }

        RowLayout {
            Layout.maximumWidth: 400
            visible: typeof(uiSettings.data.useCustomTheme) !== "undefined" ? !uiSettings.data.useCustomTheme : true
            z: 2

            Image{
                visible: Qt.platform.os === "android"
                source: "qrc:/icons/android/settings_android/brush.svg"
                Layout.preferredWidth: styleHelper.androidIconSize
                Layout.preferredHeight: styleHelper.androidIconSize
            }
            Item{width:2;visible: Qt.platform.os === "android"}

            Label {
                Layout.fillWidth: true
                //: Label for combobox where users can specify the color theme
                text: qsTr("Theme (restart required)")
                Accessible.role: Accessible.StaticText
                Accessible.name: text
            }

            ComboBox {
                Material.background: Material.Indigo
                currentIndex: typeof(uiSettings.data.theme) !== "undefined" ? model.indexOf(uiSettings.data.theme) : 0
                Layout.minimumWidth: 140
                Component.onCompleted: {
                    if(Qt.platform.os !== "android"){
                        contentItem.color = palette.text
                        indicator.color = palette.text
                    }
                }
                model: [
                    "Dark-Blue",
                    "Dark",
                    "Light",
                ]

                onActivated: {
                    var oldTheme = uiSettings.read("theme", "dark-blue")
                    var newTheme = model[index]
                    uiSettings.write("theme", newTheme)

                    if(oldTheme !== newTheme)
                        utility.themeChanged()
                        //reloading the theme not working correctly with qtquick2
                        //uiMain.reloadTheme()
                }

                Accessible.role: Accessible.ComboBox
                //: Name of the combobox used to select the color theme for accessibility tech like screen readers
                Accessible.name: qsTr("Color Theme")
                //: Description of what the theme is for for accessibility tech like screen readers
                Accessible.description: qsTr("Which theme speek uses")
            }
            Item{width:5;height:1}
        }

        SettingsSwitch{
            text: qsTr("Use custom chat area background")
            position: uiSettings.data.UseCustomChatAreaBackground || false
            switchIcon: "qrc:/icons/android/settings_android/picture.svg"
            triggered: function(checked){
                uiSettings.write("UseCustomChatAreaBackground", checked)
            }
        }

        RowLayout {
            Layout.maximumWidth: 400
            visible: typeof(uiSettings.data.UseCustomChatAreaBackground) !== "undefined" ? !uiSettings.data.UseCustomChatAreaBackground : true
            z: 2

            Image{
                visible: Qt.platform.os === "android"
                source: "qrc:/icons/android/settings_android/change_image.svg"
                Layout.preferredWidth: styleHelper.androidIconSize
                Layout.preferredHeight: styleHelper.androidIconSize
            }
            Item{width:2;visible: Qt.platform.os === "android"}

            Label {
                Layout.fillWidth: true
                //: Label for combobox where users can specify the Background for the chat area
                text: qsTr("Chat Area Background")
                Accessible.role: Accessible.StaticText
                Accessible.name: text
            }

            ComboBox {
                id: backgroundBox
                Material.background: Material.Indigo
                currentIndex: typeof(uiSettings.data.chatBackground) !== "undefined" ? model.indexOf(uiSettings.data.chatBackground) : 0
                Layout.minimumWidth: 140
                Component.onCompleted: {
                    if(Qt.platform.os !== "android"){
                        contentItem.color = palette.text
                        indicator.color = palette.text
                    }
                }
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
            Item{width:5;height:1}
        }

        ColumnLayout{
            visible: typeof(uiSettings.data.UseCustomChatAreaBackground) !== "undefined" ? uiSettings.data.UseCustomChatAreaBackground : false
            z: 2

            RowLayout{
                Image{
                    visible: Qt.platform.os === "android"
                    source: "qrc:/icons/android/settings_android/change_image.svg"
                    Layout.preferredWidth: styleHelper.androidIconSize
                    Layout.preferredHeight: styleHelper.androidIconSize
                }
                Item{width:2;visible: Qt.platform.os === "android"}

                Label {
                    //: Label for text input for custom chat area background
                    text: qsTr("Custom Chat Area Background")
                    Accessible.role: Accessible.StaticText
                    Accessible.name: text
                }
            }

            RowLayout {
                TextArea {
                    id: customChatAreaBackgroundText

                    text: typeof(uiSettings.data.customChatAreaBackground) !== "undefined" ? uiSettings.data.customChatAreaBackground : ""
                    Layout.minimumWidth: 80
                    Layout.maximumHeight: Qt.platform.os === "android" ? 50 : 33
                    Layout.fillWidth: true

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
                    Component.onCompleted: {if(Qt.platform.os !== "android")contentItem.color = palette.text}
                    Accessible.role: Accessible.Button
                    Accessible.name: text
                    //: Description of button which allows the selection of a custom chat area background for accessibility tech like screen readers
                    Accessible.description: qsTr("Select a custom chat area background image")
                }
                Item{width:5;height:1}
            }
        }

        RowLayout {
            Layout.maximumWidth: 400
            Layout.bottomMargin: 5
            z: 2

            Image{
                visible: Qt.platform.os === "android"
                source: "qrc:/icons/android/settings_android/smiley.svg"
                Layout.preferredWidth: styleHelper.androidIconSize
                Layout.preferredHeight: styleHelper.androidIconSize
            }
            Item{width:2;visible: Qt.platform.os === "android"}

            Label {
                Layout.fillWidth: true
                //: Label for combobox where users can specify the used emoji font
                text: qsTr("Emoji Font")
                Accessible.role: Accessible.StaticText
                Accessible.name: text
            }

            ComboBox {
                id: emojiBox
                Material.background: Material.Indigo
                currentIndex: typeof(uiSettings.data.emojiFont) !== "undefined" ? model.indexOf(uiSettings.data.emojiFont) : 0
                Layout.minimumWidth: 140
                Component.onCompleted: {
                    if(Qt.platform.os !== "android"){
                        contentItem.color = palette.text
                        indicator.color = palette.text
                    }
                }
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
            Item{width:5;height:1}
        }

        ColumnLayout{
            RowLayout {
                Image{
                    visible: Qt.platform.os === "android"
                    source: "qrc:/icons/android/settings_android/change_font_size.svg"
                    Layout.preferredWidth: styleHelper.androidIconSize
                    Layout.preferredHeight: styleHelper.androidIconSize
                }
                Item{width:2;visible: Qt.platform.os === "android"}

                Label {
                    //: Label for a slider used to adjust the font size
                    text: qsTr("Font Size (restart required)")
                    Accessible.role: Accessible.StaticText
                    Accessible.name: text
                }
            }
            RowLayout {
                Item { width: Qt.platform.os === "android" ? 36 : 16 }

                Slider {
                    to: 1.3
                    from: 0.7
                    snapMode: Slider.SnapAlways
                    value: uiSettings.read("fontSizeMultiplier", 1)
                    stepSize: 0.15

                    onValueChanged: {
                        var oldSize = uiSettings.read("fontSizeMultiplier", 1)
                        var newSize = value
                        uiSettings.write("fontSizeMultiplier", value)

                        if(oldSize !== newSize)
                            utility.fontSizeChanged()
                    }

                    Accessible.role: Accessible.Slider
                    //: Name of the slider used to adjust the font size for accessibility tech like screen readers
                    Accessible.name: qsTr("Font Size Multiplier")
                    Accessible.onIncreaseAction: {
                        value += 0.15
                    }
                    Accessible.onDecreaseAction: {
                        value -= 0.15
                    }
                }
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

        SettingsSwitch{
            text: qsTr("Use custom theme")
            position: uiSettings.data.useCustomTheme || false
            switchIcon: "qrc:/icons/android/settings_android/custom_theme.svg"
            triggered: function(checked){
                uiSettings.write("useCustomTheme", checked)
            }
        }

        ColumnLayout {
            visible: typeof(uiSettings.data.useCustomTheme) !== "undefined" ? uiSettings.data.useCustomTheme : false
            z: 2
            Label {
                //: Label for a custome theme
                text: qsTr("Custom Theme:")
                Accessible.role: Accessible.StaticText
                Accessible.name: text
            }
            RowLayout{
                TextField {
                    id: customTheme

                    text: typeof(uiSettings.data.customTheme) !== "undefined" ? uiSettings.data.customTheme : ""
                    Layout.minimumWidth: 200
                    Layout.maximumHeight: Qt.platform.os === "android" ? 50 : 33

                    onTextChanged: {
                        uiSettings.write("customTheme", customTheme.text)
                    }

                    Accessible.role: Accessible.EditableText
                    //: Name of the text input used to set a custom theme
                    Accessible.name: qsTr("Custom theme input field")
                    //: Description of what the Custom theme input is for accessibility tech like screen readers
                    Accessible.description: qsTr("What the custom theme should be")
                }
            }
            RowLayout{
                Button {
                    //: Label for button which allows the selecting of a custom theme
                    text: qsTr("Select Theme")
                    onClicked: fileDialogTheme.open()
                    Component.onCompleted: {if(Qt.platform.os !== "android")contentItem.color = palette.text}
                    Accessible.role: Accessible.Button
                    Accessible.name: text
                    //: Description of button which allows the selection of a custom theme for accessibility tech like screen readers
                    Accessible.description: qsTr("Select a custom theme file")
                }

                Button {
                    //: Label for button which allows the creation of a new custom theme
                    text: qsTr("Create New Theme")
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Create a new theme based on the currently selected color scheme")
                    onClicked: utility.createNewTheme(uiSettings.data.lightMode ? "light" : "dark")
                    Component.onCompleted: {if(Qt.platform.os !== "android")contentItem.color = palette.text}
                    Accessible.role: Accessible.Button
                    Accessible.name: text
                    //: Description of button which allows the creation of a new custom theme for accessibility tech like screen readers
                    Accessible.description: qsTr("Create a new custom theme file")
                }

                Button {
                    //: Label for button which reloads the theme
                    text: qsTr("Reload Theme")
                    onClicked: uiMain.reloadTheme()
                    Component.onCompleted: {if(Qt.platform.os !== "android")contentItem.color = palette.text}
                    Accessible.role: Accessible.Button
                    Accessible.name: text
                    //: Description of button which reloads the theme for accessibility tech like screen readers
                    Accessible.description: qsTr("Reload the theme")
                }
            }
        }

        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
        }
    }
}
