/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useState } from 'react';
import {
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '../App';
import {
  CONFIG_FIELDS,
  CONFIG_KIND_TITLES,
  validateFields,
  type ConfigFields,
  type ConfigKind,
} from '../src/config/customConfigs';
import { colors } from '../src/styles/colors';
import { commonStyles } from '../src/styles/common';

type Props = NativeStackScreenProps<RootStackParamList, 'ConfigEditor'> & {
  onAdd: (kind: ConfigKind, fields: ConfigFields) => void;
  onUpdate: (id: string, fields: ConfigFields) => void;
};

/**
 * Add/edit form for a custom configuration of one kind.
 *
 * @param props Screen props.
 * @returns Config editor screen.
 */
export default function ConfigEditorScreen(props: Props): React.ReactElement {
  const { navigation, route, onAdd, onUpdate } = props;
  const { kind, initialFields, editingId } = route.params;
  const [fields, setFields] = useState<ConfigFields>(initialFields);
  const [error, setError] = useState<string | null>(null);

  const handleSave = () => {
    const message = validateFields(kind, fields);
    if (message) {
      setError(message);
      return;
    }
    navigation.goBack();
    // Save after the pop is recorded: saving can rebuild the providers, which
    // restores the last recorded navigation state.
    setTimeout(() => {
      if (editingId) {
        onUpdate(editingId, fields);
      } else {
        onAdd(kind, fields);
      }
    }, 0);
  };

  return (
    <ScrollView
      style={commonStyles.configScreen}
      contentContainerStyle={commonStyles.configScreenContent}
      keyboardShouldPersistTaps="handled"
    >
      <Text style={commonStyles.configSectionTitle}>
        {editingId ? 'Edit' : 'Add'} {CONFIG_KIND_TITLES[kind]} Config
      </Text>
      {CONFIG_FIELDS[kind].map(field => (
        <View key={field.key}>
          <Text style={commonStyles.configOptionMeta}>
            {field.label}
            {field.required ? ' *' : ''}
            {field.hint ? ` (${field.hint})` : ''}
          </Text>
          <TextInput
            style={styles.input}
            value={fields[field.key] ?? ''}
            onChangeText={text =>
              setFields(current => ({ ...current, [field.key]: text }))
            }
            autoCapitalize="none"
            autoCorrect={false}
            accessibilityLabel={field.label}
          />
        </View>
      ))}
      {error ? <Text style={commonStyles.textError}>{error}</Text> : null}
      <Pressable style={commonStyles.buttonPrimary} onPress={handleSave}>
        <Text style={commonStyles.buttonText}>Save</Text>
      </Pressable>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  input: {
    borderWidth: 1,
    borderColor: colors.textDark,
    borderRadius: 8,
    padding: 12,
    marginTop: 4,
    marginBottom: 12,
    color: colors.textDark,
  },
});
