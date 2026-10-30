/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { Text, TouchableOpacity, View } from 'react-native';
import FontAwesomeIcon from 'react-native-vector-icons/FontAwesome';
import type { IdpCollector } from '@ping-identity/rn-external-idp';
import { commonStyles } from '../../../../src/styles/common';
import { journeyFieldRendererStyles as fieldStyles } from '../../../../src/styles/journeyStyles';
import { davinciFieldStyles } from '../../../../src/styles/davinciStyles';
import type { DaVinciCollectorRendererProps } from './types';

/**
 * Maps an IdpCollector `idpType` (e.g. `'GOOGLE'`) to a FontAwesome brand
 * icon name. Returns `null` when no match is found.
 */
function resolveIdpIcon(idpType: string): string | null {
  const lower = idpType.toLowerCase();
  if (lower.includes('facebook')) return 'facebook';
  if (lower.includes('google')) return 'google';
  if (lower.includes('apple')) return 'apple';
  return null;
}

/** Brand colors used when the server doesn't supply custom style. */
const BRAND_STYLES: Record<
  string,
  {
    backgroundColor: string;
    borderColor?: string;
    iconBackground: string;
    iconColor: string;
    textColor: string;
  }
> = {
  google: {
    backgroundColor: '#ffffff',
    iconBackground: '#ffffff',
    iconColor: '#4285F4',
    textColor: '#3c4043',
    borderColor: '#dadce0',
  },
  facebook: {
    backgroundColor: '#1877F2',
    iconBackground: '#1877F2',
    iconColor: '#ffffff',
    textColor: '#ffffff',
  },
  apple: {
    backgroundColor: '#000000',
    iconBackground: '#000000',
    iconColor: '#ffffff',
    textColor: '#ffffff',
  },
};

/**
 * Props for {@link DaVinciIdpField}.
 */
export type DaVinciIdpFieldProps = DaVinciCollectorRendererProps & {
  /**
   * Called when the user presses the social login button.
   *
   * @param collector The IdpCollector to authorize.
   */
  onIdpAuthorize: (collector: IdpCollector) => Promise<void>;
};

/**
 * Renders an {@link IdpCollector} as a branded social login button with a
 * FontAwesome icon for Google, Facebook, and Apple.
 *
 * @param props Renderer props extended with `onIdpAuthorize`.
 * @returns Social login button element.
 */
export default function DaVinciIdpField(
  props: DaVinciIdpFieldProps,
): React.ReactElement {
  const { collector, loading, onIdpAuthorize } = props;
  const idpCollector = collector as unknown as IdpCollector;
  const iconName = resolveIdpIcon(idpCollector.idpType);
  const brand = iconName ? BRAND_STYLES[iconName] : undefined;

  return (
    <View style={davinciFieldStyles.card}>
      <TouchableOpacity
        style={[
          commonStyles.buttonSecondary,
          brand?.backgroundColor
            ? { backgroundColor: brand.backgroundColor }
            : null,
          {
            borderColor:
              brand?.borderColor ?? brand?.backgroundColor ?? undefined,
          },
        ]}
        onPress={() => void onIdpAuthorize(idpCollector)}
        disabled={loading || !idpCollector.idpEnabled}
        activeOpacity={0.8}
      >
        <View style={fieldStyles.providerButtonContent}>
          {iconName ? (
            <View
              style={[
                fieldStyles.providerIconContainer,
                brand?.iconBackground
                  ? { backgroundColor: brand.iconBackground }
                  : null,
              ]}
            >
              <FontAwesomeIcon
                name={iconName}
                size={16}
                color={brand?.iconColor ?? '#333333'}
              />
            </View>
          ) : null}
          <Text
            style={[
              commonStyles.buttonTextSecondary,
              brand?.textColor ? { color: brand.textColor } : null,
            ]}
          >
            {idpCollector.label || idpCollector.idpType}
          </Text>
        </View>
      </TouchableOpacity>
    </View>
  );
}
