import QtQuick
import qs.Commons
import qs.Ui
import "IconOrder.js" as Order

// Single bar slot for the four tracked Bluetooth devices (speaker, earbuds,
// mouse, keyboard). Each SlotIcon is independently hideable through its own
// {slot}ShowWhenDisconnected setting (reusing the standalone om.bt-* widget
// logic per slot); when all four are hidden this still shows a small setup
// button so the plugin's own settings panel stays reachable.
BarWidget {
  id: root
  moduleName: "redeye1011.bluetooth-status"

  readonly property string statusStyle: String(setting("statusStyle", "color") || "color")
  readonly property var iconOrder: Order.normalize(setting("iconOrder", ""))
  readonly property bool anySlotVisible: {
    var count = iconRepeater.count
    for (var i = 0; i < count; i++) {
      var icon = iconRepeater.itemAt(i)
      if (icon && icon.visible) return true
    }
    return false
  }

  function openSettingsPanel() {
    if (root.bar) root.bar.run("omarchy-shell shell toggle redeye1011.bluetooth-status")
  }

  implicitWidth: grid.implicitWidth
  implicitHeight: grid.implicitHeight

  Grid {
    id: grid
    anchors.centerIn: parent
    rows: root.vertical ? 5 : 1
    columns: root.vertical ? 1 : 5
    rowSpacing: Style.space(4)
    columnSpacing: Style.space(4)

    Repeater {
      id: iconRepeater
      model: root.iconOrder
      delegate: SlotIcon {
        required property string modelData
        bar: root.bar
        settings: root.settings
        statusStyle: root.statusStyle
        slotKey: modelData
        iconType: ({speaker: "Speaker", earbuds: "Headphones", mouse: "Mouse", keyboard: "Keyboard"})[modelData]
        defaultIcon: ({speaker: "󰓃", earbuds: "󰋎", mouse: "󰍽", keyboard: "󰌌"})[modelData]
        defaultLabel: modelData[0].toUpperCase() + modelData.slice(1)
      }
    }

    BarIconButton {
      id: setupButton
      bar: root.bar
      text: "󰂯"
      opticalSize: Style.bar.iconCanvas
      tooltipText: "Bluetooth Status · open settings"
      useActiveColor: false
      foreground: Color.muted
      pressable: true
      interactive: true
      visible: !root.anySlotVisible
      onPressed: root.openSettingsPanel()
    }
  }
}
