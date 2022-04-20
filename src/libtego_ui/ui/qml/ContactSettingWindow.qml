import QtQuick 2.2
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.0
import im.ricochet 1.0
import QtQuick.Controls.Styles 1.4

ApplicationWindow {
    id: contactPreferencesWindow
    width: 900
    minimumWidth: 820
    height: 420
    minimumHeight: 420
    title: qsTr("Speek Preferences")

    signal closed
    onVisibleChanged: if (!visible) closed()

    function close() {
        visible = false
    }

    property var selectedContact

    color: palette.window

    ContactPreferences{
        anchors.fill: parent
        selectedContact: contactPreferencesWindow.selectedContact
        Component.onCompleted: {
            selectedContact = contactPreferencesWindow.selectedContact
        }
    }


    Action {
        shortcut: StandardKey.Close
        onTriggered: contactPreferencesWindow.close()
    }

    Action {
        shortcut: "Escape"
        onTriggered: contactPreferencesWindow.close()
    }
}
