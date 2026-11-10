const base = require('./jest.config.cjs');

/** Manual frozen-domain lane: adoption visit lib tests retained for migration/journey coverage. */
module.exports = {
  ...base,
  testMatch: [
    '<rootDir>/test/adoptionVisits.test.js',
    '<rootDir>/test/adoptionJourneys.test.js',
    '<rootDir>/test/fosterPlacements.test.js',
    '<rootDir>/test/sessionLifecycle.test.js',
    '<rootDir>/test/custodyTransfers.test.js',
  ],
};
