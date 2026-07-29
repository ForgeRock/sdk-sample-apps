/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

const sensitiveKeyPattern =
  /(password|secret|token|otp|assertion|signature|pin|selectedAnswer)/i;

/**
 * Debug entry shape rendered on the sample Journey screen.
 */
export type JourneyDebugEntry = {
  id: string;
  timestamp: string;
  title: string;
  payload?: unknown;
};

/**
 * Creates a debug entry with timestamp and unique id.
 *
 * @param title - Human-readable debug title.
 * @param payload - Optional structured payload.
 * @returns Materialized debug entry.
 */
export function createJourneyDebugEntry(
  title: string,
  payload?: unknown,
): JourneyDebugEntry {
  return {
    id: `${Date.now()}-${Math.random().toString(16).slice(2, 8)}`,
    timestamp: new Date().toISOString(),
    title,
    payload,
  };
}

/**
 * Redacts sensitive fields from debug payloads.
 *
 * @param value - Arbitrary payload value.
 * @returns Sanitized payload safe for on-screen debug output.
 */
export function sanitizeDebugPayload(value: unknown): unknown {
  if (Array.isArray(value)) {
    return value.map(item => sanitizeDebugPayload(item));
  }

  if (!value || typeof value !== 'object') {
    return value;
  }

  const record = value as Record<string, unknown>;
  const callbackType = typeof record.type === 'string' ? record.type : '';

  return Object.entries(record).reduce<Record<string, unknown>>(
    (result, [key, nestedValue]) => {
      if (
        sensitiveKeyPattern.test(key) ||
        (key === 'value' && /password/i.test(callbackType))
      ) {
        result[key] = '[REDACTED]';
        return result;
      }

      result[key] = sanitizeDebugPayload(nestedValue);
      return result;
    },
    {},
  );
}

/**
 * Converts debug payloads to printable JSON.
 *
 * @param payload - Arbitrary payload value.
 * @returns Pretty JSON or fallback string.
 */
export function debugPayloadToString(payload: unknown): string {
  try {
    return JSON.stringify(payload, null, 2);
  } catch {
    return String(payload);
  }
}
