module.exports = {
  env: {
    browser: true,
    node: true,
    es2021: true,
  },
  extends: ['prettier', 'plugin:react/recommended'],
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
