import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.0

ApplicationWindow {
    id: imageViewerDialog
    width: Qt.platform.os == "android" ? undefined : image.width > 3400 ? 3400 : image.width
    height: Qt.platform.os == "android" ? undefined : image.height > 1600 ? 1600 : image.height
    flags: Qt.platform.os == "android" ? undefined : Qt.Window
    modality: Qt.NonModal
    title: mainWindow.title

    property string imageData

    signal closed
    onVisibleChanged: if (!visible) closed()

    function close() {
        visible = false
    }
    color: palette.window

    ColumnLayout {
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            color: "transparent"
            Image {
                id: image
                source: "image://base64n/" + imageData
                smooth: true
                antialiasing: true
            }
        }
    }

    Action {
        shortcut: StandardKey.Close
        onTriggered: imageViewerDialog.close()
    }

    Action {
        shortcut: "Escape"
        onTriggered: imageViewerDialog.close()
    }
}
