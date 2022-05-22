import QtQuick 2.2
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.0
import im.ricochet 1.0
import QtQuick.Controls.Styles 1.4

ApplicationWindow {
    id: preferencesWindow
    width: 900
    minimumWidth: 820
    height: 420
    minimumHeight: 420
    title: qsTr("Speek Preferences")
    modality: Qt.WindowModal

    signal closed
    onVisibleChanged: if (!visible) closed()

    property string initialPage
    property var initialPageProperties: { }

    color: palette.window

    Component.onCompleted: {
        if (initialPage != "") {
            initialPage = Qt.resolvedUrl(initialPage)
            for (var i = 0; i < tabs.count; i++) {
                if (tabs.getTab(i).source == initialPage) {
                    tabs.currentIndex = i
                    var item = tabs.getTab(i).item
                    for (var key in initialPageProperties) {
                        item[key] = initialPageProperties[key]
                    }
                }
            }
        }
    }


    PreferencesDialogMain{
        id: tabs
    }

    Action {
        shortcut: StandardKey.Close
        onTriggered: preferencesWindow.close()
    }

    Action {
        shortcut: "Escape"
        onTriggered: preferencesWindow.close()
    }
}
