/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { Text, TouchableOpacity, View } from 'react-native';
import { commonStyles } from '../../../src/styles/common';

/**
 * Props for the reusable auth-source tab strip.
 */
export type AuthSourceTabsProps<T extends string> = {
  /**
   * Ordered tab labels to render.
   */
  tabs: readonly T[];
  /**
   * Currently selected tab.
   */
  activeTab: T;
  /**
   * Called when user selects a new tab.
   *
   * @param tab - Newly selected tab.
   */
  onTabChange: (tab: T) => void;
};

/**
 * Renders a shared tab strip for auth-source screens (Journey, DaVinci, OIDC).
 *
 * @param props - Tab strip props.
 * @returns Tab strip element.
 */
export default function AuthSourceTabs<T extends string>(
  props: AuthSourceTabsProps<T>,
): React.ReactElement {
  const { tabs, activeTab, onTabChange } = props;

  return (
    <View style={commonStyles.userProfileTabs}>
      {tabs.map(tab => {
        const selected = tab === activeTab;
        return (
          <TouchableOpacity
            key={tab}
            style={[
              commonStyles.userProfileTab,
              selected ? commonStyles.userProfileTabActive : null,
            ]}
            onPress={() => onTabChange(tab)}
          >
            <Text
              style={[
                commonStyles.userProfileTabText,
                selected ? commonStyles.userProfileTabTextActive : null,
              ]}
            >
              {tab}
            </Text>
          </TouchableOpacity>
        );
      })}
    </View>
  );
}
