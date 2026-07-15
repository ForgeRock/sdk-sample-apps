/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useCallback } from 'react';
import { ScrollView } from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { JourneyClient } from '@ping-identity/rn-journey';
import type { RootStackParamList } from '../App';
import { commonStyles } from '../src/styles/common';
import JourneyClientPanel from './journey/components/organisms/JourneyClientPanel';

type Props = NativeStackScreenProps<RootStackParamList, 'JourneyHelper'> & {
  /**
   * Journey client selected by the sample app configuration.
   */
  journeyClient: JourneyClient;
  /**
   * App return URI used by external IdP browser authorization.
   */
  externalIdpRedirectUri: string;
};

/**
 * Renders the helper-driven Journey sample screen.
 *
 * @param props - Native stack screen props.
 * @returns Journey helper screen element.
 */
export default function JourneyHelperScreen(props: Props): React.ReactElement {
  const initialJourneyName = props.route.params?.journeyName?.trim() ?? '';
  const { externalIdpRedirectUri, journeyClient } = props;
  const onAuthenticated = useCallback((): void => {
    props.navigation.reset({
      index: 1,
      routes: [{ name: 'Home' }, { name: 'UserProfile' }],
    });
  }, [props.navigation]);
  return (
    <ScrollView contentContainerStyle={commonStyles.container}>
      <JourneyClientPanel
        journeyClient={journeyClient}
        externalIdpRedirectUri={externalIdpRedirectUri}
        initialJourneyName={initialJourneyName}
        autoStartOnMount={initialJourneyName.length > 0}
        onAuthenticated={onAuthenticated}
        requireSuccessConfirmation
      />
    </ScrollView>
  );
}
