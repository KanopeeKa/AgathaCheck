module.exports = {
  testEnvironment: 'node',
  transform: { '^.+\\.js$': 'babel-jest' },
  // uuid v14+ ships ESM-only; babel-jest must transform it for Jest.
  transformIgnorePatterns: ['/node_modules/(?!uuid/)'],
};
