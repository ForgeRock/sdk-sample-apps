/*
 * @forgerock/javascript-sdk
 *
 * webpack.comfig.js
 *
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import webpack from 'webpack';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';
import HtmlWebpackPlugin from 'html-webpack-plugin';
import path from 'path';

dotenv.config();
const __filename = fileURLToPath(import.meta.url);

const __dirname = path.dirname(__filename);

const WEB_OAUTH_CLIENT = process.env.WEB_OAUTH_CLIENT;
const SCOPE = process.env.SCOPE;
const TIMEOUT = process.env.TIMEOUT;
const WELL_KNOWN = process.env.WELL_KNOWN;
const SERVER_TYPE = process.env.SERVER_TYPE;

const config = {
  plugins: [
    new HtmlWebpackPlugin({
      inject: true,
      template: path.resolve(__dirname, './src/public/index.html'),
      filename: 'index.html',
    }),
    new webpack.DefinePlugin({
      // Inject all the environment variable into the Webpack build
      'process.env.WEB_OAUTH_CLIENT': JSON.stringify(WEB_OAUTH_CLIENT),
      'process.env.SCOPE': JSON.stringify(SCOPE),
      'process.env.TIMEOUT': JSON.stringify(TIMEOUT),
      'process.env.WELL_KNOWN': JSON.stringify(WELL_KNOWN),
      'process.env.SERVER_TYPE': JSON.stringify(SERVER_TYPE),
    }),
  ],
  resolve: {
    extensions: ['.js', '.jsx', 'html'],
  },
  entry: {
    main: [path.resolve(__dirname, './src/main.js')],
    styles: [path.resolve(__dirname, './src/styles.css')],
  },
  output: {
    path: path.resolve(__dirname, './dist'),
    filename: '[name].js',
    publicPath: '/',
  },
  target: 'web',
  node: false,
  mode: 'production',
  cache: undefined,
  devtool: 'source-map',
  module: {
    rules: [
      {
        test: /\.css$/i,
        use: ['style-loader', 'css-loader'],
      },
    ],
  },
  devServer: {
    port: 8443,
    host: 'localhost',
    open: false,
    client: {
      overlay: false,
    },
    headers: {
      'Access-Control-Allow-Credentials': true,
      'Access-Control-Allow-Origin': 'null',
      'Content-Security-Policy': 'upgrade-insecure-requests',
    },
    static: {
      directory: path.resolve(__dirname, './src/public'),
    },
    https: true,
  },
  stats: { warnings: false },
};

export default config;
