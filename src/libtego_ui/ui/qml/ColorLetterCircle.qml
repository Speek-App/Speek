import QtQuick 2.0
import QtQuick.Controls 1.0
import im.utility 1.0
import im.ricochet 1.0

Rectangle {
    Utility {
       id: utility
    }

    property var name
    property var icon

    id: colorLetterCircle
    width: 48
    height: 48
    color:"transparent"


    Image {
        height: parent.height
        width: parent.width
        anchors.fill: parent
        source: {
            if(icon == ""){
                var file_path1 = ":/icons/icons_letter/" + name.charAt(0) + ".png";
                var file_path2 = ":/icons/icons_letter/ASCII-" + name.charCodeAt(0) + ".png";
                if(utility.checkFileExists(file_path1))
                    return "qrc" + file_path1
                else if(utility.checkFileExists(file_path2))
                    return "qrc" + file_path2
                else
                    return "qrc:/icons/icons_letter/ASCII-63.png";
            }
            else{
                return "image://base64/" + icon;
            }
        }
        smooth: true
    }
}
