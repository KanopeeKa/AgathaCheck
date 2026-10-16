'use strict';

/** Stub until WP5 (state-machine §4.2 U-rules). */
// eslint-disable-next-line no-unused-vars
function decideUat() {
  return { state: 'release:merged', phase: null, action: { actor: 'driver', kind: 'wait', launch: false, args: { reason: 'preuat' } }, stop: null, evidence: [], budgets: {} };
}

module.exports = { decideUat };
