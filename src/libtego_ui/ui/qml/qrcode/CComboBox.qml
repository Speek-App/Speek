import QtQuick 2.0
import QtQuick.Controls 2.12

ComboBox {
  background: Rectangle {
    radius: 2
    implicitWidth: settings.width
    implicitHeight: settings.height / 8
    border {
      color: "#333"
      width: 1
    }
  }
}
