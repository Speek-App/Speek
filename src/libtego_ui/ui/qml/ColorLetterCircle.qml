import QtQuick 2.5
import QtQuick.Controls 1.0
import im.utility 1.0
import im.ricochet 1.0

Rectangle {
    //property var color_circle1: ["#fff163","#fff585","#fff9a4","#ffe4c6","#ff67bf","#ff59a2","#ff2093","#ffad62","#ff8057","#fff9a4"]
    //property var color_circle2: ["#ffe573","#fff062","#ffba68","#ff9575","#ff7986","#ff64b5","#ff4fc3","#ff4dd0","#ff4db6","#ff81c7"]

    Utility {
       id: utility
    }

    property var name

    id: colorLetterCircle
    width: 48
    height: 48
    color:"transparent"
    //radius: 360
    //color: color_circle2[name.length > 0 ? (name.charCodeAt(0) + name.charCodeAt(name.length-1))%10 : ""]

    Image {
        height: parent.height
        width: parent.width
        anchors.fill: parent
        source: {
            var file_path1 = ":/icons/icons_letter/" + name.charAt(0) + ".png";
            var file_path2 = ":/icons/icons_letter/ASCII-" + name.charCodeAt(0) + ".png";
            if(utility.checkFileExists(file_path1))
                return "qrc" + file_path1
            else if(utility.checkFileExists(file_path2))
                return "qrc" + file_path2
            else
                return "qrc:/icons/icons_letter/ASCII-63.png";
        }
        smooth: true
    }

/*
    Label {
        //anchors.horizontalCenter: parent.horizontalCenter
        //anchors.verticalCenter: parent.verticalCenter
        font.pointSize: 24
        font.bold: true
        anchors.leftMargin: (44 - paintedWidth) / 2
        anchors.topMargin: -1
        //anchors.centerIn: colorLetterCircle
        anchors.fill: parent
        id: label
        text: name.length > 0 ? name.charAt(0) : ""

        color: "white"
    }*/
}
