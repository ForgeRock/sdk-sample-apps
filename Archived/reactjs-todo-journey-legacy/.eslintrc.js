module.exports = {
  env: {
    browser: true,
    es2021: true,
  },
  ignorePatterns: [
    '**/node_modules/**',
    '**/dist/**',
    'public',
    'playwright-report',
    'test-results',
  ],
  extends: ['standard', 'plugin:react/recommended', 'prettier'],
  overrides: [
    {
      env: {
        node: true,
      },
      files: ['.eslintrc.{js,cjs}'],
      parserOptions: {
        sourceType: 'script',
      },
    },
  ],
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
  },
  plugins: ['react'],
  settings: {
    react: {
      version: 'detect',
    },
  },
  rules: {
    'react/prop-types': 'off',
    'no-debugger': 'off',
  },
};
