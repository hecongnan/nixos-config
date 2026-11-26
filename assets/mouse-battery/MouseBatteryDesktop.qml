import QtQuick
import qs.Common
import qs.Modules.Plugins

DesktopPluginComponent {
    id: root

    minWidth: implicitWidth
    minHeight: implicitHeight
    implicitWidth: indicator.implicitWidth + 2 * Theme.spacingL
    implicitHeight: Math.max(48, indicator.implicitHeight + 2 * Theme.spacingS)
    readonly property real defaultWidth: implicitWidth
    readonly property real defaultHeight: implicitHeight
    readonly property bool resizable: false

    Rectangle {
        anchors.fill: parent
        radius: Math.min(Theme.cornerRadius, height / 2)
        color: Theme.surface

        MouseBatteryIndicator {
            id: indicator
            anchors.centerIn: parent
            iconSize: Theme.fontSizeXLarge
            textSize: Theme.fontSizeLarge
        }
    }
}
