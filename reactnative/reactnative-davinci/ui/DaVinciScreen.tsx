/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useCallback } from 'react';
import { ScrollView } from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { davinciScreenStyles } from '../src/styles/davinciStyles';
import type { RootStackParamList } from '../App';
import DaVinciClientPanel from './davinci/components/organisms/DaVinciClientPanel';

type Props = NativeStackScreenProps<RootStackParamList, 'DaVinci'> & {
  /**
   * Redirect URI of the selected DaVinci configuration, used by social login.
   */
  externalIdpRedirectUri?: string;
};

/**
 * Renders the sample app DaVinci flow. The DaVinciProvider is mounted at the
 * app root so this screen shares the same native instance as TokenScreen and
 * UserProfileScreen.
 *
 * @param props Native stack screen props.
 * @returns DaVinci screen element.
 */
export default function DaVinciScreen(props: Props): React.ReactElement {
  const { navigation, route, externalIdpRedirectUri } = props;
  const verificationUri = route.params?.verificationUri;
  const handleAuthenticated = useCallback((): void => {
    navigation.navigate('Home');
  }, [navigation]);
  const handleUserProfile = useCallback((): void => {
    navigation.navigate('UserProfile');
  }, [navigation]);

  return (
    <ScrollView
      style={davinciScreenStyles.screen}
      contentContainerStyle={davinciScreenStyles.content}
      keyboardShouldPersistTaps="handled"
    >
      <DaVinciClientPanel
        onAuthenticated={handleAuthenticated}
        onUserProfile={handleUserProfile}
        verificationUri={verificationUri}
        externalIdpRedirectUri={externalIdpRedirectUri}
      />
    </ScrollView>
  );
}
