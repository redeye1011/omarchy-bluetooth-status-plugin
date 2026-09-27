function toArray(values) {
  if (!values) return []
  if (Array.isArray(values)) return values.slice()
  var length = Number(values.length || 0)
  if (!isFinite(length) || length <= 0) return []
  var list = []
  for (var i = 0; i < length; i++) list.push(values[i])
  return list
}

function normalizedAddress(value) {
  var address = String(value || "").trim().toLowerCase()
  return /^([0-9a-f]{2}:){5}[0-9a-f]{2}$/.test(address) ? address.replace(/:/g, "") : ""
}

function deviceLabel(device) {
  if (!device) return ""
  return String(device.deviceName || device.name || device.alias || "").trim()
}

function isHexColor(value) {
  return /^#([0-9a-fA-F]{6}|[0-9a-fA-F]{3}|[0-9a-fA-F]{8})$/.test(String(value || "").trim())
}

function matchDevice(devices, address) {
  var values = toArray(devices)
  var target = normalizedAddress(address)
  if (target.length !== 12) return null

  for (var i = 0; i < values.length; i++) {
    var device = values[i]
    if (!device) continue
    if (normalizedAddress(device.address) === target) return device
  }
  return null
}

// True when a slot has a configured address but that address no longer
// resolves to any known device (e.g. the device was forgotten and re-paired
// under a new address). Callers use this to trigger a one-shot rebind
// request against the helper CLI, guarded separately from this pure check.
function needsRebind(address, devices) {
  return normalizedAddress(address) !== "" && matchDevice(devices, address) === null
}

function deviceSnapshot(device) {
  if (!device) {
    return {
      found: false,
      address: "",
      name: "",
      connected: false,
      batteryAvailable: false,
      battery: 0
    }
  }

  return {
    found: true,
    address: String(device.address || ""),
    name: deviceLabel(device),
    connected: !!device.connected,
    batteryAvailable: !!device.batteryAvailable,
    battery: device.battery !== undefined ? Number(device.battery) : 0
  }
}

function batteryPercent(snapshot) {
  if (!snapshot || !snapshot.batteryAvailable) return -1
  var value = Number(snapshot.battery)
  if (!isFinite(value)) return -1
  // BlueZ may expose 0..1 or 0..100 depending on backend.
  if (value >= 0 && value <= 1) return Math.round(value * 100)
  return Math.max(0, Math.min(100, Math.round(value)))
}

function tooltipText(snapshot, displayName, configured) {
  if (!configured) return "Bluetooth device not configured · choose a tracked device in Bluetooth Status"
  var name = (snapshot && snapshot.name) || displayName || "Bluetooth device"
  if (!snapshot || !snapshot.found) return name + " · not paired on this machine"
  if (!snapshot.connected) return name + " · not connected here"
  var battery = batteryPercent(snapshot)
  if (battery >= 0) return name + " · connected · " + battery + "%"
  return name + " · connected"
}

if (typeof module !== "undefined") {
  module.exports = {
    toArray: toArray,
    normalizedAddress: normalizedAddress,
    deviceLabel: deviceLabel,
    isHexColor: isHexColor,
    matchDevice: matchDevice,
    needsRebind: needsRebind,
    deviceSnapshot: deviceSnapshot,
    batteryPercent: batteryPercent,
    tooltipText: tooltipText
  }
}
