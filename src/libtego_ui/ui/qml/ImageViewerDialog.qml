import QtQuick 2.2
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0

ApplicationWindow {
    id: imageViewerDialog
    width: image.width > 3400 ? 3400 : image.width
    height: image.height > 1600 ? 1600 : image.height
    flags: styleHelper.dialogWindowFlags
    modality: Qt.WindowModal
    title: mainWindow.title

    property string imageData

    signal closed
    onVisibleChanged: if (!visible) closed()

    function close() {
        visible = false
    }

    ColumnLayout {
        Rectangle {
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
        onTriggered: addContactWindow.close()
    }

    Action {
        shortcut: "Escape"
        onTriggered: addContactWindow.close()
    }
}