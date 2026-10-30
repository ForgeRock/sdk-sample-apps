/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Alert } from 'react-native';
import type { SampleAppClientProfile } from '../clients';
import { toFields, type ConfigFields, type ConfigKind } from './customConfigs';

/**
 * Parameters of the config editor route.
 */
export type ConfigEditorParams = {
  kind: ConfigKind;
  initialFields: ConfigFields;
  editingId?: string;
};

/**
 * Add, edit, duplicate and delete handlers for the Configuration screen:
 * duplicating copies immediately, deleting asks
 * for confirmation.
 *
 * @param openEditor Navigates to the config editor.
 * @param addCustomConfig Persists a new custom config.
 * @param deleteCustomConfig Removes a custom config by id.
 * @returns Handlers keyed by action.
 */
export function useConfigActions(
  openEditor: (params: ConfigEditorParams) => void,
  addCustomConfig: (kind: ConfigKind, fields: ConfigFields) => void,
  deleteCustomConfig: (id: string) => void,
) {
  const fieldsOf = (profile: SampleAppClientProfile): ConfigFields =>
    toFields(profile.kind!, profile.name, profile.unifiedConfig!);

  return {
    add: (kind: ConfigKind) => openEditor({ kind, initialFields: {} }),
    edit: (profile: SampleAppClientProfile) =>
      openEditor({
        kind: profile.kind!,
        initialFields: fieldsOf(profile),
        editingId: profile.presetId,
      }),
    duplicate: (profile: SampleAppClientProfile) =>
      addCustomConfig(profile.kind!, {
        ...fieldsOf(profile),
        name: `${profile.name} (copy)`,
      }),
    remove: (profile: SampleAppClientProfile) =>
      Alert.alert('Delete configuration', `Delete '${profile.name}'?`, [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: () => deleteCustomConfig(profile.presetId!),
        },
      ]),
  };
}
