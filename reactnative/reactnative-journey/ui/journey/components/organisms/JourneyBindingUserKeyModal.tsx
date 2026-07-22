/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useState } from 'react';
import { FlatList, Modal, Text, TouchableOpacity, View } from 'react-native';
import { commonStyles } from '../../../../src/styles/common';
import type { UserKeyOption } from '@ping-identity/rn-binding';

/**
 * Active key selection request payload.
 */
export type JourneyBindingUserKeyRequest = {
  /**
   * Available registered user keys.
   */
  userKeys: UserKeyOption[];
  /**
   * Resolves pending native key selection request.
   */
  onSelect: (key: UserKeyOption) => void;
  /**
   * Cancels pending native key selection request.
   */
  onCancel: () => void;
};

/**
 * Props for the Journey user-key selection modal.
 */
export type JourneyBindingUserKeyModalProps = {
  /**
   * Active request, or null when no key picker is needed.
   */
  request: JourneyBindingUserKeyRequest | null;
};

/**
 * Renders app-owned key selection UI for Binding custom selector flow.
 *
 * @param props - Component props.
 * @returns Modal element.
 */
export default function JourneyBindingUserKeyModal(
  props: JourneyBindingUserKeyModalProps,
): React.ReactElement {
  const { request } = props;
  const [selectedKeyId, setSelectedKeyId] = useState<string | null>(null);
  const effectiveSelectedKeyId =
    selectedKeyId ?? request?.userKeys[0]?.id ?? null;

  return (
    <Modal
      visible={request !== null}
      transparent
      animationType="fade"
      onRequestClose={() => {
        request?.onCancel();
        setSelectedKeyId(null);
      }}
    >
      <View
        style={{
          flex: 1,
          justifyContent: 'center',
          backgroundColor: 'rgba(0,0,0,0.5)',
          padding: 24,
        }}
      >
        <View style={commonStyles.card}>
          <Text style={{ fontSize: 18, fontWeight: 'bold', marginBottom: 12 }}>
            Select Account
          </Text>
          <FlatList
            data={request?.userKeys ?? []}
            keyExtractor={item => item.id}
            renderItem={({ item }) => {
              const isSelected = item.id === effectiveSelectedKeyId;
              return (
                <TouchableOpacity
                  onPress={() => setSelectedKeyId(item.id)}
                  style={{
                    padding: 12,
                    marginBottom: 8,
                    borderRadius: 8,
                    borderWidth: 1,
                    borderColor: isSelected ? '#007AFF' : '#ccc',
                    backgroundColor: isSelected ? '#EAF3FF' : '#fff',
                  }}
                >
                  <Text style={{ fontWeight: '600' }}>{item.username}</Text>
                  <Text style={{ fontSize: 12, color: '#666', marginTop: 2 }}>
                    {item.authenticationType}
                  </Text>
                </TouchableOpacity>
              );
            }}
            style={{ maxHeight: 240, marginBottom: 16 }}
          />
          <TouchableOpacity
            style={[
              commonStyles.buttonPrimary,
              !selectedKeyId && { opacity: 0.4 },
            ]}
            disabled={!selectedKeyId}
            onPress={() => {
              const key = request?.userKeys.find(
                item => item.id === effectiveSelectedKeyId,
              );
              if (key) {
                request?.onSelect(key);
                setSelectedKeyId(null);
              }
            }}
          >
            <Text style={commonStyles.buttonText}>Confirm</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[commonStyles.buttonSecondary, { marginTop: 8 }]}
            onPress={() => {
              request?.onCancel();
              setSelectedKeyId(null);
            }}
          >
            <Text style={commonStyles.buttonTextSecondary}>Cancel</Text>
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  );
}
