const assert = require('node:assert/strict')
const model = require('../PresenceModel.js')
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
console.log('Presence models: OK')
