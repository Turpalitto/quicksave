module.exports = {
  env: {
    node: true,
    es2022: true,
    jest: true,
  },
  extends: ['eslint:recommended'],
  parserOptions: {
    ecmaVersion: 2022,
  },
  rules: {
    'no-console': ['warn', { allow: ['warn', 'error'] }],
    'no-unused-vars': ['error', { argsIgnorePattern: '^_', varsIgnorePattern: '^_' }],
    'no-empty': ['error', { allowEmptyCatch: true }],
    'no-useless-escape': 'off',
  },
  overrides: [
    {
      files: ['**/*.test.js'],
      rules: {
        'no-unused-vars': 'off',
      },
    },
  ],
  ignorePatterns: ['node_modules/'],
};
