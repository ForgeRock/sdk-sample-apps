/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import {
  Alert,
  Clipboard,
  Platform,
  ScrollView,
  Text,
  ToastAndroid,
  View,
  TouchableOpacity,
} from 'react-native';
import { commonStyles } from '../../../../src/styles/common';
import { journeyDebugPanelStyles as styles } from '../../../../src/styles/journeyStyles';
import {
  type JourneyDebugEntry,
  debugPayloadToString,
} from '../../utils/debug';

/**
 * Props for Journey debug panel.
 */
export type JourneyDebugPanelProps = {
  /**
   * Ordered debug entries to render, newest first.
   */
  entries: JourneyDebugEntry[];
  /**
   * Clears all currently displayed debug entries.
   */
  onClear: () => void;
};

/**
 * Renders an on-screen debug trace for Journey callback/test validation.
 *
 * @param props - Panel input props.
 * @returns Debug panel element.
 */
export default function JourneyDebugPanel(
  props: JourneyDebugPanelProps,
): React.ReactElement {
  const { entries, onClear } = props;

  /**
   * Builds a plain-text copy payload for one debug entry.
   *
   * @param entry - Debug entry to serialize.
   * @returns Copy-friendly string.
   */
  const toCopyText = (entry: JourneyDebugEntry): string => {
    const header = `[${entry.timestamp}] ${entry.title}`;
    if (entry.payload === undefined) {
      return header;
    }
    return `${header}\n${debugPayloadToString(entry.payload)}`;
  };

  /**
   * Copies one debug entry to the system clipboard and shows UX confirmation.
   *
   * @param entry - Debug entry to copy.
   */
  const copyEntry = (entry: JourneyDebugEntry): void => {
    Clipboard.setString(toCopyText(entry));

    if (Platform.OS === 'android') {
      ToastAndroid.show('Debug log copied', ToastAndroid.SHORT);
      return;
    }

    Alert.alert('Copied', 'Debug log copied to clipboard.');
  };

  return (
    <View style={commonStyles.card}>
      <View style={styles.headerRow}>
        <Text style={styles.title}>Journey Debug</Text>
        <TouchableOpacity
          style={styles.clearButton}
          onPress={onClear}
          disabled={entries.length === 0}
        >
          <Text style={styles.clearButtonText}>Clear</Text>
        </TouchableOpacity>
      </View>

      {entries.length === 0 ? (
        <Text style={styles.emptyText}>No debug events yet.</Text>
      ) : (
        entries.map(entry => (
          <View key={entry.id} style={styles.eventCard}>
            <View style={styles.eventHeaderRow}>
              <Text style={styles.eventTitle}>
                [{entry.timestamp}] {entry.title}
              </Text>
              <TouchableOpacity
                style={styles.copyButton}
                onPress={() => {
                  copyEntry(entry);
                }}
              >
                <Text style={styles.copyButtonText}>Copy</Text>
              </TouchableOpacity>
            </View>
            {entry.payload !== undefined ? (
              <ScrollView
                style={styles.payloadScroll}
                nestedScrollEnabled
                keyboardShouldPersistTaps="handled"
                showsVerticalScrollIndicator
                onStartShouldSetResponderCapture={(): boolean => true}
                onMoveShouldSetResponderCapture={(): boolean => true}
              >
                <Text style={commonStyles.codeText}>
                  {debugPayloadToString(entry.payload)}
                </Text>
              </ScrollView>
            ) : null}
          </View>
        ))
      )}
    </View>
  );
}
