/*
 * ping-sample-web-react-journey
 *
 * journey-trace.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { JOURNEY_TRACE } from '../constants';

const TRACE_BUFFER = '__PING_JOURNEY_TRACE__';
const TRACE_HELPERS = '__PING_JOURNEY_TRACE_HELPERS__';

function getWindow() {
  return typeof window === 'undefined' ? null : window;
}

function safeCall(fn) {
  try {
    return fn();
  } catch (error) {
    return {
      traceSnapshotError: snapshotError(error),
    };
  }
}

export function cloneForTrace(value) {
  const seen = new WeakSet();

  if (value === undefined || value === null) {
    return value;
  }

  if (value instanceof Error) {
    return snapshotError(value);
  }

  let serialized;

  try {
    serialized = JSON.stringify(value, (key, currentValue) => {
      void key;

      if (typeof currentValue === 'function') {
        return `[Function ${currentValue.name || 'anonymous'}]`;
      }

      if (typeof currentValue === 'bigint') {
        return currentValue.toString();
      }

      if (currentValue instanceof Error) {
        return snapshotError(currentValue);
      }

      if (currentValue && typeof currentValue === 'object') {
        if (seen.has(currentValue)) {
          return '[Circular]';
        }
        seen.add(currentValue);
      }

      return currentValue;
    });
  } catch (error) {
    return {
      traceSerializationError: snapshotError(error),
      value: String(value),
    };
  }

  return serialized === undefined ? undefined : JSON.parse(serialized);
}

export function snapshotError(error) {
  if (!error) {
    return error;
  }

  if (typeof error !== 'object') {
    return error;
  }

  return {
    name: error.name,
    message: error.message,
    stack: error.stack,
    raw: clonePlainObject(error),
  };
}

function clonePlainObject(value) {
  try {
    return cloneForTrace({ ...value });
  } catch {
    return String(value);
  }
}

export function snapshotCallback(callback) {
  if (!callback) {
    return callback;
  }

  return {
    type: safeCall(() => callback.getType && callback.getType()) || callback.type,
    payload: cloneForTrace(callback.payload),
  };
}

export function snapshotStep(step) {
  if (!step) {
    return step;
  }

  const callbacks = Array.isArray(step.callbacks)
    ? step.callbacks.map((callback) => snapshotCallback(callback))
    : [];

  return {
    type: step.type,
    stage: safeCall(() => step.getStage && step.getStage()),
    payload: cloneForTrace(step.payload),
    callbackTypes: callbacks.map((callback) => callback?.type),
    callbacks,
    error: cloneForTrace(step.error),
  };
}

export function traceJourney(event, details = {}) {
  if (!JOURNEY_TRACE) {
    return null;
  }

  const currentWindow = getWindow();
  if (!currentWindow) {
    return null;
  }

  if (!Array.isArray(currentWindow[TRACE_BUFFER])) {
    currentWindow[TRACE_BUFFER] = [];
  }

  if (!currentWindow[TRACE_HELPERS]) {
    currentWindow[TRACE_HELPERS] = {
      clear() {
        currentWindow[TRACE_BUFFER] = [];
      },
      copy() {
        return cloneForTrace(currentWindow[TRACE_BUFFER]);
      },
      download(filename = 'ping-journey-trace.json') {
        const blob = new Blob([JSON.stringify(currentWindow[TRACE_BUFFER], null, 2)], {
          type: 'application/json',
        });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');

        link.href = url;
        link.download = filename;
        link.click();

        URL.revokeObjectURL(url);
      },
    };
  }

  const entry = {
    id: currentWindow[TRACE_BUFFER].length + 1,
    timestamp: new Date().toISOString(),
    event,
    ...cloneForTrace(details),
  };

  currentWindow[TRACE_BUFFER].push(entry);
  console.log('[Ping Journey Trace]', event, entry);

  return entry;
}

export function traceStep(event, step, details = {}) {
  return traceJourney(event, {
    ...details,
    step: snapshotStep(step),
  });
}
