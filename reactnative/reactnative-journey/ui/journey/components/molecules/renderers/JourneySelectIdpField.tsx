/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { Text, TouchableOpacity, View } from 'react-native';
import FontAwesomeIcon from 'react-native-vector-icons/FontAwesome';
import { commonStyles } from '../../../../../src/styles/common';
import { journeyFieldRendererStyles as fieldStyles } from '../../../../../src/styles/journeyStyles';
import { readString, resolvePromptText } from './valueReaders';
import type { JourneyFieldRendererProps } from './types';

type ParsedButtonStyle = {
  backgroundColor?: string;
  borderColor?: string;
  textColor?: string;
};

type SelectIdpProviderOption = {
  id: string;
  label: string;
  buttonStyle?: ParsedButtonStyle;
  iconColor?: string;
  iconBackground?: string;
};

/**
 * Returns a record value when the input is object-like.
 *
 * @param value - Candidate record value.
 * @returns Record value or null.
 */
function asRecord(value: unknown): Record<string, unknown> | null {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    return null;
  }
  return value as Record<string, unknown>;
}

function capitalizeFirst(value: string): string {
  return value.length > 0 ? value[0].toUpperCase() + value.slice(1) : value;
}

function parseCssButtonStyle(css: string): ParsedButtonStyle {
  const result: ParsedButtonStyle = {};
  for (const declaration of css.split(';')) {
    const colonIndex = declaration.indexOf(':');
    if (colonIndex === -1) continue;
    const property = declaration.slice(0, colonIndex).trim().toLowerCase();
    const value = declaration.slice(colonIndex + 1).trim();
    if (!value) continue;
    if (property === 'background-color') result.backgroundColor = value;
    else if (property === 'border-color') result.borderColor = value;
    else if (property === 'color') result.textColor = value;
  }
  return result;
}

/**
 * Resolves a FontAwesome icon name from the provider identifier by checking
 * for known brand substrings. Returns null when no match is found.
 *
 * @param id - Server-side provider identifier.
 * @returns FontAwesome icon name or null.
 */
function resolveProviderIcon(id: string): string | null {
  const lower = id.toLowerCase();
  if (lower.includes('facebook')) return 'facebook';
  if (lower.includes('google')) return 'google';
  if (lower.includes('apple')) return 'apple';
  return null;
}

/**
 * Converts a provider payload item into a selectable option.
 * The label is the server-side provider name (e.g. "facebook-ios") with its
 * first letter capitalized. The id is kept verbatim for submission.
 *
 * @param provider - Raw provider payload item.
 * @returns Normalized provider option or null.
 */
function normalizeProviderOption(
  provider: unknown,
): SelectIdpProviderOption | null {
  if (typeof provider === 'string') {
    const id = provider.trim();
    return id.length > 0 ? { id, label: capitalizeFirst(id) } : null;
  }

  const record = asRecord(provider);
  if (!record) {
    return null;
  }

  const id =
    readString(record.provider).trim() ||
    readString(record.id).trim() ||
    readString(record.value).trim() ||
    readString(record.name).trim();
  if (id.length === 0) {
    return null;
  }

  const uiConfig = asRecord(record.uiConfig);

  const cssStyle = readString(uiConfig?.buttonCustomStyle).trim();
  const buttonStyle =
    cssStyle.length > 0 ? parseCssButtonStyle(cssStyle) : undefined;

  const iconColor = readString(uiConfig?.iconFontColor).trim() || undefined;
  const iconBackground =
    readString(uiConfig?.iconBackground).trim() || undefined;

  return {
    id,
    label: capitalizeFirst(id),
    buttonStyle,
    iconColor,
    iconBackground,
  };
}

/**
 * Reads a named output value from a callback payload.
 *
 * @param output - Callback output array.
 * @param name - Output name to resolve.
 * @returns Output value when found.
 */
function readOutputValue(output: unknown, name: string): unknown {
  if (!Array.isArray(output)) {
    return undefined;
  }

  return output.map(asRecord).find(item => item?.name === name)?.value;
}

/**
 * Resolves SelectIdp provider options from native callback payload shapes.
 *
 * @param raw - Raw callback payload from the Journey field.
 * @returns Selectable provider options.
 */
function resolveProviderOptions(raw: unknown): SelectIdpProviderOption[] {
  const callback = asRecord(raw);
  const rawCallback = asRecord(callback?.raw);
  const providerValues =
    callback?.providers ??
    rawCallback?.providers ??
    readOutputValue(callback?.output, 'providers') ??
    readOutputValue(rawCallback?.output, 'providers');

  if (!Array.isArray(providerValues)) {
    return [];
  }

  return providerValues
    .map(normalizeProviderOption)
    .filter((option): option is SelectIdpProviderOption => option !== null);
}

/**
 * Renders provider choices for a native `SelectIdpCallback`.
 *
 * @param props - Field renderer props.
 * @returns Select IdP provider field.
 */
export default function JourneySelectIdpField(
  props: JourneyFieldRendererProps,
): React.ReactElement {
  const { field, currentValue, setFieldValue, onSelectIdpProvider } = props;
  const selectedProvider = readString(currentValue).trim();
  const promptText = resolvePromptText(field.prompt, field.message);
  const options = resolveProviderOptions(field.raw);

  return (
    <View style={fieldStyles.card}>
      {promptText.length > 0 ? (
        <Text style={fieldStyles.promptText}>{promptText}</Text>
      ) : null}
      {options.length === 0 ? (
        <Text style={fieldStyles.helperText}>
          No providers were provided by this callback.
        </Text>
      ) : null}
      {options.map(option => {
        const iconName = resolveProviderIcon(option.id);
        return (
          <TouchableOpacity
            key={`${field.id}:${option.id}`}
            style={[
              commonStyles.buttonSecondary,
              option.buttonStyle?.backgroundColor
                ? { backgroundColor: option.buttonStyle.backgroundColor }
                : null,
              option.buttonStyle?.borderColor
                ? { borderColor: option.buttonStyle.borderColor }
                : null,
              selectedProvider === option.id
                ? fieldStyles.selectedOption
                : null,
            ]}
            onPress={() => {
              setFieldValue(field.id, option.id);
              void onSelectIdpProvider?.(field.id, option.id);
            }}
          >
            <View style={fieldStyles.providerButtonContent}>
              {iconName ? (
                <View
                  style={[
                    fieldStyles.providerIconContainer,
                    option.iconBackground
                      ? { backgroundColor: option.iconBackground }
                      : null,
                  ]}
                >
                  <FontAwesomeIcon
                    name={iconName}
                    size={14}
                    color={
                      option.iconColor ??
                      option.buttonStyle?.textColor ??
                      '#333333'
                    }
                  />
                </View>
              ) : null}
              <Text
                style={[
                  commonStyles.buttonTextSecondary,
                  option.buttonStyle?.textColor
                    ? { color: option.buttonStyle.textColor }
                    : null,
                ]}
              >
                {option.label}
              </Text>
            </View>
          </TouchableOpacity>
        );
      })}
    </View>
  );
}
