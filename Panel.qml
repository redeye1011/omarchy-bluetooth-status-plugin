import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import qs.Commons

Item {
  id: root
  property var shell: null
  property bool opened: false
  property string page: ""
  property int selectedIndex: 0
  property string actionMessage: ""
  property var settings: ({})
  readonly property string helperPath: Quickshell.env("HOME") + "/.config/omarchy/plugins/redeye1011.bluetooth-status/bin/omarchy-bt-widgets"
  readonly property var widgetEntry: settings["redeye1011.bluetooth-status"] || ({})
  readonly property var devices: Bluetooth.devices ? Bluetooth.devices.values : []
  readonly property var slots: ["speaker", "earbuds", "mouse", "keyboard"]
  readonly property var defaults: ({speaker: "󰓃", earbuds: "󰋎", mouse: "󰍽", keyboard: "󰌌"})
  readonly property var familyNames: ({a: "Classic", b: "Linework", c: "Modern"})
  readonly property var choices: ({speaker: ["󰓃 Omarchy default", "󰕾 Volume", "󰂯 Radio"],
    earbuds: ["󰋎 Omarchy default", "󰥰 Earbuds", "󰂯 Radio"],
    mouse: ["󰍽 Omarchy default", "󰣌 Pointer", "󰂯 Radio"],
    keyboard: ["󰌌 Omarchy default", "󰥻 Keys", "󰂯 Radio"]})
  readonly property var rows: buildRows()
  onRowsChanged: selectedIndex = Math.min(selectedIndex, Math.max(0, rows.length - 1))
  onSelectedIndexChanged: Qt.callLater(function() {
    var row = rowRepeater.itemAt(root.selectedIndex)
    if (!row) return
    if (row.y < rowFlick.contentY) rowFlick.contentY = row.y
    else if (row.y + row.height > rowFlick.contentY + rowFlick.height)
      rowFlick.contentY = row.y + row.height - rowFlick.height
  })

  function entry(slot) {
    var w = widgetEntry
    return {
      address: w[slot + "Address"] || "",
      iconFamily: w[slot + "IconFamily"] || "glyph",
      icon: w[slot + "Icon"] || defaults[slot],
      showWhenDisconnected: w[slot + "ShowWhenDisconnected"] !== false
    }
  }
  function iconFamily(data) { return ["a", "b", "c"].indexOf(data.iconFamily) >= 0 ? data.iconFamily : "glyph" }
  function artworkSource(slot, family, variant) {
    if (!slot || !family) return ""
    var type = ({speaker: "Speaker", earbuds: "Headphones", mouse: "Mouse", keyboard: "Keyboard"})[slot]
    return Qt.resolvedUrl("icons/Menu" + family.toUpperCase() + type + variant + ".png")
  }
  function currentStyle() {
    return widgetEntry.statusStyle || "color"
  }
  function currentFamily() {
    var first = iconFamily(entry(slots[0]))
    for (var i = 0; i < slots.length; i++) {
      var slot = slots[i], fam = iconFamily(entry(slot))
      if (fam !== first) return "Mixed"
      if (fam === "glyph" && entry(slot).icon && entry(slot).icon !== defaults[slot]) return "Mixed"
    }
    return first
  }
  function device(address) {
    for (var i = 0; i < devices.length; i++)
      if (String(devices[i].address || "").toUpperCase() === String(address || "").toUpperCase()) return devices[i]
    return null
  }
  function deviceLabel(d) { return d.deviceName || d.name || d.alias || d.address }
  function title() {
    if (!page) return "Bluetooth Status"
    var parts = page.split(".")
    if (parts[0] === "style") return "Status style"
    if (parts[0] === "icons") return "Icon set"
    return parts[0][0].toUpperCase() + parts[0].slice(1) + (parts[1] ? " · " + parts[1][0].toUpperCase() + parts[1].slice(1) : "")
  }
  function buildRows() {
    var result = []
    if (!page) {
      var style = currentStyle()
      var styleName = ({color: "Red / Green", shape: "Outline / Fill", monochrome: "Monochrome Squares"})[style] || style
      result.push({label: "Status style", detail: styleName, next: "style"})
      var curFam = currentFamily()
      var famName = curFam === "glyph" ? "Omarchy defaults" : (familyNames[curFam] || curFam)
      result.push({label: "Icon set", detail: famName, next: "icons"})
      for (var i = 0; i < slots.length; i++) {
        var slot = slots[i], current = entry(slot), found = device(current.address)
        var state = !current.address ? "Choose a device" : found && found.connected ? "Connected" : "Not connected here"
        result.push({label: slot[0].toUpperCase() + slot.slice(1), detail: state, next: slot})
      }
      result.push({label: "Manage devices", detail: "Omarchy Bluetooth panel", command: ["omarchy-shell", "shell", "summon", "omarchy.bluetooth"]})
    } else if (page === "style") {
      var styles = [["color", "Red / Green", "Green when connected, red when away"],
        ["shape", "Outline / Fill", "Artwork fills when connected; no badge"],
        ["monochrome", "Monochrome Squares", "Filled when connected; outlined when away"]]
      for (var s = 0; s < styles.length; s++)
        result.push({label: styles[s][1] + (currentStyle() === styles[s][0] ? " ✓" : ""),
          detail: styles[s][2],
          command: [root.helperPath, "style", styles[s][0]]})
    } else if (page === "icons") {
      var curFam = currentFamily()
      var families = ["a", "b", "c"]
      for (var f = 0; f < families.length; f++)
        result.push({label: familyNames[families[f]] + (curFam === families[f] ? " ✓" : ""),
          detail: "All 4 devices", previewFamily: families[f],
          command: [root.helperPath, "family", "all", families[f]]})
      result.push({label: "Omarchy defaults" + (curFam === "glyph" ? " ✓" : ""),
        detail: "󰓃  󰋎  󰍽  󰌌  Stock Nerd Font icons",
        command: [root.helperPath, "family", "all", "glyph"]})
    } else {
      var parts = page.split("."), target = parts[0], data = entry(target)
      if (parts.length === 1) {
        var d = device(data.address)
        result.push({label: !data.address ? "Unconfigured" : d && d.connected ? "Connected" : "Not connected here", detail: data.address || "No device selected", command: ["omarchy-shell", "shell", "summon", "omarchy.bluetooth"]})
        result.push({label: "Tracked device", detail: d ? deviceLabel(d) : (data.address || "Choose a paired device"), next: target + ".device"})
        var family = iconFamily(data)
        result.push({label: "Icon", detail: family === "glyph" ? (data.icon || defaults[target]) : familyNames[family], next: target + ".icon"})
        result.push({label: data.showWhenDisconnected === false ? "Show when disconnected" : "Hide when disconnected",
          detail: data.showWhenDisconnected === false ? "Hidden while away" : "Visible while away",
          command: [root.helperPath, "visibility", target]})
      } else if (parts[1] === "icon") {
        var families = ["a", "b", "c"]
        for (var f = 0; f < families.length; f++)
          result.push({label: familyNames[families[f]] + (iconFamily(data) === families[f] ? " ✓" : ""),
            detail: "Base · filled · outlined", previewSlot: target, previewFamily: families[f],
            command: [root.helperPath, "family", target, families[f]]})
        var options = choices[target]
        for (var c = 0; c < options.length; c++) {
          var glyph = options[c].split(" ")[0]
          result.push({label: options[c] + (iconFamily(data) === "glyph" && (data.icon || defaults[target]) === glyph ? " ✓" : ""),
            command: [root.helperPath, "icon", target, glyph]})
        }
      } else if (parts[1] === "device") {
        for (var j = 0; j < devices.length; j++) {
          var choice = devices[j]
          if (!choice.paired) continue
          result.push({label: deviceLabel(choice) + (String(data.address || "").toUpperCase() === String(choice.address).toUpperCase() ? " ✓" : ""),
            detail: choice.address, command: [root.helperPath, "bind", target, choice.address]})
        }
        if (!result.length) result.push({label: "Pair a device in Bluetooth settings", command: ["omarchy-shell", "shell", "summon", "omarchy.bluetooth"]})
      }
    }
    return result
  }
  function navigate(next) { page = next; selectedIndex = 0; rowFlick.contentY = 0; actionMessage = "" }
  function back() {
    if (!page) { dismiss(); return }
    var parts = page.split(".") 
    navigate(parts.length === 1 ? "" : parts[0])
  }
  function activate(index) {
    var row = rows[index]
    if (!row) return
    if (row.next) { navigate(row.next); return }
    if (!row.command) return
    if (row.command[0] === "omarchy-shell") {
      Quickshell.execDetached(row.command)
      dismiss()
    } else if (!settingProcess.running) {
      actionMessage = "Applying…"
      settingProcess.command = row.command
      settingProcess.running = true
    }
  }
  function open(_) {
    page = ""
    selectedIndex = 0
    opened = true
    rowFlick.contentY = 0
    actionMessage = ""
    configFile.reload()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }
  function close() { opened = false }
  function dismiss() {
    opened = false
    if (shell && typeof shell.hide === "function") shell.hide("redeye1011.bluetooth-status")
  }
  function toggle() { if (opened) dismiss(); else open("{}") }

  Process {
    id: settingProcess
    onExited: function(exitCode) {
      configFile.reload()
      root.actionMessage = exitCode === 0 ? "" : "Could not save setting; check the device is paired"
    }
  }

  FileView {
    id: configFile
    path: Quickshell.env("HOME") + "/.config/omarchy/shell.json"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      try {
        var layout = JSON.parse(text()).bar.layout
        var next = ({})
        var sections = [layout.left || [], layout.center || [], layout.right || []]
        for (var i = 0; i < sections.length; i++) {
          var sec = sections[i]
          if (!sec) continue
          for (var j = 0; j < sec.length; j++) {
            if (sec[j] && sec[j].id) next[sec[j].id] = sec[j]
          }
        }
        root.settings = next
      } catch (e) { root.settings = ({}) }
    }
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omarchy-bt-settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle { anchors.fill: parent; color: Color.menu.scrim }
    MouseArea { anchors.fill: parent; onClicked: root.dismiss() }

    Rectangle {
      width: Math.min(420, panel.width - 32)
      height: Math.min(80 + rowsColumn.implicitHeight + (root.actionMessage ? 24 : 0), panel.height - 80)
      anchors.centerIn: parent
      radius: 12
      color: Color.menu.background
      border.color: Color.menu.border
      border.width: 1

      MouseArea { anchors.fill: parent; onClicked: {} }
      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) root.dismiss()
          else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backspace) root.back()
          else if (event.key === Qt.Key_Up) root.selectedIndex = Math.max(0, root.selectedIndex - 1)
          else if (event.key === Qt.Key_Down) root.selectedIndex = Math.min(root.rows.length - 1, root.selectedIndex + 1)
          else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Right) root.activate(root.selectedIndex)
          else return
          event.accepted = true
        }
        Text {
          id: heading
          x: 20; y: 18
          text: root.title()
          color: Color.menu.text
          font.pixelSize: 19
          font.bold: true
        }
        Text {
          x: parent.width - width - 20; y: 21
          text: root.page ? "← Back" : "Esc Close"
          color: Color.muted
          font.pixelSize: 12
          MouseArea { anchors.fill: parent; onClicked: root.back() }
        }
        Flickable {
          id: rowFlick
          x: 12; y: 58
          width: parent.width - 24
          height: parent.height - 70 - (root.actionMessage ? 24 : 0)
          contentHeight: rowsColumn.implicitHeight
          clip: true
          Column {
            id: rowsColumn
            width: parent.width
            spacing: 4
            Repeater {
              id: rowRepeater
              model: root.rows
              delegate: Rectangle {
                id: rowItem
                required property var modelData
                required property int index
                width: rowsColumn.width
                height: modelData.detail ? 56 : 42
                radius: 7
                color: root.selectedIndex === index ? Color.menu.border : "transparent"
                Text {
                  x: 12; y: modelData.detail ? 8 : 11
                  width: parent.width - (modelData.previewFamily ? (modelData.previewSlot ? 116 : 140) : 24)
                  text: modelData.label
                  color: Color.menu.text
                  font.pixelSize: 15
                  elide: Text.ElideRight
                }
                Text {
                  x: 12; y: 31
                  width: parent.width - (modelData.previewFamily ? (modelData.previewSlot ? 116 : 140) : 24)
                  visible: !!modelData.detail
                  text: modelData.detail || ""
                  color: Color.muted
                  font.pixelSize: 12
                  elide: Text.ElideRight
                }
                Row {
                  visible: !!rowItem.modelData.previewFamily
                  anchors.right: parent.right
                  anchors.rightMargin: 12
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: 4
                  Repeater {
                    model: rowItem.modelData.previewSlot ? ["", "Filled", "Outline"] : root.slots
                    delegate: Item {
                      id: preview
                      required property string modelData
                      width: 25; height: 25
                      Image {
                        id: previewAsset
                        anchors.fill: parent
                        source: rowItem.modelData.previewSlot
                          ? root.artworkSource(rowItem.modelData.previewSlot, rowItem.modelData.previewFamily, preview.modelData)
                          : root.artworkSource(preview.modelData, rowItem.modelData.previewFamily, "")
                        fillMode: Image.PreserveAspectFit
                        sourceSize.width: Math.round(width * Screen.devicePixelRatio)
                        sourceSize.height: Math.round(height * Screen.devicePixelRatio)
                        visible: false
                        layer.enabled: true
                      }
                      ColorOverlay {
                        anchors.fill: previewAsset
                        source: previewAsset
                        color: Color.menu.text
                      }
                    }
                  }
                }
                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  onEntered: root.selectedIndex = index
                  onClicked: root.activate(index)
                }
              }
            }
          }
        }
        Text {
          x: 20; y: parent.height - 25
          text: root.actionMessage
          visible: !!text
          color: Color.muted
          font.pixelSize: 12
        }
      }
    }
  }
}
