/**
 * Jest coverage universe for active server production code (J.1-4).
 * Imported by jest.config.active.cjs and referenced by check_coverage_ratchet.js.
 */
module.exports = [
  'lib/**/*.js',
  'services/**/*.js',
  'routes/**/*.js',
  '!routes/organizations/**',
  '!routes/fosterPlacements.js',
  '!routes/custodyTransfers.js',
];
