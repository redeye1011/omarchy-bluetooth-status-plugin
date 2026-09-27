const assert = require('node:assert/strict')
const model = require('../PresenceModel.js')
const order = require('../IconOrder.js')
const exact = { address: 'AA:BB:CC:DD:EE:FF', name: 'Desk Device', connected: true, batteryAvailable: true, battery: 0.62 }
const similar = { address: '11:22:33:44:55:66', name: 'Desk Device Extra', connected: false }
assert.equal(model.matchDevice([similar, exact], 'aa:bb:cc:dd:ee:ff'), exact)
assert.equal(model.matchDevice([similar], 'AA:BB:CC:DD:EE:FF'), null)
assert.equal(model.matchDevice([exact], ''), null)
assert.equal(model.matchDevice([exact], 'prefix-AA:BB:CC:DD:EE:FF'), null)
assert.equal(model.batteryPercent(model.deviceSnapshot(exact)), 62)
assert.match(model.tooltipText(null, 'Speaker', false), /not configured/)
assert.equal(model.isHexColor('#abc'), true)
assert.equal(model.isHexColor('red'), false)
for (const type of ['Speaker', 'Headphones', 'Mouse', 'Keyboard']) {
  for (const [configured, connected, variant] of [
    [false, false, ''], [false, true, ''], [true, false, 'Outline'], [true, true, 'Filled']
  ]) {
    assert.equal(model.artworkFilename('glyph', type, 'shape', configured, connected), `MenuB${type}${variant}.png`)
    assert.equal(model.artworkFilename('glyph', type, 'color', configured, connected), '')
    assert.equal(model.artworkFilename('glyph', type, 'monochrome', configured, connected), '')
  }
  for (const family of ['a', 'b', 'c']) {
    const prefix = `Menu${family.toUpperCase()}${type}`
    for (const [configured, connected, variant] of [
      [false, false, ''], [false, true, ''], [true, false, 'Outline'], [true, true, 'Filled']
    ]) {
      assert.equal(model.artworkFilename(family, type, 'shape', configured, connected), `${prefix}${variant}.png`)
      assert.equal(model.artworkFilename(family, type, 'monochrome', configured, connected), `${prefix}${variant}.png`)
      assert.equal(model.artworkFilename(family, type, 'color', configured, connected), `${prefix}.png`)
    }
  }
}
assert.deepEqual(order.normalize('mouse,mouse,keyboard'), ['mouse', 'keyboard', 'speaker', 'earbuds'])
const seen = new Set(['speaker,earbuds,mouse,keyboard'])
const queue = [...seen]
for (const current of queue) {
  for (const slot of current.split(',')) {
    for (const direction of [-1, 1]) {
      const next = order.move(current, slot, direction)
      assert.deepEqual([...next.split(',')].sort(), ['earbuds', 'keyboard', 'mouse', 'speaker'])
      if (!seen.has(next)) { seen.add(next); queue.push(next) }
    }
  }
}
assert.equal(seen.size, 24)
console.log('Presence models: OK')
