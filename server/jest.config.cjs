module.exports = {
  testEnvironment: 'node',
  transform: { '^.+\\.js$': 'babel-jest' },
  // uuid v14+ ships ESM-only; babel-jest must transform it for Jest.
  transformIgnorePatterns: ['/node_modules/(?!uuid/)'],
  coverageThreshold: {
    './lib/petAccess.js': {
      statements: 80,
      branches: 80,
      functions: 80,
      lines: 90,
    },
    './lib/petCapabilityPolicy.js': {
      statements: 85,
      branches: 90,
      functions: 100,
      lines: 85,
    },
  },
};
