/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { ScrollView } from 'react-native';
import type { OidcClientConfig } from '@ping-identity/rn-oidc';
import { commonStyles } from '../src/styles/common';
import OidcClientPanel from './oidc/components/organisms/OidcClientPanel';

type OidcScreenProps = {
  /**
   * OIDC config for the currently selected app profile.
   */
  clientConfig: OidcClientConfig;
};

/**
 * Renders OIDC helper screen with provider-backed state.
 *
 * @param props OIDC screen props.
 * @returns OIDC screen element.
 */
export default function OidcScreen(props: OidcScreenProps): React.ReactElement {
  const { clientConfig } = props;

  return (
    <ScrollView
      contentContainerStyle={commonStyles.container}
      nestedScrollEnabled
    >
      <OidcClientPanel clientConfig={clientConfig} />
    </ScrollView>
  );
}
