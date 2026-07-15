/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { StyleProp, Text, TextStyle, View, ViewStyle } from 'react-native';
import { commonStyles } from '../../../src/styles/common';
import { cardSectionStyles as styles } from '../../../src/styles/componentStyles';

type CardSectionProps = {
  /**
   * Optional card title.
   */
  title?: string;
  /**
   * Optional card subtitle.
   */
  subtitle?: string;
  /**
   * Optional header badge text.
   */
  badgeText?: string;
  /**
   * Optional right-side header content.
   */
  headerRight?: React.ReactNode;
  /**
   * Card body.
   */
  children?: React.ReactNode;
  /**
   * Optional style override for card container.
   */
  style?: StyleProp<ViewStyle>;
  /**
   * Optional style override for title text.
   */
  titleStyle?: StyleProp<TextStyle>;
  /**
   * Optional style override for subtitle text.
   */
  subtitleStyle?: StyleProp<TextStyle>;
};

/**
 * Reusable card shell with optional title, subtitle, and badge.
 *
 * @param props Card section props.
 * @returns Card section element.
 */
export default function CardSection(
  props: CardSectionProps,
): React.ReactElement {
  const {
    title,
    subtitle,
    badgeText,
    headerRight,
    children,
    style,
    titleStyle,
    subtitleStyle,
  } = props;

  return (
    <View style={[commonStyles.card, style]}>
      {title || badgeText || headerRight ? (
        <View style={styles.headerRow}>
          {title ? (
            <Text style={[commonStyles.codeTitle, titleStyle]}>{title}</Text>
          ) : null}
          {badgeText ? (
            <View style={commonStyles.homeComingSoonBadge}>
              <Text style={commonStyles.homeComingSoonText}>{badgeText}</Text>
            </View>
          ) : null}
          {headerRight}
        </View>
      ) : null}

      {subtitle ? (
        <Text style={[commonStyles.codeText, styles.subtitle, subtitleStyle]}>
          {subtitle}
        </Text>
      ) : null}

      {children}
    </View>
  );
}
