const active = require('./jest.config.active.cjs');

// The database-free CI job runs only unit tests. The PostgreSQL CI job and
// `npm test` still run the DB suites, which must fail if their database is absent.
module.exports = {
  ...active,
  testPathIgnorePatterns: [
    ...(active.testPathIgnorePatterns || []),
    '<rootDir>/test/db/',
  ],
};