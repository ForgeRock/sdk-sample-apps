/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

/**
 * Converts unknown values into display-safe strings.
 *
 * @param value - Arbitrary input value.
 * @param fallback - Fallback value.
 * @returns String value for UI rendering.
 */
export function readString(value: unknown, fallback = ''): string {
  if (typeof value === 'string') {
    return value;
  }
  if (typeof value === 'number' || typeof value === 'boolean') {
    return String(value);
  }
  return fallback;
}

/**
 * Converts unknown values into display-safe numbers.
 *
 * @param value - Arbitrary input value.
 * @param fallback - Fallback value.
 * @returns Number value for UI rendering.
 */
export function readNumber(value: unknown, fallback = 0): number {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === 'string') {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : fallback;
  }
  return fallback;
}

/**
 * Converts unknown values into display-safe booleans.
 *
 * @param value - Arbitrary input value.
 * @param fallback - Fallback value.
 * @returns Boolean value for UI rendering.
 */
export function readBoolean(value: unknown, fallback = false): boolean {
  if (typeof value === 'boolean') {
    return value;
  }
  if (typeof value === 'number') {
    return value !== 0;
  }
  if (typeof value === 'string') {
    const normalized = value.toLowerCase();
    return normalized === 'true' || normalized === '1' || normalized === 'yes';
  }
  return fallback;
}

/**
 * Converts unknown values into display-safe text input content.
 *
 * @param value - Arbitrary input value.
 * @returns Display-safe string.
 */
export function toDisplayString(value: unknown): string {
  return readString(value, '');
}

/**
 * Resolves the display prompt for sample UI rendering.
 *
 * @param prompt - Native callback prompt value.
 * @param message - Native callback message value.
 * @returns Display-ready prompt text.
 */
export function resolvePromptText(prompt: unknown, message: unknown): string {
  const promptText = readString(prompt, '').trim();
  if (promptText.length > 0) {
    return promptText;
  }

  const messageText = readString(message, '').trim();
  if (messageText.length > 0) {
    return messageText;
  }

  return '';
}

/**
 * Resolves option label for sample rendering.
 *
 * @param label - Option label from normalized callback field.
 * @param value - Raw option value.
 * @param index - Option index.
 * @returns Display-ready option label.
 */
export function resolveOptionLabel(
  label: unknown,
  value: unknown,
  index: number,
): string {
  const labelText = readString(label, '').trim();
  if (labelText.length > 0) {
    return labelText;
  }

  const valueText = readString(value, '').trim();
  if (valueText.length > 0) {
    return valueText;
  }

  return `Option ${index + 1}`;
}

/**
 * Converts rich/unknown callback content into displayable text for sample UI.
 *
 * @param value - Raw callback payload value.
 * @returns Display-safe multiline text.
 */
export function resolveContentText(value: unknown): string {
  if (value === null || value === undefined) {
    return '';
  }

  if (typeof value === 'string') {
    return value.trim();
  }

  if (typeof value === 'number' || typeof value === 'boolean') {
    return String(value);
  }

  try {
    return JSON.stringify(value, null, 2);
  } catch {
    return '';
  }
}
