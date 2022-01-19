import QtQuick 2.5
import QtQuick.Controls 1.0
import im.ricochet 1.0

Rectangle {
    property var color_circle1: ["#fff163","#fff585","#fff9a4","#ffe4c6","#ff67bf","#ff59a2","#ff2093","#ffad62","#ff8057","#fff9a4"]
    property var color_circle2: ["#ffe573","#fff062","#ffba68","#ff9575","#ff7986","#ff64b5","#ff4fc3","#ff4dd0","#ff4db6","#ff81c7"]
    property var name

    id: colorLetterCircle
    width: 44
    height: 44
    radius: 360
    color: color_circle2[name.length > 0 ? (name.charCodeAt(0) + name.charCodeAt(name.length-1))%10 : ""]


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
    }
}
