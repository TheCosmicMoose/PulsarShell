pragma ComponentBehavior: Bound
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../theme"

// Carousel of the images in ~/Pictures/Wallpapers, across the middle of the
// screen. The centered one is selected.
//   Left / Right, mouse wheel  -> move
//   click a side image         -> move to it
//   Enter, click the center    -> set it as the wallpaper
//   Escape, click outside      -> close
PanelWindow {
    id: win

    signal dismissed()
    signal chosen(string path)

    // Full width, vertically centered (no top/bottom anchor).
    anchors.left: true
    anchors.right: true
    implicitHeight: 420
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.namespace: "pulsar-wallpaper"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    HyprlandFocusGrab {
        active: true
        windows: [win]
        onCleared: win.dismissed()
    }

    readonly property int cardWidth: 480
    readonly property int cardHeight: 270

    FolderListModel {
        id: images
        folder: "file://" + WallpaperPicker.folder
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.bmp", "*.gif"]
        caseSensitive: false
        showDirs: false
        sortField: FolderListModel.Name

        // Open on the current wallpaper.
        onStatusChanged: {
            if (status !== FolderListModel.Ready || WallpaperPicker.current === "") return
            const i = indexOf("file://" + WallpaperPicker.current)
            if (i >= 0) carousel.currentIndex = i
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.bgPrimary, Theme.alphaBG)
        border.width: 1
        border.color: Theme.accentGray

        Text {
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Wallpaper"
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pointSize: Theme.fontSizeLarge
            font.bold: true
        }

        PathView {
            id: carousel

            anchors.fill: parent
            anchors.topMargin: 40
            anchors.bottomMargin: 50
            model: images
            focus: true

            pathItemCount: Math.min(7, Math.max(1, images.count))
            preferredHighlightBegin: 0.5
            preferredHighlightEnd: 0.5
            highlightRangeMode: PathView.StrictlyEnforceRange
            highlightMoveDuration: Theme.animLong
            snapMode: PathView.SnapToItem

            // Straight line through the middle; side images shrink and fade.
            path: Path {
                startX: -win.cardWidth / 2
                startY: carousel.height / 2
                PathAttribute { name: "itemScale"; value: 0.55 }
                PathAttribute { name: "itemOpacity"; value: 0.4 }
                PathAttribute { name: "itemZ"; value: 0 }
                PathLine { x: carousel.width / 2; y: carousel.height / 2 }
                PathAttribute { name: "itemScale"; value: 1.0 }
                PathAttribute { name: "itemOpacity"; value: 1.0 }
                PathAttribute { name: "itemZ"; value: 10 }
                PathLine { x: carousel.width + win.cardWidth / 2; y: carousel.height / 2 }
                PathAttribute { name: "itemScale"; value: 0.55 }
                PathAttribute { name: "itemOpacity"; value: 0.4 }
                PathAttribute { name: "itemZ"; value: 0 }
            }

            Keys.onPressed: event => {
                switch (event.key) {
                case Qt.Key_Left:
                    carousel.decrementCurrentIndex(); break
                case Qt.Key_Right:
                    carousel.incrementCurrentIndex(); break
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    if (carousel.currentItem) win.chosen(carousel.currentItem.filePath)
                    break
                case Qt.Key_Escape:
                    win.dismissed(); break
                default:
                    return
                }
                event.accepted = true
            }

            Component.onCompleted: forceActiveFocus()

            delegate: Item {
                id: card

                required property int index
                required property string filePath
                required property string fileName
                readonly property bool isCurrent: PathView.isCurrentItem
                readonly property bool isWallpaper: filePath === WallpaperPicker.current

                width: win.cardWidth
                height: win.cardHeight
                scale: PathView.itemScale ?? 1
                opacity: PathView.itemOpacity ?? 1
                z: PathView.itemZ ?? 0

                Rectangle {
                    anchors.fill: parent
                    color: Theme.bgModule
                    border.width: card.isCurrent ? 3 : 1
                    border.color: card.isCurrent ? Theme.accentBlue : Theme.accentGray

                    Image {
                        anchors.fill: parent
                        anchors.margins: parent.border.width
                        source: "file://" + card.filePath
                        // Decode at card size, not the full image size.
                        sourceSize.width: win.cardWidth
                        sourceSize.height: win.cardHeight
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }

                    // Marks the wallpaper in use.
                    Rectangle {
                        visible: card.isWallpaper
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 8
                        width: inUse.implicitWidth + 12
                        height: inUse.implicitHeight + 6
                        radius: Theme.barButtonRadius
                        color: Theme.accentBlue

                        Text {
                            id: inUse
                            anchors.centerIn: parent
                            text: "Current"
                            color: Theme.bgPrimary
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.fontSizeSmall
                            font.bold: true
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (card.isCurrent) win.chosen(card.filePath)
                        else carousel.currentIndex = card.index
                    }
                }
            }
        }

        // Wheel anywhere on the band moves the carousel.
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                const d = event.angleDelta.y !== 0 ? event.angleDelta.y : -event.angleDelta.x
                if (d < 0) carousel.incrementCurrentIndex()
                else if (d > 0) carousel.decrementCurrentIndex()
            }
        }

        // Selected file name, or why there's nothing to show.
        Text {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 18
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 80
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideMiddle
            color: images.count === 0 ? Theme.textBg : Theme.textSecondary
            font.family: Theme.fontFamily
            font.pointSize: Theme.fontSizePrimary
            text: {
                if (images.status === FolderListModel.Loading) return "Loading..."
                if (images.count === 0) return "No images in " + WallpaperPicker.folder
                const name = carousel.currentItem ? carousel.currentItem.fileName : ""
                return name + "    (" + (carousel.currentIndex + 1) + " / " + images.count + ")"
                     + "    ← → to browse, Enter to set"
            }
        }
    }
}
