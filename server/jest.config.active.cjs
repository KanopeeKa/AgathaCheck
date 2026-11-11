const base = require('./jest.config.cjs');

const frozenPatterns = [
  '<rootDir>/test/organizations/',
  '<rootDir>/test/adoptionVisits.test.js',
  '<rootDir>/test/adoptionJourneys.test.js',
  '<rootDir>/test/fosterPlacements.test.js',
  '<rootDir>/test/sessionLifecycle.test.js',
  '<rootDir>/test/custodyTransfers.test.js',
];

const collectCoverageFrom = require('./collectCoverageFrom.cjs');

module.exports = {
  ...base,
  collectCoverageFrom,
  coverageReporters: ['text', 'lcov', 'json-summary'],
  testPathIgnorePatterns: [
    ...(base.testPathIgnorePatterns || []),
    ...frozenPatterns,
  ],
};
