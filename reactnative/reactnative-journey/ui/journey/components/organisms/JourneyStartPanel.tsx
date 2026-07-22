/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import {
  ActivityIndicator,
  ScrollView,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { colors } from '../../../../src/styles/colors';
import { commonStyles } from '../../../../src/styles/common';
import { journeyStartPanelStyles as styles } from '../../../../src/styles/journeyStyles';
import PingTextInput from '../../../components/atoms/PingTextInput';

/**
 * Props for the Journey start panel.
 */
export type JourneyStartPanelProps = {
  showJourneyInput: boolean;
  journeyName: string;
  onJourneyNameChange: (value: string) => void;
  recentJourneys: string[];
  testJourneys: string[];
  usedTestJourneys: ReadonlySet<string>;
  onPressRecentJourney: (journeyName: string) => void;
  onPressTestJourney: (journeyName: string) => void;
  suggestionLayout?: 'horizontal_rows' | 'wrap';
  loading: boolean;
  canStart: boolean;
  onStart: () => void;
};

/**
 * Distributes suggestion labels across fixed visual rows.
 *
 * @param suggestions - Suggested journey names.
 * @param rowCount - Number of visual rows.
 * @returns Suggestions grouped by row.
 */
function buildSuggestionRows(
  suggestions: string[],
  rowCount: number,
): string[][] {
  const rows: string[][] = Array.from({ length: rowCount }, () => []);
  suggestions.forEach((suggestion, index) => {
    rows[index % rowCount].push(suggestion);
  });
  return rows.filter(row => row.length > 0);
}

/**
 * Renders journey name input, suggestions, loading indicator, and start action.
 *
 * @param props - Component props.
 * @returns Journey start panel markup.
 */
export default function JourneyStartPanel(
  props: JourneyStartPanelProps,
): React.ReactElement {
  const {
    showJourneyInput,
    journeyName,
    onJourneyNameChange,
    recentJourneys,
    testJourneys,
    onPressRecentJourney,
    onPressTestJourney,
    suggestionLayout = 'horizontal_rows',
    loading,
    canStart,
    onStart,
  } = props;
  const useWrappedSuggestions = suggestionLayout === 'wrap';
  const testJourneyRows = buildSuggestionRows(testJourneys, 1);
  const recentJourneyRows = buildSuggestionRows(recentJourneys, 1);

  return (
    <>
      {showJourneyInput ? (
        <>
          <PingTextInput
            label="Journey name"
            placeholder="Enter journey name"
            value={journeyName}
            onChangeText={onJourneyNameChange}
            autoCapitalize="none"
          />
          {testJourneys.length > 0 ? (
            <View style={styles.suggestionPanel}>
              <Text style={styles.suggestionPanelTitle}>AM Test Journeys</Text>
              {useWrappedSuggestions ? (
                <View
                  style={[
                    commonStyles.suggestionContainer,
                    styles.wrappedSuggestionContainer,
                  ]}
                >
                  {testJourneys.map(name => {
                    return (
                      <TouchableOpacity
                        key={`test-wrap-${name}`}
                        onPress={() => onPressTestJourney(name)}
                        style={commonStyles.suggestionChip}
                      >
                        <Text style={commonStyles.suggestionText}>{name}</Text>
                      </TouchableOpacity>
                    );
                  })}
                </View>
              ) : (
                <ScrollView
                  horizontal
                  style={styles.suggestionScroll}
                  contentContainerStyle={styles.suggestionScrollContent}
                  showsHorizontalScrollIndicator={false}
                  nestedScrollEnabled
                  directionalLockEnabled
                  keyboardShouldPersistTaps="handled"
                >
                  <View style={styles.suggestionRowsContainer}>
                    {testJourneyRows.map((row, rowIndex) => (
                      <View
                        key={`test-journey-row-${rowIndex}`}
                        style={styles.suggestionRow}
                      >
                        {row.map(name => {
                          return (
                            <TouchableOpacity
                              key={`test-${rowIndex}-${name}`}
                              onPress={() => onPressTestJourney(name)}
                              style={commonStyles.suggestionChip}
                            >
                              <Text style={commonStyles.suggestionText}>
                                {name}
                              </Text>
                            </TouchableOpacity>
                          );
                        })}
                      </View>
                    ))}
                  </View>
                </ScrollView>
              )}
            </View>
          ) : null}

          {recentJourneys.length > 0 ? (
            <View style={styles.suggestionPanel}>
              <Text style={styles.suggestionPanelTitle}>Recent Journeys</Text>
              {useWrappedSuggestions ? (
                <View
                  style={[
                    commonStyles.suggestionContainer,
                    styles.wrappedSuggestionContainer,
                  ]}
                >
                  {recentJourneys.map(name => (
                    <TouchableOpacity
                      key={`recent-wrap-${name}`}
                      onPress={() => onPressRecentJourney(name)}
                      style={commonStyles.suggestionChip}
                    >
                      <Text style={commonStyles.suggestionText}>{name}</Text>
                    </TouchableOpacity>
                  ))}
                </View>
              ) : (
                <ScrollView
                  horizontal
                  style={styles.suggestionScroll}
                  contentContainerStyle={styles.suggestionScrollContent}
                  showsHorizontalScrollIndicator={false}
                  nestedScrollEnabled
                  directionalLockEnabled
                  keyboardShouldPersistTaps="handled"
                >
                  <View style={styles.suggestionRowsContainer}>
                    {recentJourneyRows.map((row, rowIndex) => (
                      <View
                        key={`recent-journey-row-${rowIndex}`}
                        style={styles.suggestionRow}
                      >
                        {row.map(name => (
                          <TouchableOpacity
                            key={`recent-${rowIndex}-${name}`}
                            onPress={() => onPressRecentJourney(name)}
                            style={commonStyles.suggestionChip}
                          >
                            <Text style={commonStyles.suggestionText}>
                              {name}
                            </Text>
                          </TouchableOpacity>
                        ))}
                      </View>
                    ))}
                  </View>
                </ScrollView>
              )}
            </View>
          ) : null}
        </>
      ) : null}

      {loading ? (
        <ActivityIndicator size="large" color={colors.primary} />
      ) : null}

      {canStart ? (
        <TouchableOpacity
          style={commonStyles.buttonPrimary}
          onPress={onStart}
          disabled={loading}
        >
          <Text style={commonStyles.buttonText}>Start Journey</Text>
        </TouchableOpacity>
      ) : null}
    </>
  );
}
