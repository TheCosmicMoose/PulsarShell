import QtQuick
import "../../theme"

// A clickable row: glyph, title, optional subtitle and right-hand text.
// Anything declared inside a ListRow goes into an area under the row that is
// shown while `expanded` is true (used for Connect/Disconnect buttons etc.):
//
//   ListRow {
//       title: "My headphones"
//       expanded: someCondition
//       onClicked: ...
//       FlyoutButton { text: "Disconnect" }
//   }
Rectangle {
    id: row

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property string trailing: ""
    property color iconColor: Theme.textPrimary
    property bool active: false         // highlight, e.g. the connected network
    property bool expanded: false
    default property alias content: extra.data

    signal clicked()

    implicitHeight: column.implicitHeight + 12
    radius: Theme.barButtonRadius
    color: hover.hovered || expanded ? Theme.bgModule : "transparent"

    HoverHandler { id: hover }

    Column {
        id: column
        x: 8
        y: 6
        width: parent.width - 16
        spacing: 8

        Item {
            id: header
            width: parent.width
            height: Math.max(glyph.implicitHeight, texts.implicitHeight)

            Text {
                id: glyph
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: row.icon === "" ? 0 : 24
                horizontalAlignment: Text.AlignHCenter
                text: row.icon
                color: row.active ? Theme.accentBlue : row.iconColor
                font.family: Theme.fontFamily
                font.pointSize: Theme.fontSizeLarge
            }

            Column {
                id: texts
                anchors.left: glyph.right
                anchors.leftMargin: row.icon === "" ? 0 : 10
                anchors.right: trailingText.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: row.title
                    color: row.active ? Theme.accentBlue : Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.fontSizePrimary
                    font.bold: row.active
                }

                Text {
                    width: parent.width
                    visible: text !== ""
                    elide: Text.ElideRight
                    text: row.subtitle
                    color: Theme.textBg
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.fontSizeSmall
                }
            }

            Text {
                id: trailingText
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: row.trailing
                color: Theme.textBg
                font.family: Theme.fontFamily
                font.pointSize: Theme.fontSizeSmall
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: row.clicked()
            }
        }

        Column {
            id: extra
            width: parent.width
            spacing: 8
            visible: row.expanded
        }
    }
}
