const base = require('./jest.config.cjs');

/** Manual frozen-domain lane: lib-only tests (HTTP org mounts removed in phase 2). */
module.exports = {
  ...base,
  testMatch: [
    '<rootDir>/test/adoptionVisits.test.js',
    '<rootDir>/test/custodyTransfers.test.js',
  ],
};
