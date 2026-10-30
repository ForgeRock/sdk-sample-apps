/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useMemo } from 'react';
import { ScrollView, StyleSheet, Text, View } from 'react-native';
import type { FidoCollector } from '@ping-identity/rn-fido';
import type { IdpCollector } from '@ping-identity/rn-external-idp';
import type {
  ContinueNode,
  DaVinciFormResult,
  DaVinciNormalizedCollector,
  PollingCollector,
  PollingStatus,
  UnsupportedDaVinciField,
  DaVinciFormValue,
  DaVinciFieldValidationError,
} from '@ping-identity/rn-davinci';
import { commonStyles } from '../../../../src/styles/common';
import { colors } from '../../../../src/styles/colors';
import { davinciScreenStyles } from '../../../../src/styles/davinciStyles';
import AsyncActionButton from '../../../components/molecules/AsyncActionButton';
import DaVinciFieldRenderer from '../molecules/DaVinciFieldRenderer';

/**
 * Renders the raw node JSON below the form. Enable locally while debugging
 * collector payloads; keep disabled otherwise.
 */
const SHOW_DEBUG_PANEL = false;

/**
 * Props for {@link DaVinciContinueNodePanel}.
 */
export type DaVinciContinueNodePanelProps = {
  /**
   * Active continue node returned by the bridge.
   */
  node: ContinueNode;
  /**
   * Headless form state produced by `useDaVinciForm` for the active node.
   */
  form: DaVinciFormResult;
  /**
   * True while a DaVinci action is in flight.
   */
  loading: boolean;
  /**
   * Submits the current form by calling `next` with the planned payload.
   */
  onSubmit: () => void;
  /**
   * Validates the current value for a collector.
   *
   * @param collectorKey Collector key to validate.
   * @param value Current rendered value for the collector.
   * @returns Validation errors for the collector.
   */
  onValidate: (
    collectorKey: string,
    value: DaVinciFormValue,
  ) => Promise<DaVinciFieldValidationError[]>;
  /**
   * Submits a flow collector (`SUBMIT_BUTTON`, `ACTION`, `FLOW_BUTTON`,
   * `FLOW_LINK`) by key.
   *
   * @param flowKey Flow collector key.
   */
  onFlowAction: (flowKey: string) => void;
  /**
   * Launches the social login browser flow for an IDP collector.
   *
   * @param collector The IdpCollector to authorize.
   */
  onIdpAuthorize: (collector: IdpCollector) => Promise<void>;
  /**
   * Runs the native passkey ceremony for a FIDO collector.
   *
   * @param collector The FIDO collector to process.
   */
  onFidoCeremony: (collector: FidoCollector) => Promise<void>;
  /**
   * Streams {@link PollingStatus} updates for a {@link PollingCollector}.
   *
   * @param collector The PollingCollector to poll.
   * @param onStatus Callback invoked with each streamed status tick.
   */
  onPollStatus: (
    collector: PollingCollector,
    onStatus: (status: PollingStatus) => void,
  ) => Promise<() => void>;
};

/**
 * Determines whether a collector list already contains a control that submits.
 *
 * @param collectors Normalised collectors for the current node.
 * @returns True when at least one submit or flow collector is present.
 */
function hasInteractiveSubmit(
  collectors: DaVinciNormalizedCollector[],
): boolean {
  return collectors.some(
    collector =>
      collector.type === 'SUBMIT_BUTTON' ||
      collector.type === 'ACTION' ||
      collector.type === 'FLOW_BUTTON' ||
      collector.type === 'FLOW_LINK',
  );
}

/**
 * Renders an unsupported-fields warning when the bridge dropped one or more
 * server-side fields.
 *
 * @param fields Fields the bridge could not instantiate.
 * @returns Warning element, or `null` when nothing to show.
 */
function renderUnsupportedFieldsNotice(
  fields: UnsupportedDaVinciField[] | undefined,
): React.ReactElement | null {
  if (!fields || fields.length === 0) {
    return null;
  }
  return (
    <View style={davinciScreenStyles.errorCard}>
      <Text style={davinciScreenStyles.errorCardTitle}>
        Unsupported fields skipped
      </Text>
      <Text style={davinciScreenStyles.errorCardMessage}>
        {fields.map(field => `${field.key} (${field.type})`).join(', ')}
      </Text>
    </View>
  );
}

/**
 * Renders an active DaVinci {@link ContinueNode} as a vertical form.
 *
 * @remarks
 * Each collector is dispatched to its dedicated molecule via
 * {@link DaVinciFieldRenderer}. A trailing fallback submit button is rendered
 * only when the node lacks any other interactive submit control.
 *
 * @param props Component props.
 * @returns Continue node form element.
 */
const styles = StyleSheet.create({
  formHeader: { marginBottom: 16 },
  formTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: colors.textDark,
    marginBottom: 4,
  },
  formDescription: {
    fontSize: 14,
    color: colors.gray,
  },
  debugPanel: {
    marginTop: 24,
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 4,
    padding: 8,
  },
  debugTitle: {
    fontSize: 12,
    fontWeight: '700',
    marginBottom: 4,
    color: '#666',
  },
  debugScroll: {
    maxHeight: 300,
  },
  debugText: {
    fontSize: 10,
    fontFamily: 'Courier',
    color: '#333',
  },
});

export default function DaVinciContinueNodePanel(
  props: DaVinciContinueNodePanelProps,
): React.ReactElement {
  const {
    node,
    form,
    loading,
    onSubmit,
    onValidate,
    onFlowAction,
    onIdpAuthorize,
    onFidoCeremony,
    onPollStatus,
  } = props;
  const { fields, values, canSubmit, issues, setValue } = form;

  const showFallbackSubmit = useMemo(
    () => !hasInteractiveSubmit(fields),
    [fields],
  );

  return (
    <View>
      {node.name || node.description ? (
        <View style={styles.formHeader}>
          {node.name ? <Text style={styles.formTitle}>{node.name}</Text> : null}
          {node.description ? (
            <Text style={styles.formDescription}>{node.description}</Text>
          ) : null}
        </View>
      ) : null}

      {renderUnsupportedFieldsNotice(node.unsupportedFields)}

      {fields.map(collector => (
        <DaVinciFieldRenderer
          key={collector.key}
          collector={collector}
          value={values[collector.key]}
          onChange={next => setValue(collector.key, next)}
          onValidate={onValidate}
          onSubmit={onSubmit}
          onFlowAction={onFlowAction}
          onIdpAuthorize={onIdpAuthorize}
          onFidoCeremony={onFidoCeremony}
          onPollStatus={onPollStatus}
          loading={loading}
          canSubmit={canSubmit}
        />
      ))}

      {showFallbackSubmit ? (
        <AsyncActionButton
          label="Next"
          onPress={onSubmit}
          loading={loading}
          disabled={!canSubmit}
        />
      ) : null}

      {issues.length > 0 && !canSubmit ? (
        <Text style={commonStyles.textError}>
          Please complete required fields before continuing.
        </Text>
      ) : null}

      {SHOW_DEBUG_PANEL ? (
        <View style={styles.debugPanel}>
          <Text style={styles.debugTitle}>DEBUG: Raw Node JSON</Text>
          <ScrollView style={styles.debugScroll} nestedScrollEnabled>
            <Text style={styles.debugText} selectable>
              {JSON.stringify(node, null, 2)}
            </Text>
          </ScrollView>
        </View>
      ) : null}
    </View>
  );
}
