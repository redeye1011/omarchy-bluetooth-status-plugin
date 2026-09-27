var slots = ["speaker", "earbuds", "mouse", "keyboard"]

function normalize(value) {
  var given = String(value || "").split(",")
  var order = []
  for (var i = 0; i < given.length; i++)
    if (slots.indexOf(given[i]) >= 0 && order.indexOf(given[i]) < 0) order.push(given[i])
  for (var j = 0; j < slots.length; j++)
    if (order.indexOf(slots[j]) < 0) order.push(slots[j])
  return order
}

function move(value, slot, direction) {
  var order = normalize(value)
  var from = order.indexOf(slot), to = from + direction
  if (from < 0 || to < 0 || to >= order.length) return order.join(",")
  order[from] = order[to]
  order[to] = slot
  return order.join(",")
}

if (typeof module !== "undefined") module.exports = { normalize: normalize, move: move }
