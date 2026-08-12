/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useCallback, useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Pressable,
  ScrollView,
  Text,
  View,
} from 'react-native';
import MaterialIcon from 'react-native-vector-icons/MaterialIcons';
import type { UserKeyOption } from '@ping-identity/rn-binding';
import {
  getAllKeys,
  deleteKey,
  deleteAllKeys,
} from '@ping-identity/rn-binding';
import { formatError } from './utils/formatError';
import { commonStyles } from '../src/styles/common';
import { colors } from '../src/styles/colors';
import DeviceListSeparator from './devices/components/atoms/DeviceListSeparator';

type KeyListStatus = 'idle' | 'loading' | 'ready' | 'error';

/**
 * Developer tools screen for managing locally stored device binding keys.
 *
 * @returns Binding keys screen element.
 */
export default function BindingKeysScreen(): React.ReactElement {
  const [keys, setKeys] = useState<UserKeyOption[]>([]);
  const [status, setStatus] = useState<KeyListStatus>('idle');
  const [error, setError] = useState<string | null>(null);

  const fetchKeys = useCallback(async (): Promise<void> => {
    setStatus('loading');
    setError(null);
    try {
      const result = await getAllKeys();
      setKeys(result);
      setStatus('ready');
    } catch (err) {
      setError(formatError(err));
      setStatus('error');
    }
  }, []);

  useEffect(() => {
    const timeoutId = setTimeout(() => {
      void fetchKeys();
    }, 0);
    return () => clearTimeout(timeoutId);
  }, [fetchKeys]);

  const handleDelete = (key: UserKeyOption) => {
    Alert.alert('Delete Key', `Delete binding key for "${key.username}"?`, [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Delete',
        style: 'destructive',
        onPress: () => {
          deleteKey(key)
            .then(() => fetchKeys())
            .catch((err: unknown) => Alert.alert('Error', formatError(err)));
        },
      },
    ]);
  };

  const handleDeleteAll = () => {
    if (keys.length === 0) return;
    Alert.alert(
      'Delete All Keys',
      'Delete all locally stored binding keys? This cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete All',
          style: 'destructive',
          onPress: () => {
            deleteAllKeys()
              .then(() => fetchKeys())
              .catch((err: unknown) => Alert.alert('Error', formatError(err)));
          },
        },
      ],
    );
  };

  return (
    <ScrollView
      style={commonStyles.deviceContainer}
      contentContainerStyle={commonStyles.deviceContentContainer}
    >
      <View style={commonStyles.deviceListCard}>
        <View style={commonStyles.deviceListHeader}>
          <Text style={commonStyles.deviceListTitle}>
            Binding Keys ({keys.length})
          </Text>
          <Pressable
            testID="binding-keys-refresh"
            onPress={fetchKeys}
            style={commonStyles.deviceRefreshButton}
          >
            <MaterialIcon name="refresh" size={24} color={colors.primary} />
          </Pressable>
          <Pressable
            testID="binding-keys-delete-all"
            onPress={handleDeleteAll}
            disabled={keys.length === 0}
            style={commonStyles.deviceIconButton}
          >
            <MaterialIcon
              name="delete-sweep"
              size={24}
              color={keys.length === 0 ? '#BDBDBD' : colors.error}
            />
          </Pressable>
        </View>

        {status === 'loading' ? (
          <View style={commonStyles.deviceLoadingContainer}>
            <ActivityIndicator size="large" color={colors.primary} />
          </View>
        ) : status === 'error' ? (
          <Text style={commonStyles.deviceErrorText}>
            {error ?? 'Error retrieving binding keys'}
          </Text>
        ) : keys.length === 0 ? (
          <Text style={commonStyles.deviceEmptyText}>
            No binding keys found
          </Text>
        ) : (
          <View testID="binding-keys-list">
            {keys.map((item, index) => (
              <View key={item.id}>
                {index > 0 ? <DeviceListSeparator /> : null}
                <BindingKeyRow
                  key={item.id}
                  userKey={item}
                  onDelete={handleDelete}
                />
              </View>
            ))}
          </View>
        )}
      </View>
    </ScrollView>
  );
}

type BindingKeyRowProps = {
  userKey: UserKeyOption;
  onDelete: (key: UserKeyOption) => void;
};

function BindingKeyRow({
  userKey,
  onDelete,
}: BindingKeyRowProps): React.ReactElement {
  return (
    <View
      testID={`binding-key-row-${userKey.id}`}
      style={[commonStyles.deviceRow, { alignItems: 'flex-start' }]}
    >
      <View style={{ flex: 1 }}>
        <Text style={commonStyles.deviceRowName} numberOfLines={1}>
          {userKey.username}
        </Text>
        <Text style={commonStyles.deviceRowSubtitle} numberOfLines={1}>
          User ID: {userKey.userId}
        </Text>
        <Text style={commonStyles.deviceRowSubtitle} numberOfLines={1}>
          Type: {userKey.authenticationType}
        </Text>
      </View>
      <Pressable
        testID={`binding-key-delete-${userKey.id}`}
        onPress={() => onDelete(userKey)}
        style={commonStyles.deviceIconButton}
      >
        <MaterialIcon name="delete" size={20} color={colors.error} />
      </Pressable>
    </View>
  );
}
