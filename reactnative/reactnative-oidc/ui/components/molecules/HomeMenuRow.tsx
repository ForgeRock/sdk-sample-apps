/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { Text, TouchableOpacity, View } from 'react-native';
import MaterialIcon from 'react-native-vector-icons/MaterialIcons';
import { commonStyles } from '../../../src/styles/common';
import { colors } from '../../../src/styles/colors';

/**
 * Data model for a home menu row.
 */
export type HomeMenuItem = {
  /**
   * Primary row title.
   */
  title: string;
  /**
   * Secondary row subtitle.
   */
  subtitle: string;
  /**
   * Material icon name.
   */
  icon: string;
  /**
   * Whether row is currently unavailable.
   */
  disabled?: boolean;
  /**
   * Whether "COMING SOON" badge should be shown.
   */
  comingSoon?: boolean;
  /**
   * Optional row press handler.
   */
  onPress?: () => void;
};

/**
 * Renders one home menu row tile.
 *
 * @param props Home menu row data.
 * @returns Home menu row element.
 */
export default function HomeMenuRow(props: HomeMenuItem): React.ReactElement {
  const {
    title,
    subtitle,
    icon,
    disabled = false,
    comingSoon = false,
    onPress,
  } = props;

  return (
    <TouchableOpacity
      style={[
        commonStyles.homeRow,
        disabled ? commonStyles.homeRowDisabled : null,
      ]}
      onPress={disabled ? undefined : onPress}
      disabled={disabled}
    >
      <View style={commonStyles.homeRowContent}>
        <View style={commonStyles.homeRowIconWrap}>
          <MaterialIcon
            name={icon}
            size={36}
            color={disabled ? colors.homeRowDisabledIcon : colors.primary}
          />
        </View>
        <View style={commonStyles.homeRowTextStack}>
          <View style={commonStyles.homeRowTitleContainer}>
            <Text
              style={[
                commonStyles.homeRowTitle,
                disabled ? commonStyles.homeRowTitleDisabled : null,
              ]}
            >
              {title}
            </Text>
            {comingSoon ? (
              <View style={commonStyles.homeComingSoonBadge}>
                <Text style={commonStyles.homeComingSoonText}>COMING SOON</Text>
              </View>
            ) : null}
          </View>
          <Text
            style={[
              commonStyles.homeRowSubtitle,
              disabled ? commonStyles.homeRowSubtitleDisabled : null,
            ]}
          >
            {subtitle}
          </Text>
        </View>
      </View>
      <Text
        style={[
          commonStyles.homeRowChevron,
          disabled ? commonStyles.homeRowChevronDisabled : null,
        ]}
      >
        {'>'}
      </Text>
    </TouchableOpacity>
  );
}
