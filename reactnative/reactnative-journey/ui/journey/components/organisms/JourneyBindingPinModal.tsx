/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useState } from 'react';
import { Modal, Text, TouchableOpacity, View } from 'react-native';
import { commonStyles } from '../../../../src/styles/common';
import type { BindingPrompt } from '@ping-identity/rn-binding';
import PingTextInput from '../../../components/atoms/PingTextInput';

/**
 * Active PIN prompt request payload.
 */
export type JourneyBindingPinRequest = {
  /**
   * Prompt metadata from native SDK.
   */
  prompt: BindingPrompt;
  /**
   * Resolves pending native PIN request with entered value.
   */
  onSubmit: (pin: string) => void;
  /**
   * Cancels pending native PIN request.
   */
  onCancel: () => void;
};

/**
 * Props for the Journey PIN prompt modal.
 */
export type JourneyBindingPinModalProps = {
  /**
   * Active PIN request, or null when no PIN prompt is needed.
   */
  request: JourneyBindingPinRequest | null;
};

/**
 * Renders app-owned PIN collection UI for Binding custom collector flow.
 *
 * @param props - Component props.
 * @returns Modal element.
 */
export default function JourneyBindingPinModal(
  props: JourneyBindingPinModalProps,
): React.ReactElement {
  const { request } = props;
  const [pinValue, setPinValue] = useState('');

  return (
    <Modal
      visible={request !== null}
      transparent
      animationType="fade"
      onRequestClose={() => {
        request?.onCancel();
        setPinValue('');
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
          <Text
            style={{
              fontSize: 18,
              fontWeight: 'bold',
              marginBottom: 8,
              color: '#111827',
            }}
          >
            {request?.prompt.title}
          </Text>
          {request?.prompt.subtitle ? (
            <Text style={{ marginBottom: 8, color: '#1f2937' }}>
              {request.prompt.subtitle}
            </Text>
          ) : null}
          {request?.prompt.description ? (
            <Text style={{ marginBottom: 12, color: '#374151' }}>
              {request.prompt.description}
            </Text>
          ) : null}
          <PingTextInput
            secureTextEntry
            keyboardType="number-pad"
            label="PIN"
            value={pinValue}
            onChangeText={setPinValue}
            containerStyle={{
              marginBottom: 16,
            }}
          />
          <TouchableOpacity
            style={commonStyles.buttonPrimary}
            onPress={() => {
              request?.onSubmit(pinValue);
              setPinValue('');
            }}
          >
            <Text style={commonStyles.buttonText}>Confirm</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[commonStyles.buttonSecondary, { marginTop: 8 }]}
            onPress={() => {
              request?.onCancel();
              setPinValue('');
            }}
          >
            <Text style={commonStyles.buttonTextSecondary}>Cancel</Text>
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  );
}
