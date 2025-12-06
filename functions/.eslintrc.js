module.exports = {
  env: {
    es6: true,
    node: true
  },
  parserOptions: {
    ecmaVersion: 2020
  },
  extends: [
    'eslint:recommended',
    'google'
  ],
  rules: {
    'indent': ['error', 2],
    'quotes': ['error', 'single', { allowTemplateLiterals: true }],
    'max-len': ['error', { code: 120 }],
    'comma-dangle': 'off',
    'require-jsdoc': 'off',
    'object-curly-spacing': ['error', 'always'],
    'padded-blocks': 'off',
    'linebreak-style': 'off',
    'eol-last': 'off',
    'no-unused-vars': ['error', { 'argsIgnorePattern': '^_' }]
  },
  overrides: [
    {
      files: ['**/*.spec.*'],
      env: {
        mocha: true
      },
      rules: {}
    }
  ],
  globals: {}
};