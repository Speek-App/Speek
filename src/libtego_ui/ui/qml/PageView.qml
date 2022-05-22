import QtQuick 2.0

/* Simple QML view that associates a string key with a page, and
 * displays one page at a time. */

FocusScope {
    property Item currentPage
    property string currentKey
    property var _items: { '': null }

    function add(key, source, properties) {
        if (key === "")
            return
        if (_items[key] !== null)
            remove(key)

        var component = Qt.createComponent(source, content)
        if (component.status !== Component.Ready) {
            console.log("PageView:", source, component.errorString())
            return
        }

        if (properties === undefined)
            properties = [ ]
        properties['visible'] = false
        properties['anchors.fill'] = content

        var item = component.createObject(content, properties)
        _items[key] = item
    }

    function show(key, source, properties) {
        if (_items[key] === undefined)
            add(key, source, properties)
        currentKey = key
    }

    function remove(key) {
        var item = _items[key]
        if (item !== undefined) {
            if (item === currentPage)
                currentKey = null
            _items[key] = undefined
            item.destroy()
        }
    }

    onCurrentKeyChanged: {
        var item = _items[currentKey]
        if (item === currentPage)
            return

        if (currentPage !== null) {
            currentPage.visible = false
            currentPage.focus = false
        }
        currentPage = item || null
        if (currentPage !== null) {
            currentPage.visible = true
            currentPage.focus = true
        }
    }

    Item {
        id: content
        anchors.fill: parent
    }

    Rectangle {
        visible: currentPage != null ? !currentPage.visible : true
        anchors.fill: parent
        color: palette.window
        Image{
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            source: styleHelper.darkMode ? "qrc:/icons/speeklogo-full.png" : "qrc:/icons/speeklogo-full-light.png"
            width:200
            height:200
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
    }
}
