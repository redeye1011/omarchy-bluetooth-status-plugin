import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import qs.Commons
import qs.Ui
import "IconOrder.js" as Order

Item {
  id: root
  property var shell: null
  property bool opened: false
  property string page: ""
  property int selectedIndex: 0
  property string actionMessage: ""
  property var settings: ({})
  property string returnMenu: "root"

  readonly property color background: Color.menu.background
  readonly property color foreground: Color.menu.text
  readonly property color border: Color.menu.border
  readonly property var borderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  readonly property color scrim: Color.menu.scrim
  readonly property color selectedBackground: Color.menu.selectedBackground
  readonly property color selectedText: Color.menu.selectedText
  readonly property color selectedBorder: Color.menu.selectedBorder
  readonly property var selectedBorderSpec: Border.surfaceSpec("menu", "selected-border", selectedBorder, 0)
  readonly property real rowReservedBorderLeft: Border.left(selectedBorderSpec)
  readonly property real rowReservedBorderRight: Border.right(selectedBorderSpec)
  readonly property int cornerRadius: Style.cornerRadius
  readonly property int contentMargin: Style.spacing.panelPadding
  readonly property int headerHeight: Math.max(Style.space(34), Style.font.title + Style.spacing.controlPaddingY * 2)
  readonly property int contentSpacing: Style.spacing.md
  readonly property int baseRowHeight: Math.max(Style.space(50), Style.font.body + Style.spacing.rowPaddingX * 2)
  readonly property int detailRowHeight: Math.max(Style.space(58), Style.font.body + Style.font.caption + Style.spacing.rowPaddingX * 2)
  readonly property int rowSpacing: Style.spacing.xs
  readonly property string fontFamily: Style.font.menuFamily

  readonly property string helperPath: Quickshell.env("HOME") + "/.config/omarchy/plugins/redeye1011.bluetooth-status/bin/omarchy-bt-widgets"
  readonly property var widgetEntry: settings["redeye1011.bluetooth-status"] || ({})
  readonly property var iconOrder: Order.normalize(widgetEntry.iconOrder)
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
  onSelectedIndexChanged: {
    if (resultList) resultList.positionViewAtIndex(selectedIndex, ListView.Contain)
  }

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
    if (parts[0] === "order") return parts[1] ? parts[1][0].toUpperCase() + parts[1].slice(1) + " position" : "Icon order"
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
      result.push({label: "Icon order", detail: "Arrange the four bar icons", next: "order"})
      for (var i = 0; i < slots.length; i++) {
        var slot = slots[i], current = entry(slot), found = device(current.address)
        var state = !current.address ? "Choose a device" : found && found.connected ? "Connected" : "Not connected here"
        result.push({label: slot[0].toUpperCase() + slot.slice(1), detail: state, next: slot})
      }
      result.push({label: "Manage devices", detail: "Omarchy Bluetooth panel", command: ["omarchy-shell", "shell", "summon", "omarchy.bluetooth"]})
    } else if (page === "style") {
      var styles = [["color", "Red / Green", "Green when connected, red when away"],
        ["shape", "Outline / Fill", "Stock glyphs use Linework artwork"],
        ["monochrome", "Monochrome Squares", "Filled when connected; outlined when away"]]
      for (var s = 0; s < styles.length; s++)
        result.push({label: styles[s][1] + (currentStyle() === styles[s][0] ? " ✓" : ""),
          detail: styles[s][2],
          command: [root.helperPath, "style", styles[s][0]]})
    } else if (page === "order") {
      for (var o = 0; o < iconOrder.length; o++) {
        var orderedSlot = iconOrder[o]
        result.push({label: orderedSlot[0].toUpperCase() + orderedSlot.slice(1),
          detail: "Position " + (o + 1) + " of 4", next: "order." + orderedSlot})
      }
    } else if (page.slice(0, 6) === "order.") {
      var movingSlot = page.slice(6), position = iconOrder.indexOf(movingSlot)
      if (position > 0) result.push({label: "Move left", detail: "Before " + iconOrder[position - 1],
        command: [root.helperPath, "order", Order.move(iconOrder.join(","), movingSlot, -1)]})
      if (position >= 0 && position < iconOrder.length - 1) result.push({label: "Move right", detail: "After " + iconOrder[position + 1],
        command: [root.helperPath, "order", Order.move(iconOrder.join(","), movingSlot, 1)]})
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

  function rowHeightForDetail(detail) {
    return detail ? root.detailRowHeight : root.baseRowHeight
  }

  function availableRowsHeight() {
    var top = panel.cardTop >= 0 ? panel.cardTop : Style.gapsOut
    var available = panel.height - top - Style.gapsOut - root.contentMargin * 2 - root.headerHeight - root.contentSpacing - (root.actionMessage ? Style.space(24) : 0)
    return Math.min(available, Math.round(panel.height * 0.7))
  }

  function foldedListHeight(totals, available) {
    var count = totals.length
    if (count === 0) return root.baseRowHeight
    if (totals[count - 1] <= available) return totals[count - 1]

    var peek = Math.round(root.baseRowHeight * 0.55)
    var full = 0
    while (full < count && totals[full] <= available) full++
    while (full > 1 && totals[full - 1] + root.rowSpacing + peek > available) full--
    if (full < 1) return Math.max(available, root.baseRowHeight)

    return totals[full - 1] + root.rowSpacing + peek
  }

  function rowListHeight() {
    if (rows.length === 0) return root.baseRowHeight
    var totals = []
    var total = 0
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) total += root.rowSpacing
      total += root.rowHeightForDetail(rows[i].detail)
      totals.push(total)
    }
    return foldedListHeight(totals, availableRowsHeight())
  }

  readonly property int cardWidth: Math.min(Style.space(300), panel.width - Style.gapsOut * 2)
  readonly property int visibleRowsHeight: rowListHeight()
  readonly property int cardHeight: Math.min(root.contentMargin * 2 + root.headerHeight + root.contentSpacing + root.visibleRowsHeight + (root.actionMessage ? Style.space(24) : 0), panel.height - Style.gapsOut * 2)

  function navigate(next) {
    panel.freezeCardTop()
    page = next
    selectedIndex = 0
    if (resultList) resultList.positionViewAtBeginning()
    actionMessage = ""
  }
  function returnToOmarchyMenu() {
    var targetMenu = root.returnMenu || "root"
    dismiss()
    Quickshell.execDetached(["omarchy-shell", "shell", "summon", "omarchy.menu", JSON.stringify({menu: targetMenu})])
  }
  function back() {
    if (!page) {
      if (root.returnMenu) returnToOmarchyMenu()
      else dismiss()
      return
    }
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
  function open(rawPayload) {
    page = ""
    selectedIndex = 0
    opened = true
    if (panel) panel.cardTop = -1
    actionMessage = ""
    returnMenu = "root"
    if (rawPayload) {
      try {
        var payload = typeof rawPayload === "string" ? JSON.parse(rawPayload) : rawPayload
        if (payload && payload.returnMenu !== undefined) returnMenu = String(payload.returnMenu || "")
      } catch (e) {}
    }
    configFile.reload()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }
  function close() { opened = false }
  function dismiss() {
    opened = false
    if (shell && typeof shell.hide === "function") shell.hide("redeye1011.bluetooth-status")
  }
  function toggle(payloadJson) { if (opened) dismiss(); else open(payloadJson || "{}") }

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

    property int cardTop: -1
    readonly property int centeredTop: Math.max(Style.gapsOut, Math.round((height - root.cardHeight) / 2))
    readonly property int effectiveCardTop: cardTop >= 0 ? cardTop : centeredTop

    function freezeCardTop() {
      if (visible && cardTop < 0) {
        cardTop = effectiveCardTop
      }
    }

    onVisibleChanged: if (!visible) cardTop = -1

    Rectangle {
      anchors.fill: parent
      color: root.scrim
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    BorderSurface {
      id: card
      width: root.cardWidth
      height: Math.min(root.cardHeight, panel.height - Style.gapsOut - panel.effectiveCardTop)
      radius: root.cornerRadius
      anchors.horizontalCenter: parent.horizontalCenter
      y: panel.effectiveCardTop
      color: root.background
      borderSpec: root.borderSpec
      padding: root.contentMargin

      MouseArea { anchors.fill: parent; onClicked: {} }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) root.dismiss()
          else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backspace) root.back()
          else if (event.key === Qt.Key_Up) {
            root.selectedIndex = Math.max(0, root.selectedIndex - 1)
            resultList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
          } else if (event.key === Qt.Key_Down) {
            root.selectedIndex = Math.min(root.rows.length - 1, root.selectedIndex + 1)
            resultList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Right) {
            root.activate(root.selectedIndex)
          } else {
            return
          }
          event.accepted = true
        }

        Column {
          anchors.fill: parent
          anchors.topMargin: card.contentTopInset
          anchors.rightMargin: card.contentRightInset
          anchors.bottomMargin: card.contentBottomInset
          anchors.leftMargin: card.contentLeftInset
          spacing: root.contentSpacing

          Rectangle {
            width: parent.width
            height: root.headerHeight
            radius: root.cornerRadius
            color: "transparent"

            Text {
              textFormat: Text.PlainText
              anchors.left: parent.left
              anchors.right: backText.left
              anchors.rightMargin: Style.space(8)
              anchors.verticalCenter: parent.verticalCenter
              text: root.title()
              color: root.foreground
              opacity: 0.58
              font.family: root.fontFamily
              font.pixelSize: Style.font.heading
              font.weight: Font.Medium
              elide: Text.ElideRight
            }

            Text {
              id: backText
              textFormat: Text.PlainText
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              text: (root.page || root.returnMenu) ? "← Back" : "Esc Close"
              color: Color.muted
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.back()
              }
            }
          }

          Item {
            width: parent.width
            height: root.visibleRowsHeight

            ListView {
              id: resultList
              anchors.fill: parent
              model: root.rows
              clip: true
              spacing: root.rowSpacing
              boundsBehavior: Flickable.StopAtBounds
              currentIndex: root.selectedIndex

              delegate: BorderSurface {
                id: rowItem
                required property var modelData
                required property int index
                width: ListView.view.width
                height: root.rowHeightForDetail(modelData.detail)
                radius: root.cornerRadius
                color: root.selectedIndex === index ? root.selectedBackground : "transparent"
                borderSpec: root.selectedIndex === index ? root.selectedBorderSpec : Border.none()

                Column {
                  id: contentColumn
                  anchors.left: parent.left
                  anchors.leftMargin: root.rowReservedBorderLeft + Style.space(18)
                  anchors.right: trail.visible ? trail.left : parent.right
                  anchors.rightMargin: trail.visible ? Style.space(6) : (root.rowReservedBorderRight + Style.space(18))
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.space(3)

                  Text {
                    id: labelText
                    textFormat: Text.PlainText
                    width: parent.width
                    text: modelData.label
                    color: root.selectedIndex === index ? root.selectedText : root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.heading
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                  }

                  Text {
                    textFormat: Text.PlainText
                    width: parent.width
                    text: modelData.detail || ""
                    visible: !!modelData.detail
                    color: root.foreground
                    opacity: 0.52
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    elide: Text.ElideRight
                  }
                }

                Row {
                  id: trail
                  visible: !!rowItem.modelData.previewFamily
                  anchors.right: parent.right
                  anchors.rightMargin: root.rowReservedBorderRight + Style.space(12)
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.space(4)

                  Repeater {
                    model: rowItem.modelData.previewSlot ? ["", "Filled", "Outline"] : root.slots
                    delegate: Item {
                      id: preview
                      required property string modelData
                      width: Style.space(20); height: Style.space(20)
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
                        color: root.selectedIndex === rowItem.index ? root.selectedText : root.foreground
                      }
                    }
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: root.selectedIndex = index
                  onClicked: root.activate(index)
                }
              }
            }

            Rectangle {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              height: Math.min(Style.space(28), parent.height / 2)
              visible: opacity > 0
              opacity: resultList.contentHeight > resultList.height
                ? Math.max(0, Math.min(1, (resultList.contentY - resultList.originY) / height))
                : 0
              gradient: Gradient {
                GradientStop { position: 0; color: root.background }
                GradientStop { position: 1; color: Util.alpha(root.background, 0) }
              }
            }

            Rectangle {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              height: Math.min(Style.space(28), parent.height / 2)
              visible: opacity > 0
              opacity: resultList.contentHeight > resultList.height
                ? Math.max(0, Math.min(1, (resultList.originY + resultList.contentHeight - resultList.height - resultList.contentY) / height))
                : 0
              gradient: Gradient {
                GradientStop { position: 0; color: Util.alpha(root.background, 0) }
                GradientStop { position: 1; color: root.background }
              }
            }
          }

          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: root.actionMessage
            visible: !!text
            color: Color.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }
      }
    }
  }
}
