/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { Pressable, Switch, Text, View } from 'react-native';
import type { BooleanCollector } from '@ping-identity/rn-davinci';
import { davinciFieldStyles } from '../../../../src/styles/davinciStyles';
import RichTextLabel from './RichTextLabel';
import type { DaVinciCollectorRendererProps } from './types';

/**
 * Renders a {@link BooleanCollector} as a checkbox row or a switch toggle,
 * depending on the collector's `appearance` field.
 *
 * @param props Renderer props.
 * @returns Boolean field element.
 */
export default function DaVinciBooleanField(
  props: DaVinciCollectorRendererProps,
): React.ReactElement {
  const { collector, value, onChange } = props;
  const booleanCollector = collector as BooleanCollector;
  const checked = typeof value === 'boolean' ? value : booleanCollector.value;
  const showError =
    booleanCollector.required && !checked && booleanCollector.errorMessage;

  if (booleanCollector.appearance === 'SWITCH') {
    return (
      <View style={davinciFieldStyles.card}>
        <View style={styles.switchRow}>
          <View style={styles.switchLabel}>
            <RichTextLabel
              text={booleanCollector.label}
              richContent={booleanCollector.richContent}
              style={davinciFieldStyles.fieldLabel}
            />
            {booleanCollector.required ? (
              <Text style={davinciFieldStyles.fieldLabel}> *</Text>
            ) : null}
          </View>
          <Switch
            value={checked}
            onValueChange={next => onChange(next)}
            accessibilityLabel={booleanCollector.label}
          />
        </View>
        {showError ? (
          <Text style={davinciFieldStyles.errorText}>
            {booleanCollector.errorMessage}
          </Text>
        ) : null}
      </View>
    );
  }

  return (
    <View style={davinciFieldStyles.card}>
      <Pressable
        style={styles.checkboxRow}
        onPress={() => onChange(!checked)}
        accessibilityRole="checkbox"
        accessibilityState={{ checked }}
        accessibilityLabel={booleanCollector.label}
      >
        <View
          style={[
            davinciFieldStyles.optionCheckbox,
            checked && davinciFieldStyles.optionCheckboxSelected,
          ]}
        >
          {checked ? <Text style={styles.checkmark}>✓</Text> : null}
        </View>
        <RichTextLabel
          text={booleanCollector.label}
          richContent={booleanCollector.richContent}
          style={davinciFieldStyles.fieldLabel}
        />
        {booleanCollector.required ? (
          <Text style={davinciFieldStyles.fieldLabel}> *</Text>
        ) : null}
      </Pressable>
      {showError ? (
        <Text style={davinciFieldStyles.errorText}>
          {booleanCollector.errorMessage}
        </Text>
      ) : null}
    </View>
  );
}

const styles = {
  switchRow: {
    flexDirection: 'row' as const,
    alignItems: 'center' as const,
    justifyContent: 'space-between' as const,
  },
  switchLabel: {
    flex: 1,
    marginRight: 8,
  },
  checkboxRow: {
    flexDirection: 'row' as const,
    alignItems: 'center' as const,
  },
  checkmark: {
    color: '#fff',
    fontSize: 12,
    fontWeight: '700' as const,
  },
};
