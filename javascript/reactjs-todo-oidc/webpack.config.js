/*
 * ping-sample-web-react-todo-oidc
 *
 * webpack.config.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

const dotenv = require('dotenv');
const fs = require('fs');
const path = require('path');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const webpack = require('webpack');

module.exports = () => {
  // Pull the local .env configuration, if present
  const localEnv = dotenv.config().parsed || {};

  // Use process environment variables for prod, but fallback to local .env for dev
  const PORT = process.env.PORT || localEnv.PORT || '8443';
  const API_URL = process.env.API_URL || localEnv.API_URL;
  const DEBUGGER_OFF = process.env.DEBUGGER_OFF || localEnv.DEBUGGER_OFF;
  const DEVELOPMENT = process.env.DEVELOPMENT || localEnv.DEVELOPMENT;
  const SERVER = process.env.SERVER || localEnv.SERVER;
  const SDK_CONFIG = process.env.SDK_CONFIG || null;

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
          exclude: /(node_modules)/,
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
      server: 'https',
      open: true,
      client: {
        overlay: false,
      },
      port: PORT,
      historyApiFallback: true,
    },
    plugins: [
      new MiniCssExtractPlugin(),
      new webpack.NormalModuleReplacementPlugin(/config\.json$/, (resource) => {
        if (!fs.existsSync(path.resolve(__dirname, 'config.json'))) {
          resource.request = resource.request.replace('config.json', 'config.example.json');
        }
      }),
      new webpack.DefinePlugin({
        // Inject all the environment variable into the Webpack build
        'process.env.API_URL': JSON.stringify(API_URL),
        'process.env.DEBUGGER_OFF': JSON.stringify(DEBUGGER_OFF),
        'process.env.SERVER': JSON.stringify(SERVER),
        'process.env.SDK_CONFIG': JSON.stringify(SDK_CONFIG),
      }),
    ],
  };
};
