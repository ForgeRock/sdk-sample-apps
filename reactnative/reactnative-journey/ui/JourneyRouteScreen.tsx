/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { Alert, ScrollView } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '../App';
import { journeyRouteScreenStyles as styles } from '../src/styles/journeyStyles';
import JourneyStartPanel from './journey/components/organisms/JourneyStartPanel';
import {
  buildRecentJourneySuggestions,
  buildUsedTestJourneys,
  isTestJourneyName,
  RECENT_JOURNEYS_STORAGE_KEY,
  SHOW_AM_TEST_JOURNEY_SUGGESTIONS,
  TEST_JOURNEY_NAME_SUGGESTIONS,
  USED_TEST_JOURNEYS_STORAGE_KEY,
} from './journey/utils/clientPanel';

type Props = NativeStackScreenProps<RootStackParamList, 'JourneyRoute'>;

/**
 * Journey configuration route screen.
 *
 * @param props - Native stack screen props.
 * @returns Journey route screen element.
 */
export default function JourneyRouteScreen(props: Props): React.ReactElement {
  const { navigation } = props;
  const [journeyName, setJourneyName] = useState<string>('');
  const [recentJourneys, setRecentJourneys] = useState<string[]>([]);
  const [usedTestJourneys, setUsedTestJourneys] = useState<string[]>([]);

  const usedTestJourneySet = useMemo<Set<string>>(
    () => new Set(usedTestJourneys),
    [usedTestJourneys],
  );

  useEffect(() => {
    (async (): Promise<void> => {
      try {
        const [recentStored, usedStored] = await Promise.all([
          AsyncStorage.getItem(RECENT_JOURNEYS_STORAGE_KEY),
          AsyncStorage.getItem(USED_TEST_JOURNEYS_STORAGE_KEY),
        ]);

        const recentParsed = recentStored
          ? (JSON.parse(recentStored) as string[])
          : [];
        const usedParsed = usedStored
          ? (JSON.parse(usedStored) as string[])
          : [];

        setRecentJourneys(buildRecentJourneySuggestions(recentParsed));
        setUsedTestJourneys(buildUsedTestJourneys(usedParsed));
      } catch {
        // Ignore suggestion storage failures on route screen.
      }
    })();
  }, []);

  const saveRecentJourney = useCallback(
    async (name: string): Promise<void> => {
      const updated = [name, ...recentJourneys.filter(item => item !== name)];
      setRecentJourneys(updated);
      await AsyncStorage.setItem(
        RECENT_JOURNEYS_STORAGE_KEY,
        JSON.stringify(updated),
      );
    },
    [recentJourneys],
  );

  const markTestJourneyUsed = useCallback(
    async (name: string): Promise<void> => {
      const trimmedName = name.trim();
      if (!isTestJourneyName(trimmedName)) {
        return;
      }
      const updated = [
        trimmedName,
        ...usedTestJourneys.filter(item => item !== trimmedName),
      ];
      setUsedTestJourneys(updated);
      await AsyncStorage.setItem(
        USED_TEST_JOURNEYS_STORAGE_KEY,
        JSON.stringify(updated),
      );
    },
    [usedTestJourneys],
  );

  const handleStart = useCallback(async (): Promise<void> => {
    const trimmedName = journeyName.trim();
    if (!trimmedName) {
      Alert.alert('Enter a journey name first');
      return;
    }

    try {
      await Promise.all([
        saveRecentJourney(trimmedName),
        SHOW_AM_TEST_JOURNEY_SUGGESTIONS
          ? markTestJourneyUsed(trimmedName)
          : Promise.resolve(),
      ]);
    } catch {
      // Ignore local suggestion persistence failures and continue to Journey flow.
    }

    navigation.navigate('JourneyHelper', { journeyName: trimmedName });
  }, [journeyName, markTestJourneyUsed, navigation, saveRecentJourney]);

  const handlePressRecentJourney = useCallback((name: string): void => {
    setJourneyName(name);
  }, []);

  const handlePressTestJourney = useCallback(
    (name: string): void => {
      setJourneyName(name);
      void markTestJourneyUsed(name);
    },
    [markTestJourneyUsed],
  );

  return (
    <ScrollView
      style={styles.screen}
      contentContainerStyle={styles.content}
      keyboardShouldPersistTaps="handled"
      showsVerticalScrollIndicator={false}
    >
      <JourneyStartPanel
        showJourneyInput
        journeyName={journeyName}
        onJourneyNameChange={setJourneyName}
        recentJourneys={recentJourneys}
        testJourneys={
          SHOW_AM_TEST_JOURNEY_SUGGESTIONS
            ? [...TEST_JOURNEY_NAME_SUGGESTIONS]
            : []
        }
        usedTestJourneys={usedTestJourneySet}
        onPressRecentJourney={handlePressRecentJourney}
        onPressTestJourney={handlePressTestJourney}
        suggestionLayout="horizontal_rows"
        loading={false}
        canStart
        onStart={() => {
          void handleStart();
        }}
      />
    </ScrollView>
  );
}
