import QtQuick 2.0
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.0
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Styles 1.2
import QtQuick.Controls.Material 2.15
import im.utility 1.0
import im.ricochet 1.0

Item{
    anchors.fill: parent
    anchors.margins: 8

    ColumnLayout {
        Utility {
           id: utility
        }

        anchors.fill: parent

        RowLayout {
            z: 2
            Layout.maximumWidth: Qt.platform.os === "android" ? 1500 : 400
            id: usernameLayout

            Image{
                visible: Qt.platform.os === "android"
                source: "qrc:/icons/android/settings_android/settings_username.svg"
                Layout.preferredWidth: styleHelper.androidIconSize
                Layout.preferredHeight: styleHelper.androidIconSize
            }
            Item{width:2;visible: Qt.platform.os === "android"}

            RowLayout {
                spacing: 0

                Label {
                    //: Label for text input where users can specify their username
                    text: !styleHelper.isGroupHostMode ? qsTr("Username") : qsTr("Group Name")
                    Accessible.role: Accessible.StaticText
                    Accessible.name: text
                }

                Button {
                    id: infoButton
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    hoverEnabled: true

                    ToolTip.visible: Qt.platform.os === "android" ? pressed : hovered
                    ToolTip.text: qsTr("Username that gets automatically filled into the \"your username\" field of a contact request. This recommends the contact a username to use for you.")

                    background: Rectangle {
                        implicitWidth: 10
                        implicitHeight: 10
                        color: "transparent"
                    }
                    contentItem: Text {
                        text: "N"
                        font.family: iconFont.name
                        font.pixelSize: 10
                        horizontalAlignment: Qt.AlignLeft
                        renderType: Text.QtRendering
                        color: {
                            return infoButton.hovered ? palette.text : styleHelper.chatIconColor
                        }
                    }
                }
            }

            function save_username(){
                if (usernameText.length > 40) usernameText.remove(40, usernameText.length);
                uiSettings.write("username", usernameText.text)
            }

            TextField {
                id: usernameText

                text: typeof(uiSettings.data.username) !== "undefined" ? uiSettings.data.username : "Speek User"
                Layout.minimumWidth: 110
                Layout.maximumHeight: Qt.platform.os === "android" ? 50 : 33

                validator: RegExpValidator{regExp: /^[a-zA-Z0-9\-_, ]+$/}

                /*onTextChanged: {
                    if(Qt.platform.os !== "android")
                        usernameLayout.save_username()
                }*/

                Accessible.role: Accessible.EditableText
                //: Name of the text input used to select the own username
                Accessible.name: qsTr("Username input field")
                //: Description of what the username text input is for accessibility tech like screen readers
                Accessible.description: qsTr("What the own username should be")
            }

            Button {
                //: Label for button which allows the user to save to changed username
                text: qsTr("Save")
                onClicked: {
                    usernameLayout.save_username()
                }
                Component.onCompleted: {if(Qt.platform.os !== "android")contentItem.color = palette.text}
                Accessible.role: Accessible.Button
                Accessible.name: text
                //: Description of button which allows the user to save the changed username for accessibility tech like screen readers
                Accessible.description: qsTr("Save the username")
            }
            Item{width:5;height:1}
        }

        ColumnLayout {
            z: 2
            visible: styleHelper.isGroupHostMode
            RowLayout {
                spacing: 0
                Label {
                    //: Label for text area where users can specify the pinned message for a group
                    text: qsTr("Group Pinned Message")
                    Accessible.role: Accessible.StaticText
                    Accessible.name: text
                }
            }

            ScrollView {
                Layout.fillHeight: true
                Layout.fillWidth: true

                background: Rectangle { color: palette.base;radius:4;visible:Qt.platform.os !== "android" }
                TextArea {
                    id: groupPinnedMessage

                    text: typeof(uiSettings.data.groupPinnedMessage) !== "undefined" ? uiSettings.data.groupPinnedMessage : ""
                    Layout.fillWidth: true
                    Layout.maximumHeight: 80

                    onTextChanged: {
                        if (length > 800) remove(800, length);
                        uiSettings.write("groupPinnedMessage", groupPinnedMessage.text)
                    }

                    Accessible.role: Accessible.EditableText
                    //: Name of the text input used to change the pinned message of a group
                    Accessible.name: qsTr("Group Pinned Message input field")
                    //: Description of what the group pinned message input field is for accessibility tech like screen readers
                    Accessible.description: qsTr("What the pinned message of the group should be")
                }
            }
        }

        SettingsSwitch{
            visible: !styleHelper.isGroupHostMode
            //: Text description of an option to activate rich text editing by default which allows the input of emojis and images
            text: qsTr("Disable default Rich Text editing")
            position: uiSettings.data.disableDefaultRichText || false
            switchIcon: "qrc:/icons/android/settings_android/settings_rich_text.svg"
            triggered: function(checked){
                uiSettings.write("disableDefaultRichText", checked)
            }
        }

        SettingsSwitch{
            visible: !styleHelper.isGroupHostMode && Qt.platform.os !== "android"
            //: Text description of an option to minimize to the systemtray
            text: qsTr("Minimize to Systemtray")
            position: uiSettings.data.minimizeToSystemtray || false
            triggered: function(checked){
                uiSettings.write("minimizeToSystemtray", checked)
            }
        }

        SettingsSwitch{
            visible: typeof(uiSettings.data.minimizeToSystemtray) !== "undefined" ? uiSettings.data.minimizeToSystemtray : false
            //: Text description of an option to show a notification in the Systemtray when a new message arrives
            text: qsTr("Show notification in Systemtray when a new message arrives and window is minimized")
            position: uiSettings.data.showNotificationSystemtray || false
            triggered: function(checked){
                uiSettings.write("showNotificationSystemtray", checked)
            }
        }

        SettingsSwitch{
            visible: !styleHelper.isGroupHostMode && Qt.platform.os === "android"
            //: Text description of an option to show a notifications when a new message arrives etc. for android devices
            text: qsTr("Show system notifications")
            position: uiSettings.data.showNotificationAndroid || false
            switchIcon: "qrc:/icons/android/settings_android/notification.svg"
            triggered: function(checked){
                uiSettings.write("showNotificationAndroid", checked)
            }
        }

        SettingsSwitch{
            visible: !styleHelper.isGroupHostMode
            //: Text description of an option to play audio notifications when contacts log in, log out, and send messages
            text: qsTr("Play audio notifications")
            position: uiSettings.data.playAudioNotification || false
            switchIcon: "qrc:/icons/android/settings_android/settings_sound.svg"
            triggered: function(checked){
                uiSettings.write("playAudioNotification", checked)
            }
        }

        RowLayout {
            visible: !styleHelper.isGroupHostMode
            Item { width: Qt.platform.os === "android" ? 36 : 16 }

            Label {
                //: Label for a slider used to adjust audio notification volume
                text: qsTr("Volume")
                Accessible.role: Accessible.StaticText
                Accessible.name: text
            }

            Slider {
                to: 1.0
                enabled: uiSettings.data.playAudioNotification || false
                value: uiSettings.read("notificationVolume", 0.75)
                onValueChanged: {
                    uiSettings.write("notificationVolume", value)
                }

                Accessible.role: Accessible.Slider
                //: Name of the slider used to adjust audio notification volume for accessibility tech like screen readers
                Accessible.name: qsTr("Volume")
                Accessible.onIncreaseAction: {
                    value += 0.125 // 8 volume settings
                }
                Accessible.onDecreaseAction: {
                    value -= 0.125
                }
            }
        }

        RowLayout {
            z: 2
            Layout.maximumWidth: 400

            Image{
                visible: Qt.platform.os === "android"
                source: "qrc:/icons/android/settings_android/settings_language.svg"
                Layout.preferredWidth: styleHelper.androidIconSize
                Layout.preferredHeight: styleHelper.androidIconSize
            }
            Item{width:2;visible: Qt.platform.os === "android"}

            Label {
                Layout.fillWidth: true
                //: Label for combobox where users can specify the UI language
                text: qsTr("Language")
                Accessible.role: Accessible.StaticText
                Accessible.name: text
            }

            ComboBox {
                id: languageBox
                model: languageModel
                textRole: "nativeName"
                currentIndex: languageModel.rowForLocaleID(uiSettings.data.language)
                Layout.minimumWidth: 160
                Material.background: Material.Indigo

                Component.onCompleted: {
                    if(Qt.platform.os !== "android"){
                        contentItem.color = palette.text
                        indicator.color = palette.text
                    }
                }

                LanguagesModel {
                    id: languageModel
                }

                onActivated: {
                    var localeID = languageModel.localeID(index)
                    uiSettings.write("language", localeID)
                    restartBubble.displayed = true
                    bubbleResetTimer.start()
                }

                Bubble {
                    id: restartBubble
                    target: languageBox
                    text: qsTr("Restart Speek to apply changes")
                    displayed: false
                    horizontalAlignment: Qt.AlignRight

                    Timer {
                        id: bubbleResetTimer
                        interval: 3000
                        onTriggered: restartBubble.displayed = false
                    }
                }
                Accessible.role: Accessible.ComboBox
                //: Name of the combobox used to select UI langauge for accessibility tech like screen readers
                Accessible.name: qsTr("Language")
                //: Description of what the language combox is for for accessibility tech like screen readers
                Accessible.description: qsTr("What language Speek will use")
            }
            Item{width:5;height:1}
        }

        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
        }
    }
}
