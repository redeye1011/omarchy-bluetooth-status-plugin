import QtQuick
import qs.Commons
import qs.Ui

// Single bar slot for the four tracked Bluetooth devices (speaker, earbuds,
// mouse, keyboard). Each SlotIcon is independently hideable through its own
// {slot}ShowWhenDisconnected setting (reusing the standalone om.bt-* widget
// logic per slot); when all four are hidden this still shows a small setup
// button so the plugin's own settings panel stays reachable.
BarWidget {
  id: root
  moduleName: "redeye1011.bluetooth-status"

  readonly property string statusStyle: String(setting("statusStyle", "color") || "color")
  readonly property bool anySlotVisible: speakerIcon.visible || earbudsIcon.visible || mouseIcon.visible || keyboardIcon.visible

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

    SlotIcon {
      id: speakerIcon
      bar: root.bar
      settings: root.settings
      statusStyle: root.statusStyle
      slotKey: "speaker"
      iconType: "Speaker"
      defaultIcon: "󰓃"
      defaultLabel: "Speaker"
    }
    SlotIcon {
      id: earbudsIcon
      bar: root.bar
      settings: root.settings
      statusStyle: root.statusStyle
      slotKey: "earbuds"
      iconType: "Headphones"
      defaultIcon: "󰋎"
      defaultLabel: "Earbuds"
    }
    SlotIcon {
      id: mouseIcon
      bar: root.bar
      settings: root.settings
      statusStyle: root.statusStyle
      slotKey: "mouse"
      iconType: "Mouse"
      defaultIcon: "󰍽"
      defaultLabel: "Mouse"
    }
    SlotIcon {
      id: keyboardIcon
      bar: root.bar
      settings: root.settings
      statusStyle: root.statusStyle
      slotKey: "keyboard"
      iconType: "Keyboard"
      defaultIcon: "󰌌"
      defaultLabel: "Keyboard"
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

