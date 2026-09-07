const base = require('./jest.config.cjs');

const frozenPatterns = [
  '<rootDir>/test/organizations/',
  '<rootDir>/test/fosterPlacements.test.js',
  '<rootDir>/test/fosteringActivitySummary.test.js',
  '<rootDir>/test/externalFosterNotice.test.js',
  '<rootDir>/test/fosterCapacity.test.js',
  '<rootDir>/test/custodyTransfers.test.js',
  '<rootDir>/test/orgConnections.test.js',
  '<rootDir>/test/organizationsDiscover.test.js',
  '<rootDir>/test/orgPermissions.test.js',
  '<rootDir>/test/orgPeople.test.js',
  '<rootDir>/test/orgPeopleRedaction.test.js',
  '<rootDir>/test/orgPetTransfer.test.js',
  '<rootDir>/test/orgRoles.test.js',
  '<rootDir>/test/adoptionJourneys.test.js',
  '<rootDir>/test/adoptionVisits.test.js',
  '<rootDir>/test/sessionDetail.test.js',
  '<rootDir>/test/sessionLifecycle.test.js',
  '<rootDir>/test/pets/orgMembership.test.js',
];

module.exports = {
  ...base,
  testPathIgnorePatterns: [
    ...(base.testPathIgnorePatterns || []),
    ...frozenPatterns,
  ],
};
