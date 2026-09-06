/** F-20: ratchet lint on Pet Care policy modules and touched routes (expand over time). */
export default [
  {
    files: [
      'server/routes/weightEntries.js',
      'server/lib/petAccess.js',
      'server/lib/petCapabilityPolicy.js',
      'server/lib/openapi/**/*.js',
    ],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: 'module',
      globals: {
        console: 'readonly',
        process: 'readonly',
        Buffer: 'readonly',
        __dirname: 'readonly',
        __filename: 'readonly',
        setTimeout: 'readonly',
        clearTimeout: 'readonly',
        setInterval: 'readonly',
        clearInterval: 'readonly',
      },
    },
    rules: {
      'no-unused-vars': ['error', { argsIgnorePattern: '^_', caughtErrorsIgnorePattern: '^_' }],
      'no-undef': 'error',
      'no-console': 'off',
    },
  },
];
