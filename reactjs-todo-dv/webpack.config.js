const dotenv = require('dotenv');
const path = require('path');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const webpack = require('webpack');

module.exports = () => {
  // Pull the local .env configuration, if present
  const localEnv = dotenv.config().parsed || {};

  // Use process environment variables for prod, but fallback to local .env for dev
  const APP_URL = process.env.APP_URL || localEnv.APP_URL;
  const API_URL = process.env.API_URL || localEnv.API_URL;
  const DEBUGGER_OFF = process.env.DEBUGGER_OFF || localEnv.DEBUGGER_OFF;
  const DEVELOPMENT = process.env.DEVELOPMENT || localEnv.DEVELOPMENT;
  const CLIENT_ID = process.env.CLIENT_ID || localEnv.CLIENT_ID;
  const REDIRECT_URI = process.env.REDIRECT_URI || localEnv.REDIRECT_URI;
  const SCOPE = process.env.SCOPE || localEnv.SCOPE;
  const BASE_URL = process.env.BASE_URL || localEnv.BASE_URL;

  return {
    // Point to the top level source file
    entry: {
      app: './client/index.js',
    },
    resolve: {
      extensions: ['', '.js', '.jsx'],
    },
    // This helps provide better debugging in browsers
    devtool: 'source-map',
    // The location of where the built files are placed
    output: {
      path: path.resolve(__dirname, 'public'),
      filename: '[name].js',
    },
    // Dictates some behavior in Webpack, "development" is a bit quicker
    mode: DEVELOPMENT === 'true' ? 'development' : 'production',
    // Modules are essentially plugins that can extend/modify Webpack
    // Here, we are using it to transpile React's JSX to ordinary functions
    module: {
      rules: [
        {
          // If JavaScript file ...
          test: /\.js$/,
          //exclude: /(node_modules)/,
          resolve: {
            fullySpecified: false,
          },
          use: {
            // Babel is a JavaScript transpiler (kind of like a compiler)
            // It converts unsupported features to something browser's can use
            loader: 'babel-loader',
            options: {
              presets: [
                // Transforms for browsers that support ESModules (e.g. modern browsers)
                // and include standard React transformations
                ['@babel/preset-env', { targets: { esmodules: true } }],
                ['@babel/preset-react'],
              ],
            },
          },
        },
        {
          // If SCSS file ...
          test: /\.(scss)$/,
          use: [
            // Injects CSS into DOM
            'style-loader',
            // Extracts CSS imported into project into separate output
            {
              loader: MiniCssExtractPlugin.loader,
              options: {
                esModule: false,
              },
            },
            // Allows for the loading of CSS via "import"
            'css-loader',
            // Allows for post-processing of CSS
            {
              loader: 'postcss-loader',
              options: {
                postcssOptions: {
                  plugins: () => [require('autoprefixer')],
                },
              },
            },
            // Processes SCSS into CSS
            'sass-loader',
          ],
        },
      ],
    },
    devServer: {
      allowedHosts: ['localhost', 'react.example.com', '.example.com'],
      open: true,
      client: {
        overlay: false,
      },
      port: 8443,
      historyApiFallback: true,
    },
    plugins: [
      new MiniCssExtractPlugin(),
      new webpack.DefinePlugin({
        // Inject all the environment variable into the Webpack build
        'process.env.APP_URL': JSON.stringify(APP_URL),
        'process.env.API_URL': JSON.stringify(API_URL),
        'process.env.DEBUGGER_OFF': JSON.stringify(DEBUGGER_OFF),
        'process.env.CLIENT_ID': JSON.stringify(CLIENT_ID),
        'process.env.REDIRECT_URI': JSON.stringify(REDIRECT_URI),
        'process.env.SCOPE': JSON.stringify(SCOPE),
        'process.env.BASE_URL': JSON.stringify(BASE_URL),
      }),
    ],
  };
};
