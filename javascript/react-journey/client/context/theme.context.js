/*
 * ping-sample-web-react-journey
 *
 * theme.context.js
 *
 * Copyright (c) 2026 Ping Identity Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import { createContext } from 'react';

/**
 * @function initTheme - Initialize the global theme based on user preference
 * @param {boolean} prefersDarkTheme - User preference for dark theme
 * @returns {Object} - Theme configuration object
 */
export function initTheme(prefersDarkTheme) {
  let theme;
  if (prefersDarkTheme) {
    document.body.classList.add('cstm_bg-dark', 'bg-dark');
    theme = {
      mode: 'dark',
      // CSS Classes
      bgClass: 'bg-dark',
      borderClass: 'border-dark',
      borderHighContrastClass: 'cstm_border_black',
      cardBgClass: 'cstm_card-dark',
      dropdownClass: 'dropdown-menu-dark',
      listGroupClass: 'cstm_list-group_dark',
      navbarClass: 'cstm_navbar-dark navbar-dark bg-dark text-white',
      textClass: 'text-white',
      textMutedClass: 'text-white-50',
    };
  } else {
    theme = {
      mode: 'light',
      // CSS Classes
      bgClass: '',
      borderClass: '',
      borderHighContrastClass: '',
      cardBgClass: '',
      dropdownClass: '',
      listGroupClass: '',
      navbarClass: 'navbar-light bg-white',
      textClass: '',
      textMutedClass: 'text-muted',
    };
  }
  return theme;
}

/**
 * @constant ThemeContext - Creates React Context for theming
 * This provides the capability to set a global theme in React
 * without having to pass the state as props through parent-child components.
 */
export const ThemeContext = createContext(null);
