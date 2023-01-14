import QtQuick 2.0
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.0
import im.ricochet 1.0

Column {
    id: setup
    spacing: 8

    property alias proxyType: proxyTypeField.selectedType
    property alias proxyAddress: proxyAddressField.text
    property alias proxyPort: proxyPortField.text
    property alias proxyUsername: proxyUsernameField.text
    property alias proxyPassword: proxyPasswordField.text
    property alias allowedPorts: allowedPortsField.text
    property alias bridgeType: bridgeTypeField.selectedType
    property alias bridgeStrings: bridgeStringsField.text

    function init() {
        let config = torControl.getConfiguration();

        if (config.proxy)
        {
            if(config.proxy.type === "socks4")
                proxyTypeField.currentIndex = 1
            else if(config.proxy.type === "socks5")
                proxyTypeField.currentIndex = 2
            else if(config.proxy.type === "https")
                proxyTypeField.currentIndex = 3
            else
                proxyTypeField.currentIndex = 0

            proxyAddress = config.proxy.address ? config.proxy.address : ''
            proxyPort = config.proxy.port ? config.proxy.port : ''
            proxyUsername = config.proxy.username ? config.proxy.username : ''
            proxyPassword = config.proxy.password ? config.proxy.password : ''
        }
        else
        {
            proxyTypeField.currentIndex = 0
            proxyAddress = ''
            proxyPort = ''
            proxyUsername = ''
            proxyPassword = ''
        }

        allowedPorts = config.allowedPorts ? config.allowedPorts.join(',') : ''

        if (config.bridgeType == "custom"){
            bridgeTypeField.currentIndex = 1
            bridgeStrings = config.bridgeStrings ? config.bridgeStrings.join('\n') : ''
        }
        else{
            let bridgeTypeIndex = torControl.getBridgeTypes().indexOf(config.bridgeType)
            if (bridgeTypeIndex == -1){
                bridgeTypeField.currentIndex = 0
            }
            else{
                bridgeTypeField.currentIndex = 2 + bridgeTypeIndex
            }
            bridgeStrings = ""
        }
    }

    function save() {
        var conf = {}
        conf.disableNetwork = 0
        conf.proxy = {}
        conf.proxy.type = proxyType
        conf.proxy.address = proxyAddress
        conf.proxy.port = parseInt(proxyPort)
        conf.proxy.username = proxyUsername
        conf.proxy.password = proxyPassword
        conf.allowedPorts = (() => {
            const portStrings = allowedPorts.trim().split(',')
            const portInts = portStrings.map(p => parseInt(p))
            const validPortInts = portInts.filter(x => x > 0 && x < 65536)
            const uniquePorts = [...new Set(validPortInts)].sort((a,b) => a - b)
            return uniquePorts
        })();
        conf.bridgeType = bridgeType
        if (bridgeType == "custom") {
            conf.bridgeStrings = bridgeStrings.split('\n').map(x => x.trim()).filter(x => x.length > 0)
        }

        let command = torControl.setConfiguration(conf);
        if (command != null) {
            command.finished.connect(function(successful) {
                if (successful) {
                    window.back()
                } else
                    console.log("SETCONF error:", command.errorMessage)
             });
        }
    }

    GroupBox {
        width: setup.width
        title: "Proxy"

        GridLayout {
            anchors.fill: parent
            columns: 2

            Label {
                text: qsTr("Type:")
                color: proxyPalette.text
            }
            ComboBox {
                id: proxyTypeField
                model: [
                    { "text": qsTr("None"), "type": "none" },
                    { "text": "SOCKS 4", "type": "socks4" },
                    { "text": "SOCKS 5", "type": "socks5" },
                    { "text": "HTTPS", "type": "https" },
                ]
                textRole: "text"
                property string selectedType: currentIndex >= 0 ? model[currentIndex].type : ""

                SystemPalette {
                    id: proxyPalette
                    colorGroup: setup.proxyType == "none" ? SystemPalette.Disabled : SystemPalette.Active
                }

                Component.onCompleted: {
                    if(Qt.platform.os !== "android"){
                        contentItem.color = palette.text
                        indicator.color = palette.text
                    }
                }

                Accessible.role: Accessible.ComboBox
                Accessible.name: selectedType
                //: Description used by accessibility tech, such as screen readers
                Accessible.description: qsTr("If you need a proxy to access the internet, select one from this list.")
            }

            Label {
                //: Label indicating the textbox to place a proxy IP or URL
                text: qsTr("Address:")
                color: proxyPalette.text

                Accessible.role: Accessible.StaticText
                Accessible.name: text
            }
            RowLayout {
                Layout.fillWidth: true
                TextField {
                    id: proxyAddressField
                    Layout.fillWidth: true
                    enabled: setup.proxyType
                    //: Placeholder text of text box expecting an IP or URL for proxy
                    placeholderText: qsTr("IP address or hostname")

                    Accessible.role: Accessible.EditableText
                    Accessible.name: placeholderText
                    //: Description of what to enter into the IP textbox, used by accessibility tech such as screen readers
                    Accessible.description: qsTr("Enter the IP address or hostname of the proxy you wish to connect to")
                }
                Label {
                    //: Label indicating the textbox to place a proxy port
                    text: qsTr("Port:")
                    color: proxyPalette.text

                }
                TextField {
                    id: proxyPortField
                    Layout.preferredWidth: 50
                    enabled: setup.proxyType
                    validator: RegExpValidator{regExp: /^[0-9/]+$/}

                    Accessible.role: Accessible.EditableText
                    //: Name of the port label, used by accessibility tech such as screen readers
                    Accessible.name: qsTr("Port")
                    //: Description of what to enter into the Port textbox, used by accessibility tech such as screen readers
                    Accessible.description: qsTr("Enter the port of the proxy you wish to connect to")
                }
            }

            Label {
                //: Label indicating the textbox to place the proxy username
                text: qsTr("Username:")
                color: proxyPalette.text

                Accessible.role: Accessible.StaticText
                Accessible.name: text
            }
            RowLayout {
                Layout.fillWidth: true

                TextField {
                    id: proxyUsernameField
                    Layout.fillWidth: true
                    enabled: setup.proxyType
                    //: Textbox placeholder text indicating the field is not required
                    placeholderText: qsTr("Optional")

                    Accessible.role: Accessible.EditableText
                    //: Name of the username label, used by accessibility tech such as screen readers
                    Accessible.name: qsTr("Username")
                    //: Description to enter into the Username textbox, used by accessibility tech such as screen readers
                    Accessible.description: qsTr("If required, enter the username for the proxy you wish to connect to")
                }
                Label {
                    //: Label indicating the textbox to place the proxy password
                    text: qsTr("Password:")
                    color: proxyPalette.text

                    Accessible.role: Accessible.StaticText
                    Accessible.name: text
                }
                TextField {
                    id: proxyPasswordField
                    Layout.fillWidth: true
                    enabled: setup.proxyType
                    //: Textbox placeholder text indicating the field is not required
                    placeholderText: qsTr("Optional")

                    Accessible.role: Accessible.EditableText
                    //: Name of the password label, used by accessibility tech such as screen readers
                    Accessible.name: qsTr("Password")
                    //: Description to enter into the Password textbox, used by accessibility tech such as screen readers
                    Accessible.description: qsTr("If required, enter the password for the proxy you wish to connect to")
                }
            }
        }
    }

    Item { height: 4; width: 1 }

    GroupBox {
        width: parent.width
        // Workaround OS X visual bug
        height: Math.max(implicitHeight, 40)
        title: "Firewall"

        /* without this the top of groupbox clips into the first row */
        ColumnLayout {
            anchors.fill: parent

            RowLayout {
                Label {
                    //: Label indicating the textbox to place the allowed ports
                    text: qsTr("Allowed ports:")

                    Accessible.role: Accessible.StaticText
                    Accessible.name: text
                }
                TextField {
                    id: allowedPortsField
                    Layout.fillWidth: true
                    //: Textbox showing an example entry for the firewall allowed ports entry
                    placeholderText: qsTr("Example: 80,443")
                    validator: RegExpValidator{regExp: /^[0-9, /]+$/}

                    Accessible.role: Accessible.EditableText
                    //: Name of the allowed ports label, used by accessibility tech such as screen readers
                    Accessible.name: qsTr("Allowed ports") // todo: translations
                    Accessible.description: placeholderText
                }
            }
        }
    }

    Item { height: 4; width: 1 }

    GroupBox {
        width: parent.width
        title: "Bridges"

        Column {
            anchors.fill: parent
            width: parent.width
            // Stuffing the row layout into a column layout and inserting a bogus
            // item prevents clipping on linux
            Item { height: Qt.platform.os === "linux" ? 15 : 0 }

            RowLayout {
                Layout.fillWidth: true

                Label {
                    text: qsTr("Type:")
                }

                ComboBox {
                    // Displays the selection of a bridge type (obfs4, meek-azure, etc)
                    id: bridgeTypeField
                    model: ListModel {
                        id: bridgeTypeModel
                        ListElement { text: qsTr("None"); type: "none" }
                        ListElement { text: qsTr("Custom"); type: "custom" }
                        Component.onCompleted: {
                            var bridgeTypes = torControl.getBridgeTypes();
                            for (var i = 0; i < bridgeTypes.length; i++)
                            {
                                // Dynamically construct the list model so that whenever
                                // new bridge types are introduced, they'll automatically
                                // propogate to the dropdown
                                bridgeTypeModel.append({text: bridgeTypes[i], type: bridgeTypes[i]});
                            }
                        }
                    }
                    textRole: "text"

                    property string selectedType: currentIndex >= 0 ? model.get(currentIndex).type : ""

                    SystemPalette {
                        id: bridgePalette
                        colorGroup: setup.bridgeType == "" ? SystemPalette.Disabled : SystemPalette.Active
                    }

                    Component.onCompleted: {
                        if(Qt.platform.os !== "android"){
                            contentItem.color = palette.text
                            indicator.color = palette.text
                        }
                    }

                    Accessible.role: Accessible.ComboBox
                    Accessible.name: selectedType
                    //: Description used by accessibility tech, such as screen readers
                    Accessible.description: qsTr("If you need a bridge to access Tor, select one from this list.")
                }
            }

            Label {
                visible: setup.bridgeType == "custom"
                text: qsTr("Enter one or more bridge relays (one per line):")
                width: parent.width
                wrapMode: Text.Wrap

                Accessible.role: Accessible.StaticText
                Accessible.name: text
            }

            ScrollView {
                width: parent.width
                height: allowedPortsField.height * 4;
                visible: setup.bridgeType == "custom"
                background: Rectangle { color: palette.base;radius:4;visible:Qt.platform.os !== "android" }

                TextArea {
                    id: bridgeStringsField
                    wrapMode: TextEdit.NoWrap
                    textFormat: TextEdit.PlainText
                    anchors.fill: parent

                    Accessible.name: qsTr("Enter one or more bridge relays (one per line):")
                    Accessible.role: Accessible.EditableText
                }
            }
        }
    }

    RowLayout {
        width: parent.width

        Button {
            //: Button label for going back to previous screen
            text: qsTr("Back")
            onClicked: window.back()
            Component.onCompleted: {if(Qt.platform.os !== "android")contentItem.color = palette.text}

            Accessible.name: text
            Accessible.onPressAction: window.back()
        }

        Item { height: 1; Layout.fillWidth: true }

        Button {
            //: Button label for connecting to tor
            text: qsTr("Save")
            enabled: (torControl.status == TorControl.Connected) && (setup.proxyType == "none" ? true : (proxyAddressField.text && (() => {const p = parseInt(proxyPortField.text); return p > 0 && p < 65536;})()))
            onClicked: {
                setup.save()
            }

            //palette.buttonText seems broken (see https://bugreports.qt.io/browse/QTBUG-79881)
            contentItem: Label {
                text: parent.text
                color: palette.text
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Accessible.name: text
            Accessible.onPressAction: setup.save()
        }
    }
}
