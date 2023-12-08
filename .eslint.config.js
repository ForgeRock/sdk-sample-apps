module.exports = {
  env: {
    browser: true,
    node: true,
    es2021: true,
  },
  extends: ['prettier'],
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
  plugins: ['prettier', 'react'],
  rules: {
    'prettier/prettier': ['error'],
  },
};
