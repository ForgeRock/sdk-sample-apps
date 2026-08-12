/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Alert,
  ScrollView,
  Switch,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import {
  type JourneyCallback,
  type JourneyCallbackInput,
  type JourneyCallbackType,
  type JourneyFormValue,
  type JourneyNextInput,
  useJourney,
} from '@ping-identity/rn-journey';
import {
  callbackType,
  nativeExtensionCallbackType,
} from '@ping-identity/rn-types';
import { formatError } from './utils/formatError';
import { commonStyles } from '../src/styles/common';
import { journeyFullScreenStyles as styles } from '../src/styles/journeyStyles';
import PingTextInput from './components/atoms/PingTextInput';
import PayloadViewer from './components/atoms/PayloadViewer';

/**
 * Callback metadata with deterministic per-type index.
 */
type IndexedCallback = {
  key: string;
  type: JourneyCallbackType;
  typeIndex: number;
  callback: JourneyCallback;
};

/**
 * KBA field state shape for `KbaCreateCallback`.
 */
type KbaInput = {
  selectedQuestion: string;
  selectedAnswer: string;
  allowUserDefinedQuestions: boolean;
};

const outputOnlyCallbackTypes = new Set<JourneyCallbackType>([
  callbackType.TextOutputCallback,
  callbackType.SuspendedTextOutputCallback,
  callbackType.MetadataCallback,
  callbackType.PollingWaitCallback,
  callbackType.DeviceProfileCallback,
]);

const integrationRequiredCallbackTypes = new Set<JourneyCallbackType>([
  callbackType.PingOneProtectInitializeCallback,
  callbackType.PingOneProtectEvaluationCallback,
  // callbackType.SelectIdPCallback is 'SelectIdPCallback' (capital P, ForgeRock JS SDK).
  // The native SDK surfaces this as 'SelectIdpCallback' (lowercase p). Both are registered.
  callbackType.SelectIdPCallback,
  nativeExtensionCallbackType.SelectIdpCallback,
  callbackType.ReCaptchaCallback,
  callbackType.ReCaptchaEnterpriseCallback,
  nativeExtensionCallbackType.IdPCallback,
  nativeExtensionCallbackType.IdpCallback,
  nativeExtensionCallbackType.FidoRegistrationCallback,
  nativeExtensionCallbackType.FidoAuthenticationCallback,
  nativeExtensionCallbackType.BindingCallback,
  nativeExtensionCallbackType.DeviceBindingCallback,
  nativeExtensionCallbackType.DeviceSigningVerifierCallback,
]);

/**
 * Creates deterministic callback references (`<type>:<index>`) for a callback list.
 *
 * @param callbacks - Callback collection from a ContinueNode.
 * @returns Indexed callback entries.
 */
function indexCallbacks(
  callbacks: JourneyCallback[] | undefined,
): IndexedCallback[] {
  if (!callbacks || callbacks.length === 0) {
    return [];
  }

  const counts = new Map<JourneyCallbackType, number>();
  return callbacks.map(callback => {
    const type = callback.type;
    const typeIndex = counts.get(type) ?? 0;
    counts.set(type, typeIndex + 1);
    return {
      key: `${type}:${typeIndex}`,
      type,
      typeIndex,
      callback,
    };
  });
}

/**
 * Resolves UI options for choice-style callbacks.
 *
 * @param callback - Raw callback payload.
 * @returns String labels for each selectable option.
 */
function readOptions(callback: JourneyCallback): string[] {
  const candidate = Array.isArray(callback.options)
    ? callback.options
    : Array.isArray(callback.choices)
      ? callback.choices
      : [];

  return candidate.map((item, index) => {
    if (typeof item === 'string') {
      return item;
    }
    if (item && typeof item === 'object') {
      const label = (item as Record<string, unknown>).label;
      const value = (item as Record<string, unknown>).value;
      if (typeof label === 'string' && label.length > 0) {
        return label;
      }
      if (typeof value === 'string' && value.length > 0) {
        return value;
      }
    }
    return `Option ${index + 1}`;
  });
}

/**
 * Builds a manual `next()` payload from local callback value state.
 *
 * @param callbacks - Indexed callback entries.
 * @param values - UI value map.
 * @returns Payload + issue list.
 */
function buildManualNextInput(
  callbacks: IndexedCallback[],
  values: Record<string, JourneyFormValue | undefined>,
): { input: JourneyNextInput; issues: string[] } {
  const mutations: JourneyCallbackInput[] = [];
  const issues: string[] = [];

  callbacks.forEach(entry => {
    const { key, type, typeIndex, callback } = entry;

    if (outputOnlyCallbackTypes.has(type)) {
      return;
    }

    if (integrationRequiredCallbackTypes.has(type)) {
      issues.push(`${type} requires extra module integration.`);
      return;
    }

    const rawValue = values[key];

    if (
      type === callbackType.BooleanAttributeInputCallback ||
      type === callbackType.TermsAndConditionsCallback ||
      type === nativeExtensionCallbackType.ConsentMappingCallback
    ) {
      const accepted = typeof rawValue === 'boolean' ? rawValue : false;
      const required =
        callback.required === true ||
        callback.isRequired === true ||
        callback.enforceRequired === true;
      if (required && !accepted) {
        issues.push(`${type} is required.`);
      }
      mutations.push({
        type,
        index: typeIndex,
        value: accepted,
      });
      return;
    }

    if (type === callbackType.NumberAttributeInputCallback) {
      const numericValue =
        typeof rawValue === 'number'
          ? rawValue
          : typeof rawValue === 'string'
            ? Number(rawValue)
            : Number.NaN;
      if (!Number.isFinite(numericValue)) {
        issues.push(`${type} requires a numeric value.`);
        return;
      }
      mutations.push({
        type,
        index: typeIndex,
        value: numericValue,
      });
      return;
    }

    if (
      type === callbackType.ChoiceCallback ||
      type === callbackType.ConfirmationCallback
    ) {
      const selectedIndex =
        typeof rawValue === 'number'
          ? rawValue
          : typeof rawValue === 'string'
            ? Number(rawValue)
            : Number.NaN;
      if (!Number.isFinite(selectedIndex)) {
        issues.push(`${type} requires selecting one option.`);
        return;
      }
      mutations.push({
        type,
        index: typeIndex,
        value: Math.max(0, Math.floor(selectedIndex)),
      });
      return;
    }

    if (type === callbackType.KbaCreateCallback) {
      const kbaValue =
        rawValue && typeof rawValue === 'object'
          ? (rawValue as KbaInput)
          : {
              selectedQuestion: '',
              selectedAnswer: '',
              allowUserDefinedQuestions: false,
            };

      if (
        !kbaValue.selectedQuestion.trim() ||
        !kbaValue.selectedAnswer.trim()
      ) {
        issues.push(`${type} requires both question and answer.`);
        return;
      }

      mutations.push({
        type,
        index: typeIndex,
        value: {
          selectedQuestion: kbaValue.selectedQuestion,
          selectedAnswer: kbaValue.selectedAnswer,
          allowUserDefinedQuestions: Boolean(
            kbaValue.allowUserDefinedQuestions,
          ),
        },
      });
      return;
    }

    const textValue = typeof rawValue === 'string' ? rawValue : '';
    mutations.push({
      type,
      index: typeIndex,
      value: textValue,
    });
  });

  return {
    input: mutations.length > 0 ? { callbacks: mutations } : {},
    issues,
  };
}

/**
 * Derives a display label from callback payload.
 *
 * @param callback - Raw callback payload.
 * @returns Prompt-like display text.
 */
function callbackLabel(callback: JourneyCallback): string {
  if (typeof callback.prompt === 'string' && callback.prompt.length > 0) {
    return callback.prompt;
  }
  if (typeof callback.message === 'string' && callback.message.length > 0) {
    return callback.message;
  }
  return callback.type;
}

/**
 * Renders a Journey screen implemented with `useJourney` only.
 *
 * @returns Journey full screen element.
 */
export default function JourneyFullScreen(): React.ReactElement {
  const [node, { start, next, resume, user, logoutUser, loading, error }] =
    useJourney();
  const [journeyName, setJourneyName] = useState<string>('Login');
  const [resumeUrl, setResumeUrl] = useState<string>('');
  const [sessionPayload, setSessionPayload] = useState<string | null>(null);
  const [values, setValues] = useState<
    Record<string, JourneyFormValue | undefined>
  >({});
  const [issues, setIssues] = useState<string[]>([]);

  const indexedCallbacks = useMemo<IndexedCallback[]>(
    () => (node?.type === 'ContinueNode' ? indexCallbacks(node.callbacks) : []),
    [node],
  );

  const setField = useCallback((key: string, value: JourneyFormValue): void => {
    setValues(previous => ({
      ...previous,
      [key]: value,
    }));
  }, []);

  const refreshSession = useCallback(async (): Promise<void> => {
    const session = await user();
    if (session) {
      setSessionPayload(JSON.stringify(session, null, 2));
    } else {
      setSessionPayload(null);
    }
  }, [user]);

  useEffect(() => {
    const timeoutId = setTimeout(() => {
      refreshSession().catch(() => {
        // Ignore initial session check failures in sample screen.
      });
    }, 0);

    return () => {
      clearTimeout(timeoutId);
    };
  }, [refreshSession]);

  useEffect(() => {
    if (node?.type === 'ContinueNode') {
      const timeoutId = setTimeout(() => {
        setIssues([]);
        setValues({});
      }, 0);

      return () => {
        clearTimeout(timeoutId);
      };
    }
    if (node?.type === 'SuccessNode') {
      const timeoutId = setTimeout(() => {
        refreshSession().catch(() => {
          // Ignore session refresh failures in sample screen.
        });
      }, 0);

      return () => {
        clearTimeout(timeoutId);
      };
    }
    return undefined;
  }, [node, refreshSession]);

  const onStart = useCallback(async (): Promise<void> => {
    const targetJourney = journeyName.trim();
    if (!targetJourney) {
      Alert.alert('Journey name is required');
      return;
    }
    try {
      setIssues([]);
      await start(targetJourney);
    } catch (cause) {
      Alert.alert('start() failed', formatError(cause));
    }
  }, [journeyName, start]);

  const onResume = useCallback(async (): Promise<void> => {
    const targetResumeUrl = resumeUrl.trim();
    if (!targetResumeUrl) {
      Alert.alert('Resume URL is required');
      return;
    }
    try {
      setIssues([]);
      await resume(targetResumeUrl);
      setResumeUrl('');
    } catch (cause) {
      Alert.alert('resume() failed', formatError(cause));
    }
  }, [resume, resumeUrl]);

  const onSubmit = useCallback(async (): Promise<void> => {
    const plan = buildManualNextInput(indexedCallbacks, values);
    setIssues(plan.issues);
    if (plan.issues.length > 0) {
      return;
    }

    try {
      await next(plan.input);
    } catch (cause) {
      Alert.alert('next() failed', formatError(cause));
    }
  }, [indexedCallbacks, next, values]);

  const onLogout = useCallback(async (): Promise<void> => {
    try {
      await logoutUser();
      setSessionPayload(null);
      setValues({});
      setIssues([]);
    } catch (cause) {
      Alert.alert('logoutUser() failed', formatError(cause));
    }
  }, [logoutUser]);

  const renderCallback = useCallback(
    (entry: IndexedCallback): React.ReactElement => {
      const { key, type, callback } = entry;
      const currentValue = values[key];
      const label = callbackLabel(callback);

      if (outputOnlyCallbackTypes.has(type)) {
        return (
          <View key={key} style={styles.callbackCard}>
            <Text style={styles.callbackType}>{type}</Text>
            <Text style={styles.callbackLabel}>{label}</Text>
          </View>
        );
      }

      if (integrationRequiredCallbackTypes.has(type)) {
        return (
          <View key={key} style={styles.callbackCard}>
            <Text style={styles.callbackType}>{type}</Text>
            <Text style={styles.integrationText}>
              Requires additional integration module. Submit from this screen is
              blocked.
            </Text>
          </View>
        );
      }

      if (
        type === callbackType.BooleanAttributeInputCallback ||
        type === callbackType.TermsAndConditionsCallback ||
        type === nativeExtensionCallbackType.ConsentMappingCallback
      ) {
        return (
          <View key={key} style={styles.callbackCard}>
            <Text style={styles.callbackType}>{type}</Text>
            <Text style={styles.callbackLabel}>{label}</Text>
            <View style={styles.switchRow}>
              <Text style={styles.switchLabel}>
                {currentValue === true ? 'Accepted' : 'Not accepted'}
              </Text>
              <Switch
                value={currentValue === true}
                onValueChange={value => setField(key, value)}
              />
            </View>
          </View>
        );
      }

      if (
        type === callbackType.ChoiceCallback ||
        type === callbackType.ConfirmationCallback
      ) {
        const options = readOptions(callback);
        return (
          <View key={key} style={styles.callbackCard}>
            <Text style={styles.callbackType}>{type}</Text>
            <Text style={styles.callbackLabel}>{label}</Text>
            {options.map((optionLabel, optionIndex) => {
              const selected = currentValue === optionIndex;
              return (
                <TouchableOpacity
                  key={`${key}:option:${optionIndex}`}
                  style={[
                    styles.optionButton,
                    selected ? styles.optionButtonSelected : null,
                  ]}
                  onPress={() => setField(key, optionIndex)}
                >
                  <Text
                    style={[
                      styles.optionButtonText,
                      selected ? styles.optionButtonTextSelected : null,
                    ]}
                  >
                    {optionLabel}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>
        );
      }

      if (type === callbackType.KbaCreateCallback) {
        const value =
          currentValue && typeof currentValue === 'object'
            ? (currentValue as KbaInput)
            : {
                selectedQuestion: '',
                selectedAnswer: '',
                allowUserDefinedQuestions: false,
              };

        return (
          <View key={key} style={styles.callbackCard}>
            <Text style={styles.callbackType}>{type}</Text>
            <Text style={styles.callbackLabel}>{label}</Text>
            <PingTextInput
              label="Security question"
              placeholder="Security question"
              value={value.selectedQuestion}
              onChangeText={text =>
                setField(key, {
                  ...value,
                  selectedQuestion: text,
                })
              }
            />
            <PingTextInput
              label="Security answer"
              placeholder="Security answer"
              value={value.selectedAnswer}
              onChangeText={text =>
                setField(key, {
                  ...value,
                  selectedAnswer: text,
                })
              }
            />
            <View style={styles.switchRow}>
              <Text style={styles.switchLabel}>Allow custom questions</Text>
              <Switch
                value={Boolean(value.allowUserDefinedQuestions)}
                onValueChange={enabled =>
                  setField(key, {
                    ...value,
                    allowUserDefinedQuestions: enabled,
                  })
                }
              />
            </View>
          </View>
        );
      }

      const secureTextEntry =
        type === callbackType.PasswordCallback ||
        type === callbackType.ValidatedCreatePasswordCallback;
      const keyboardType =
        type === callbackType.NumberAttributeInputCallback
          ? 'numeric'
          : 'default';
      const textValue =
        typeof currentValue === 'string'
          ? currentValue
          : typeof callback.value === 'string'
            ? callback.value
            : '';

      return (
        <View key={key} style={styles.callbackCard}>
          <Text style={styles.callbackType}>{type}</Text>
          <Text style={styles.callbackLabel}>{label}</Text>
          <PingTextInput
            label={label}
            value={textValue}
            secureTextEntry={secureTextEntry}
            allowPasswordToggle={secureTextEntry}
            keyboardType={keyboardType}
            onChangeText={text => setField(key, text)}
            autoCapitalize="none"
            placeholder={label}
          />
        </View>
      );
    },
    [setField, values],
  );

  return (
    <ScrollView
      contentContainerStyle={commonStyles.journeyContainer}
      nestedScrollEnabled
    >
      <View style={commonStyles.journeyCard}>
        <Text style={commonStyles.journeyTitle}>Journey (useJourney only)</Text>

        {sessionPayload ? (
          <View style={styles.section}>
            <Text style={commonStyles.journeySectionTitle}>Active session</Text>
            <PayloadViewer payload={sessionPayload} />
            <TouchableOpacity
              style={commonStyles.journeyButtonPrimary}
              onPress={onLogout}
              disabled={loading}
            >
              <Text style={commonStyles.journeyButtonText}>Logout</Text>
            </TouchableOpacity>
          </View>
        ) : (
          <View style={styles.section}>
            <Text style={commonStyles.journeySectionTitle}>Start Journey</Text>
            <PingTextInput
              label="Journey name"
              value={journeyName}
              onChangeText={setJourneyName}
              placeholder="Journey name"
              autoCapitalize="none"
            />
            <TouchableOpacity
              style={commonStyles.journeyButtonPrimary}
              onPress={onStart}
              disabled={loading}
            >
              <Text style={commonStyles.journeyButtonText}>Start</Text>
            </TouchableOpacity>
          </View>
        )}

        {node?.type === 'ContinueNode' ? (
          <View style={styles.section}>
            <Text style={commonStyles.journeySectionTitle}>Callbacks</Text>
            {indexedCallbacks.map(renderCallback)}
            {issues.map((issue, index) => (
              <Text key={`issue:${index}`} style={styles.issueText}>
                {issue}
              </Text>
            ))}
            <TouchableOpacity
              style={commonStyles.journeyButtonPrimary}
              onPress={onSubmit}
              disabled={loading}
            >
              <Text style={commonStyles.journeyButtonText}>Continue</Text>
            </TouchableOpacity>
          </View>
        ) : null}

        <View style={styles.section}>
          <Text style={commonStyles.journeySectionTitle}>Resume</Text>
          <PingTextInput
            label="Resume URL"
            value={resumeUrl}
            onChangeText={setResumeUrl}
            placeholder="Resume URL"
            autoCapitalize="none"
          />
          <TouchableOpacity
            style={commonStyles.journeyButtonSecondary}
            onPress={onResume}
            disabled={loading}
          >
            <Text style={commonStyles.journeyButtonText}>Resume</Text>
          </TouchableOpacity>
        </View>

        {error ? (
          <View style={styles.section}>
            <Text style={styles.errorText}>{formatError(error)}</Text>
          </View>
        ) : null}
      </View>
    </ScrollView>
  );
}
