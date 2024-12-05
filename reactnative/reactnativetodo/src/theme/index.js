/*
 * forgerock-react-native-sample
 *
 * index.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { NativeBaseProvider, extendTheme } from 'native-base';

/**
 * Customizing NativeBase's default theming
 */
export default function ({ children }) {
  const theme = extendTheme({
    colors: {
      primary: {
        50: '#dcf7ff',
        100: '#b0e2ff',
        200: '#83cdfa',
        300: '#53b9f6',
        400: '#26a5f2',
        500: '#0d8cd9',
        600: '#006daa',
        700: '#004e7a',
        800: '#002f4c',
        900: '#00121f',
      },
      secondary: {
        50: '#e8f3ff',
        100: '#cfd8e3',
        200: '#b4becb',
        300: '#98a4b3',
        400: '#7c8a9c',
        500: '#637183',
        600: '#4c5867',
        700: '#353f4b',
        800: '#1e2630',
        900: '#010e18',
      },
      success: {
        50: '#ddfef5',
        100: '#b6f5e3',
        200: '#8deed2',
        300: '#62e6c0',
        400: '#39dfae',
        500: '#20c695',
        600: '#139a74',
        700: '#066e52',
        800: '#004331',
        900: '#00180f',
      },
    },
    fontConfig: {
      OpenSans: {
        100: {
          normal: 'OpenSans-Light',
          italic: 'OpenSans-LightItalic',
        },
        200: {
          normal: 'OpenSans-Light',
          italic: 'OpenSans-LightItalic',
        },
        300: {
          normal: 'OpenSans-Light',
          italic: 'OpenSans-LightItalic',
        },
        400: {
          normal: 'OpenSans-Regular',
          italic: 'OpenSans-RegularItalic',
        },
        500: {
          normal: 'OpenSans-Medium',
          italic: 'OpenSans-MediumItalic',
        },
        600: {
          normal: 'OpenSans-SemiBold',
          italic: 'OpenSans-SemiBoldItalic',
        },
        700: {
          normal: 'OpenSans-Bold',
          italic: 'OpenSans-BoldItalic',
        },
        800: {
          normal: 'OpenSans-ExtraBold',
          italic: 'OpenSans-ExtraBoldItalic',
        },
        900: {
          normal: 'OpenSans-ExtraBold',
          italic: 'OpenSans-ExtraBoldItalic',
        },
      },
    },
    fonts: {
      heading: 'OpenSans',
      body: 'OpenSans',
      mono: 'OpenSans',
    },
    fontSizes: {
      '2xs': 10,
      xs: 12,
      sm: 14,
      md: 16,
      lg: 18,
      xl: 24,
      '2xl': 36,
      '3xl': 48,
      '4xl': 60,
      '5xl': 72,
      '6xl': 96,
      '7xl': 128,
      '8xl': 128,
      '9xl': 128,
    },
    components: {
      Heading: {
        sizes: {
          xl: { fontWeight: 'light' },
          lg: { fontWeight: 'light' },
          md: { fontWeight: 'bold' },
          sm: { fontWeight: 'medium' },
        },
      },
      Input: {
        baseStyle: {
          placeholderTextColor: 'muted.500',
          borderColor: 'muted.300',
        },
      },
      Text: {
        baseStyle: {
          fontSize: 'sm',
        },
        sizes: {
          xl: { fontSize: 'xl', lineHeight: 7 },
          lg: { fontSize: 'lg', lineHeight: 7 },
          sm: { fontSize: 'sm', lineHeight: 7 },
          xs: { fontSize: 'xs', lineHeight: 7 },
        },
      },
      FormControlErrorMessage: {
        baseStyle: {
          _text: {
            fontSize: 'md',
            fontWeight: 'medium',
            color: 'white',
          },
          backgroundColor: 'danger.600',
          rounded: 'sm',
          marginBottom: 2,
          padding: 2,
        },
      },
      FormControlLabel: {
        baseStyle: {
          _text: {
            fontWeight: 'bold',
            fontSize: 'sm',
          },
          paddingBottom: 0,
        },
      },
      Select: {
        baseStyle: {
          mb: 2,
          fontSize: 'md',
          py: 2,
        },
      },
      FormControl: {
        baseStyle: {
          mb: 4,
        },
      },
      Checkbox: {
        baseStyle: {
          _text: {},
          _interactionBox: {},
        },
      },
    },
  });
  return <NativeBaseProvider theme={theme}>{children}</NativeBaseProvider>;
}
