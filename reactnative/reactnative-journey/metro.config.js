/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { getDefaultConfig, mergeConfig } = require('@react-native/metro-config');

const config = {
  resolver: {
    resolveRequest: (context, moduleName, platform) => {
      // vision-camera's package.json points `source` at src/index (unbuilt TS).
      // Force Metro to use the compiled `main` field instead.
      if (moduleName === 'react-native-vision-camera') {
        return {
          filePath: require.resolve('react-native-vision-camera'),
          type: 'sourceFile',
        };
      }
      return context.resolveRequest(context, moduleName, platform);
    },
  },
};

module.exports = mergeConfig(getDefaultConfig(__dirname), config);
