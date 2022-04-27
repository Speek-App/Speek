import QtQuick 2.0
import QtQuick.Controls 1.0
import im.utility 1.0
import im.ricochet 1.0

Rectangle {
    Utility {
       id: utility
    }

    property var name
    property var hash: ""
    property var icon

    id: colorLetterCircle
    width: 48
    height: 48
    color:"transparent"


    Image {
        height: parent.height
        width: parent.width
        sourceSize.height: parent.height
        sourceSize.width: parent.width
        anchors.fill: parent
        source: {
            if(hash === ""){
                if(icon == "" || typeof(icon) === "undefined"){
                    if(typeof(name) === "undefined"){
                        return "";
                    }
                    var icon_size = width > 96 ? "512" : "96"
                    var file_path = ":/icons/icons_letter/" + icon_size + "/ASCII-" + name.charCodeAt(0) + ".png";
                    if(utility.checkFileExists(file_path))
                        return "qrc" + file_path
                    else
                        return "qrc:/icons/icons_letter/" + icon_size +"/ASCII-63.png";
                }
                else{
                    return "image://base64/" + icon;
                }
            }
            else{
                return "image://jazzicon/" + hash
            }
        }
        smooth: true
    }
}
