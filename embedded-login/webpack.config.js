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
const AM_URL = process.env.AM_URL;
const TIMEOUT = process.env.TIMEOUT;
const REALM_PATH = process.env.REALM_PATH;
const TREE = process.env.TREE;

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
      'process.env.AM_URL': JSON.stringify(AM_URL),
      'process.env.TIMEOUT': JSON.stringify(TIMEOUT),
      'process.env.REALM_PATH': JSON.stringify(REALM_PATH),
      'process.env.TREE': JSON.stringify(TREE),
    }),
  ],
  resolve: {
    extensions: ['.js', '.jsx', '.html'],
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
