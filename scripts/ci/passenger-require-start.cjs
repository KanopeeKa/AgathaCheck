/**
 * Start the API the way cPanel Passenger does (require on bin/start.js), not `node bin/start.js`.
 * Used by PR startup smoke — see scripts/ci/pr-startup-smoke.sh.
 */
const { createRequire } = require('node:module');
const path = require('node:path');

const startPath = path.resolve(__dirname, '../../server/bin/start.js');
createRequire(startPath)(startPath);
