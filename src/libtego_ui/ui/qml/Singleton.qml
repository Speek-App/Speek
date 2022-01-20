pragma Singleton
import QtQuick 2.0

Item {
    property FontLoader EmojiFont: FontLoader {
        source: "qrc:/fonts/NotoColorEmoji.ttf"
        Component.onCompleted: console.log(name)
    }
}
