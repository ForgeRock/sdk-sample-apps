/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useCallback, useEffect, useRef, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import MaterialIcon from 'react-native-vector-icons/MaterialIcons';
import { createOathClient } from '@ping-identity/rn-oath';
import type { OathClient, OathCredential } from '@ping-identity/rn-oath';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { commonStyles } from '../src/styles/common';
import { colors } from '../src/styles/colors';
import { useOathTimer } from '../src/hooks/useOathTimer';
import OathCredentialCard from './oath/components/molecules/OathCredentialCard';
import ManualOathRegistrationModal from './oath/components/molecules/ManualOathRegistrationModal';
import OathAccountDetailModal from './oath/components/organisms/OathAccountDetailModal';
import type { RootStackParamList } from '../App';

type OathStatus = 'idle' | 'loading' | 'ready' | 'error';
type Props = NativeStackScreenProps<RootStackParamList, 'OathTokens'>;

/**
 * Converts an unknown error value to a display string.
 *
 * @param err - Unknown error value.
 * @returns A human-readable error message.
 */
function formatError(err: unknown): string {
  if (err && typeof err === 'object' && 'message' in err) {
    return String((err as { message?: string }).message ?? 'Unknown error');
  }
  return String(err);
}

/**
 * Screen for managing locally stored OATH credentials.
 *
 * Allows enrolling credentials via QR code scan, URI paste, or manual
 * form entry, viewing live TOTP codes with countdown timers, generating
 * HOTP codes on demand, copying codes to clipboard, and deleting credentials.
 *
 * @param props - Navigation stack props for the `OathTokens` route.
 * @returns OATH tokens screen element.
 */
export default function OathTokensScreen({
  navigation,
}: Props): React.ReactElement {
  const clientRef = useRef<OathClient | null>(null);
  const [client, setClient] = useState<OathClient | null>(null);

  const [credentials, setCredentials] = useState<OathCredential[]>([]);
  const [status, setStatus] = useState<OathStatus>('idle');
  const [error, setError] = useState<string | null>(null);
  const [uriInput, setUriInput] = useState('');
  const [showManualForm, setShowManualForm] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [selectedCredential, setSelectedCredential] =
    useState<OathCredential | null>(null);

  const { codes, refreshCode } = useOathTimer(client, credentials);

  const loadCredentials = useCallback(async (): Promise<void> => {
    if (clientRef.current === null) return;
    setStatus('loading');
    setError(null);
    try {
      const result = await clientRef.current.getCredentials();
      setCredentials(result);
      setStatus('ready');
    } catch (err) {
      setError(formatError(err));
      setStatus('error');
    }
  }, []);

  // Ensure the client is closed when the screen is unmounted entirely.
  // The blur listener handles closing during forward navigation; this covers
  // the final unmount when the screen is popped from the stack.
  useEffect(() => {
    return () => {
      void clientRef.current?.close();
      clientRef.current = null;
    };
  }, []);

  // Close the client when another screen is pushed on top (e.g. QRScanner) so
  // only one native OATH handle is open at a time. Reopen and reload when this
  // screen comes back into focus.
  useEffect(() => {
    const unsubBlur = navigation.addListener('blur', () => {
      void clientRef.current?.close();
      clientRef.current = null;
      setClient(null);
    });

    const unsubFocus = navigation.addListener('focus', () => {
      if (clientRef.current !== null) {
        // Already open (e.g. initial focus before any navigation away).
        void loadCredentials();
        return;
      }
      createOathClient()
        .then(c => {
          clientRef.current = c;
          setClient(c);
          void loadCredentials();
        })
        .catch(err => setError(formatError(err)));
    });

    return () => {
      unsubBlur();
      unsubFocus();
    };
  }, [navigation, loadCredentials]);

  const handleAddFromUri = async (): Promise<void> => {
    const raw = uriInput.trim();
    if (!raw) return;
    const client = clientRef.current;
    if (client === null) return;

    try {
      await client.addCredentialFromUri(raw);
      setUriInput('');
      await loadCredentials();
    } catch (err) {
      Alert.alert('Error', formatError(err));
    }
  };

  const handleDeleteCredential = async (id: string): Promise<void> => {
    const c = clientRef.current;
    if (c === null) {
      Alert.alert('Error', 'OATH client is not ready.');
      return;
    }
    try {
      await c.deleteCredential(id);
      setSelectedCredential(null);
      await loadCredentials();
    } catch (err) {
      Alert.alert('Error', formatError(err));
    }
  };

  const handleManualSubmit = async (uri: string): Promise<void> => {
    const client = clientRef.current;
    if (client === null) return;
    try {
      await client.addCredentialFromUri(uri);
      await loadCredentials();
    } catch (err) {
      Alert.alert('Error', formatError(err));
    }
  };

  const handleRefresh = useCallback(async (): Promise<void> => {
    setRefreshing(true);
    await loadCredentials();
    setRefreshing(false);
  }, [loadCredentials]);

  return (
    <>
      <ScrollView
        style={commonStyles.deviceContainer}
        contentContainerStyle={commonStyles.deviceContentContainer}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={handleRefresh}
            tintColor={colors.primary}
          />
        }
      >
        {/* Toolbar card */}
        <View style={commonStyles.deviceListCard}>
          <View style={commonStyles.deviceListHeader}>
            <Text style={commonStyles.deviceListTitle}>
              {`OATH Tokens (${credentials.length})`}
            </Text>
            <Pressable
              testID="oath-refresh"
              onPress={loadCredentials}
              style={commonStyles.deviceRefreshButton}
            >
              <MaterialIcon name="refresh" size={24} color={colors.primary} />
            </Pressable>
            <Pressable
              testID="oath-scan-btn"
              onPress={() => navigation.navigate('QRScanner')}
              style={commonStyles.deviceIconButton}
            >
              <MaterialIcon
                name="qr-code-scanner"
                size={24}
                color={colors.primary}
              />
            </Pressable>
            <Pressable
              testID="oath-manual-btn"
              onPress={() => setShowManualForm(true)}
              style={commonStyles.deviceIconButton}
            >
              <MaterialIcon
                name="add-circle"
                size={24}
                color={colors.primary}
              />
            </Pressable>
          </View>
        </View>

        {/* URI input card */}
        <View style={[commonStyles.deviceListCard, { marginTop: 8 }]}>
          <Text style={commonStyles.deviceListTitle}>Add by URI</Text>
          <TextInput
            testID="oath-uri-input"
            style={[
              commonStyles.deviceModalInput,
              { marginTop: 8, marginBottom: 8 },
            ]}
            placeholder="otpauth:// or mfauth://"
            placeholderTextColor={colors.inputPlaceholder}
            value={uriInput}
            onChangeText={setUriInput}
            autoCapitalize="none"
            autoCorrect={false}
          />
          <Pressable
            testID="oath-add-btn"
            style={[
              commonStyles.buttonPrimary,
              (!uriInput.trim() || client === null) && {
                opacity: 0.5,
              },
            ]}
            onPress={handleAddFromUri}
            disabled={!uriInput.trim() || client === null}
          >
            <Text style={commonStyles.buttonText}>Add</Text>
          </Pressable>
        </View>

        {/* Loading indicator */}
        {status === 'loading' ? (
          <View style={commonStyles.deviceLoadingContainer}>
            <ActivityIndicator size="large" color={colors.primary} />
          </View>
        ) : null}

        {/* Error display */}
        {error !== null ? (
          <Text style={commonStyles.deviceErrorText}>{error}</Text>
        ) : null}

        {/* Empty state */}
        {status === 'ready' && credentials.length === 0 ? (
          <View style={emptyStyles.container}>
            <MaterialIcon name="key" size={48} color={colors.gray} />
            <Text style={emptyStyles.title}>No OATH Accounts</Text>
            <Text style={emptyStyles.subtitle}>
              Add your first account using QR code or manual entry
            </Text>
            <View style={emptyStyles.actionRow}>
              <Pressable
                testID="oath-empty-scan-btn"
                style={emptyStyles.actionCard}
                onPress={() => navigation.navigate('QRScanner')}
              >
                <MaterialIcon
                  name="qr-code-scanner"
                  size={28}
                  color={colors.primary}
                />
                <Text style={emptyStyles.actionLabel}>Scan QR</Text>
              </Pressable>
              <Pressable
                testID="oath-empty-manual-btn"
                style={emptyStyles.actionCard}
                onPress={() => setShowManualForm(true)}
              >
                <MaterialIcon
                  name="keyboard"
                  size={28}
                  color={colors.primary}
                />
                <Text style={emptyStyles.actionLabel}>Manual Entry</Text>
              </Pressable>
            </View>
          </View>
        ) : null}

        {/* Credential list */}
        {credentials.map(c => (
          <OathCredentialCard
            key={c.id}
            credential={c}
            codeInfo={codes.get(c.id)}
            onPress={() => setSelectedCredential(c)}
            onRefreshHotp={() => refreshCode(c.id)}
          />
        ))}
      </ScrollView>

      <ManualOathRegistrationModal
        visible={showManualForm}
        onDismiss={() => setShowManualForm(false)}
        onSubmit={uri => {
          setShowManualForm(false);
          void handleManualSubmit(uri);
        }}
      />

      <OathAccountDetailModal
        visible={selectedCredential !== null}
        credential={selectedCredential}
        codeInfo={
          selectedCredential !== null
            ? codes.get(selectedCredential.id)
            : undefined
        }
        onDismiss={() => setSelectedCredential(null)}
        onDelete={() =>
          selectedCredential !== null
            ? void handleDeleteCredential(selectedCredential.id)
            : undefined
        }
        onRefreshHotp={() =>
          selectedCredential !== null
            ? refreshCode(selectedCredential.id)
            : undefined
        }
      />
    </>
  );
}

const emptyStyles = StyleSheet.create({
  container: {
    alignItems: 'center',
    paddingVertical: 40,
    paddingHorizontal: 24,
  },
  title: {
    fontSize: 18,
    fontWeight: '600',
    color: colors.textDark,
    marginTop: 16,
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 14,
    color: colors.gray,
    textAlign: 'center',
    marginBottom: 24,
  },
  actionRow: {
    flexDirection: 'row',
    gap: 16,
  },
  actionCard: {
    width: 120,
    height: 100,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.surface,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.border,
    gap: 8,
  },
  actionLabel: {
    fontSize: 14,
    fontWeight: '500',
    color: colors.textDark,
  },
});
