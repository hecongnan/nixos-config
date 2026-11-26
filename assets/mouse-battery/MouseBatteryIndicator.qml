import QtQuick
import Quickshell.Io
import Quickshell.Services.UPower
import qs.Common
import qs.DCommon.Widgets

Grid {
    id: root

    property int iconSize: Theme.fontSizeLarge
    property int textSize: Theme.fontSizeMedium
    property color foreground: Theme.surfaceText
    property bool vertical: false
    property real availableTextWidth: Math.ceil(levelMetrics.advanceWidth)

    readonly property var mouse: UPower.devices.values.find(device =>
        device.ready && device.type === UPowerDeviceType.Mouse && device.isPresent
        && device.percentage >= 0 && device.percentage <= 1)
    property int receiverPercentage: -1
    property bool receiverStale: true
    readonly property int percentage: mouse ? Math.round(mouse.percentage * 100) : receiverPercentage
    readonly property string percentageText: percentage >= 0 ? percentage + "%" : "—"
    readonly property bool showingCached: !mouse && receiverPercentage >= 0 && receiverStale

    columns: vertical ? 1 : 2
    columnSpacing: Theme.spacingXS
    rowSpacing: 2
    horizontalItemAlignment: Grid.AlignHCenter
    verticalItemAlignment: Grid.AlignVCenter

    Accessible.role: Accessible.StaticText
    Accessible.name: {
        if (percentage < 0)
            return qsTr("鼠标电量不可用");
        if (showingCached)
            return qsTr("鼠标上次电量 %1").arg(percentageText);
        return qsTr("%1 电量 %2").arg(mouse?.model || qsTr("鼠标")).arg(percentageText);
    }

    function updateReceiverReading(line) {
        const [state, value] = line.trim().split(" ");
        if (state === "disconnected") {
            receiverPercentage = -1;
            receiverStale = true;
        } else if (state === "stale") {
            receiverStale = true;
        } else if (/^(0|[1-9][0-9]?|100)$/.test(value)
                && (state === "current" || (state === "cached" && receiverPercentage < 0))) {
            receiverPercentage = Number(value);
            receiverStale = state === "cached";
        }
    }

    Timer {
        interval: 60000
        running: !root.mouse
        repeat: true
        triggeredOnStart: true
        onTriggered: receiverQuery.running = true
    }

    Process {
        id: receiverQuery

        command: ["@bash@",
            decodeURIComponent(Qt.resolvedUrl("read-logitech-battery.sh").toString().slice("file://".length))]
        stdout: SplitParser {
            onRead: line => root.updateReceiverReading(line)
        }
        onExited: exitCode => {
            if (exitCode !== 0)
                root.receiverStale = true;
        }
    }

    DIcon {
        name: "mouse"
        size: root.iconSize
        color: root.foreground
        Accessible.ignored: true
    }

    TextMetrics {
        id: levelMetrics
        font: levelLabel.font
        text: "100%"
    }

    Text {
        id: levelLabel

        width: Math.min(Math.ceil(levelMetrics.advanceWidth), root.availableTextWidth)
        text: root.percentageText
        color: root.foreground
        opacity: root.showingCached ? 0.6 : 1
        font.family: Theme.fontFamily
        font.pixelSize: root.textSize
        font.weight: Theme.fontWeightMedium
        font.features: ({ "tnum": 1 })
        fontSizeMode: root.vertical ? Text.HorizontalFit : Text.FixedSize
        minimumPixelSize: 8
        horizontalAlignment: root.vertical ? Text.AlignHCenter : Text.AlignLeft
        Accessible.ignored: true
    }
}
