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
    'comma-dangle': ['error', 'never'],
    'require-jsdoc': 'off',
    'object-curly-spacing': ['error', 'always'],
    'padded-blocks': 'off'
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
