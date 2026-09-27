import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import qs.Commons
import qs.Ui
import "PresenceModel.js" as Model

// One device's status icon inside the merged Bluetooth Status bar widget.
// Reuses the per-device BarWidget.qml logic from the standalone om.bt-*
// plugins, parameterized by settings key prefix (slotKey) and icon
// filename fragment (iconType) instead of being duplicated four times.
Item {
  id: root

  property QtObject bar: null
  property var settings: ({})
  property string statusStyle: "color"
  property string slotKey: ""
  property string iconType: ""
  property string defaultIcon: ""
  property string defaultLabel: ""

  function slotSetting(name, fallback) {
    var value = settings ? settings[slotKey + name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  readonly property string boundAddress: String(slotSetting("Address", "") || "").trim()
  readonly property string iconGlyph: {
    var icon = String(slotSetting("Icon", root.defaultIcon) || "").trim()
    return icon !== "" ? icon : root.defaultIcon
  }
  readonly property string iconFamily: {
    var family = String(slotSetting("IconFamily", "glyph") || "glyph")
    return ["a", "b", "c"].indexOf(family) >= 0 ? family : "glyph"
  }
  readonly property url imageSource: iconFamily === "glyph" ? "" : Qt.resolvedUrl("icons/Menu" + iconFamily.toUpperCase() + root.iconType
    + ((statusStyle === "shape" || statusStyle === "monochrome") && isConfigured ? (isConnected ? "Filled" : "Outline") : "") + ".png")
  readonly property bool showWhenDisconnected: slotSetting("ShowWhenDisconnected", true) !== false

  readonly property var devices: Bluetooth.devices ? Bluetooth.devices.values : []
  readonly property var matchedDevice: Model.matchDevice(devices, boundAddress)
  readonly property var snapshot: Model.deviceSnapshot(matchedDevice)
  readonly property bool isConfigured: Model.normalizedAddress(boundAddress) !== ""
  readonly property bool isConnected: !!snapshot.connected
  readonly property string displayName: snapshot.name !== "" ? snapshot.name : root.defaultLabel

  // True once the bound address stops resolving to any known device (the
  // usual sign the device was forgotten and re-paired under a new address).
  readonly property bool needsRebind: Model.needsRebind(boundAddress, devices)
  // The plugin ships its own copy of the helper CLI (no global install to
  // fall back on, and migration removes the old one), so it's invoked by
  // absolute path under this plugin's own config directory.
  readonly property string rebindHelperPath: Quickshell.env("HOME") + "/.config/omarchy/plugins/redeye1011.bluetooth-status/bin/omarchy-bt-widgets"

  readonly property color themeGreen: {
    var fromFile = String(themeGreenFile.green || "").trim()
    return Model.isHexColor(fromFile) ? fromFile : "#4caf50"
  }
  readonly property color statusColor: {
    if (!isConfigured) return Color.muted
    if (statusStyle === "monochrome") return isConnected ? "#000000" : Color.foreground
    if (statusStyle === "shape") return iconFamily === "glyph" && !isConnected ? Color.muted : Color.foreground
    return isConnected ? themeGreen : Color.urgent
  }

  readonly property string tip: Model.tooltipText(snapshot, displayName, isConfigured)

  visible: showWhenDisconnected || isConnected
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // Theme green is not a Color singleton role; read it from the active theme palette.
  FileView {
    id: themeGreenFile
    property string green: ""
    path: Color.currentThemePath + "/colors.toml"
    watchChanges: true
    onFileChanged: themeGreenFile.reload()
    onLoaded: {
      var match = String(themeGreenFile.text()).match(/^\s*green\s*=\s*["']?(#[0-9A-Fa-f]{6})/m)
      themeGreenFile.green = match ? match[1] : ""
    }
  }

  function openBluetoothPanel() {
    if (root.bar) root.bar.run("omarchy-shell shell toggle omarchy.bluetooth")
  }

  // Ask the helper CLI to find and rebind this slot to a new address once
  // the old one stops resolving. Guarded by rebindProcess.running (not a
  // permanent latch) plus a short cooldown after each exit, so overlapping
  // launches can't stack but a replacement device that pairs after a failed
  // first attempt still gets picked up on the next devices-list change.
  function checkRebind() {
    if (!root.needsRebind || rebindProcess.running || rebindCooldown.running) return
    rebindProcess.command = [root.rebindHelperPath, "rebind", root.slotKey]
    rebindProcess.running = true
  }

  Process {
    id: rebindProcess
    onExited: rebindCooldown.restart()
  }

  Timer {
    id: rebindCooldown
    // ponytail: fixed cooldown between rebind attempts rather than
    // exponential backoff; revisit if a persistently offline adapter makes
    // this call the helper too often.
    interval: 4000
    onTriggered: root.checkRebind()
  }

  Component.onCompleted: checkRebind()
  onNeedsRebindChanged: checkRebind()
  onDevicesChanged: checkRebind()
  onBarChanged: checkRebind()

  Rectangle {
    anchors.centerIn: button
    width: 20
    height: 18
    radius: 4
    visible: root.isConfigured && root.statusStyle === "monochrome"
    color: root.isConnected ? "#ffffff" : "transparent"
    border.width: root.isConnected ? 1 : 1.5
    border.color: root.isConnected ? Color.muted : Color.foreground
  }

  Component {
    id: artwork
    Item {
      Image {
        id: asset
        anchors.centerIn: parent
        width: root.statusStyle === "shape" ? 18 : root.statusStyle === "monochrome" ? 14 : 17
        height: root.statusStyle === "shape" ? 16 : root.statusStyle === "monochrome" ? 12 : 15
        source: root.imageSource
        fillMode: Image.PreserveAspectFit
        sourceSize.width: Math.round(width * Screen.devicePixelRatio)
        sourceSize.height: Math.round(height * Screen.devicePixelRatio)
        visible: false
        layer.enabled: true
      }
      ColorOverlay {
        anchors.fill: asset
        source: asset
        color: root.statusColor
      }
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.iconGlyph
    iconComponent: root.iconFamily === "glyph" ? null : artwork
    opticalSize: root.iconFamily === "glyph" ? Style.bar.iconCanvas : 20
    tooltipText: root.tip
    keepSpace: root.showWhenDisconnected
    useActiveColor: false
    foreground: root.statusColor
    pressable: true
    interactive: true
    onPressed: root.openBluetoothPanel()

    Behavior on foreground {
      ColorAnimation { duration: 160; easing.type: Easing.OutCubic }
    }
  }
}
