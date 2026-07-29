/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useState } from 'react';
import { Alert, Pressable, ScrollView, Text, View } from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type {
  DeviceByKind,
  DeviceKind,
  DeviceOf,
} from '@ping-identity/rn-device-client';
import { formatError } from './utils/formatError';
import { useDevices } from '../src/hooks/useDevices';
import { commonStyles } from '../src/styles/common';
import type { RootStackParamList } from '../App';
import DeviceRadioGroupCard from './devices/components/molecules/DeviceRadioGroupCard';
import DeviceRenameModal from './devices/components/molecules/DeviceRenameModal';
import DeviceListCard from './devices/components/organisms/DeviceListCard';
import { DEVICE_TYPES, type DeviceRenameTarget } from './devices/types';

type Props = NativeStackScreenProps<RootStackParamList, 'Devices'>;

/**
 * Device management demo screen.
 *
 * @remarks
 * Wires the sample-app-local `useDevices` hook to a typed UI that lets a
 * user switch between the five supported device kinds (OATH, Push, Bound,
 * WebAuthn, Profile) and rename / delete individual entries.
 *
 * ## Integration pattern
 *
 * The screen is intentionally simple so consumers can copy the pattern:
 *
 * 1. `useState` to track the currently selected device kind.
 * 2. `useDevices(selectedType)` returns `[state, actions]` — the sample app
 *    hook owns fetch / rename / remove against `@ping-identity/rn-device-client`.
 * 3. `<DeviceRadioGroupCard>` renders the kind selector.
 * 4. `<DeviceListCard>` renders the list / loading / empty / error views
 *    driven by `state.status`.
 * 5. `<DeviceRenameModal>` collects the new name and submits through
 *    `actions.rename`.
 * 6. Error handling: the hook surfaces a normalized message on
 *    `state.error`. The `includes('No active Journey session')` check
 *    short-circuits to a "sign in required" empty state rather than
 *    showing the raw bridge error to the user.
 *
 * ## What this screen deliberately skips
 *
 * - No optimistic UI updates — the hook re-fetches after mutations.
 * - No `dispose()` call on unmount — matches Journey's lifecycle
 *   convention (clients are app-scoped, OS reclaims on process exit).
 * - No pagination — the native SDK returns full lists today.
 */
export default function DevicesScreen({
  navigation,
}: Props): React.ReactElement {
  const [selectedType, setSelectedType] = useState<DeviceKind>('oath');
  const [state, actions] = useDevices(selectedType);

  const [renameTarget, setRenameTarget] = useState<DeviceRenameTarget | null>(
    null,
  );

  const handleDelete = (device: DeviceOf<keyof DeviceByKind>) => {
    actions.remove(device).catch((error: unknown) => {
      console.log(
        '[devices] delete failed — raw error:',
        JSON.stringify(error, Object.getOwnPropertyNames(error ?? {})),
      );
      Alert.alert('Error deleting device', formatError(error));
    });
  };

  const handleOpenEdit = (device: DeviceOf<keyof DeviceByKind>) => {
    setRenameTarget({ kind: selectedType, device, draft: device.deviceName });
  };

  const handleConfirmEdit = () => {
    if (!renameTarget || !renameTarget.draft.trim()) return;
    const { kind, device, draft } = renameTarget;
    setRenameTarget(null);
    if (kind !== selectedType) {
      return;
    }
    actions.rename(device, draft.trim()).catch((error: unknown) => {
      Alert.alert('Error editing device', formatError(error));
    });
  };

  const handleRenameDraftChange = (draft: string) => {
    setRenameTarget(current => (current ? { ...current, draft } : current));
  };

  if (state.error?.includes('No active Journey session')) {
    return (
      <View style={commonStyles.container}>
        <View style={commonStyles.userProfileEmptyCard}>
          <Text style={commonStyles.userProfileEmptyTitle}>
            Session required
          </Text>
          <Text style={commonStyles.userProfileSubText}>
            Sign in via Journey first to manage your devices.
          </Text>
          <Pressable
            style={commonStyles.buttonPrimary}
            onPress={() => navigation.navigate('JourneyRoute')}
          >
            <Text style={commonStyles.buttonText}>Sign in</Text>
          </Pressable>
        </View>
      </View>
    );
  }

  return (
    <ScrollView
      style={commonStyles.deviceContainer}
      contentContainerStyle={commonStyles.deviceContentContainer}
    >
      <DeviceRadioGroupCard
        title="Filter by Device Type:"
        options={DEVICE_TYPES}
        selectedKey={selectedType}
        testIdPrefix="device-type"
        onSelect={setSelectedType}
      />

      <DeviceListCard
        selectedType={selectedType}
        devices={state.devices}
        status={state.status}
        error={state.error}
        onRefresh={actions.refresh}
        onEdit={handleOpenEdit}
        onDelete={handleDelete}
      />

      <DeviceRenameModal
        renameTarget={renameTarget}
        onDismiss={() => setRenameTarget(null)}
        onDraftChange={handleRenameDraftChange}
        onSubmit={handleConfirmEdit}
      />
    </ScrollView>
  );
}
