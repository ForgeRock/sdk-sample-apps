module.exports = {
  root: true,
  extends: ['prettier'],
  env: {
    browser: true,
    node: true,
    es2021: true,
  },
  ignorePatterns: ['**/dist/*', 'node_modules/*'],
  parserOptions: {
    sourceType: 'module',
  },
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
  plugins: ['prettier'],
  rules: {
    'prettier/prettier': ['error'],
  },
};
