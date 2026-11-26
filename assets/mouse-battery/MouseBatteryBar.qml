pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Modules.Plugins

PluginComponent {
    id: root

    horizontalBarPill: Component {
        MouseBatteryIndicator {
            iconSize: root.iconSize
            textSize: root.textSize
            foreground: Theme.widgetTextColor
        }
    }

    verticalBarPill: Component {
        MouseBatteryIndicator {
            vertical: true
            iconSize: root.iconSize
            textSize: root.textSize
            foreground: Theme.widgetTextColor
            availableTextWidth: Math.max(1, root.widgetThickness - Theme.spacingXS)
        }
    }
}
