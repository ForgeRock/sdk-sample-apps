/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { useCallback, useEffect, useRef, useState } from 'react';
import { useJourney } from '@ping-identity/rn-journey';
import {
  createDeviceClient,
  type DeviceByKind,
  type DeviceClient,
  type DeviceKind,
  type DeviceOf,
} from '@ping-identity/rn-device-client';
import { journeyConfig } from '../clients';
import { logger } from '@ping-identity/rn-logger';

/**
 * Lifecycle status of the hook's fetch/mutation state machine.
 *
 * - `'idle'`    before the first fetch fires
 * - `'loading'` while a get / refresh / mutation is in flight
 * - `'ready'`   when the last operation succeeded and `devices` is fresh
 * - `'error'`   when the last operation failed; see `error` for the message
 */
type Status = 'idle' | 'loading' | 'ready' | 'error';

/**
 * Reactive state returned as the first tuple element from {@link useDevices}.
 */
interface UseDevicesState {
  status: Status;
  devices: DeviceOf<keyof DeviceByKind>[];
  /** Human-readable error surfaced from the native bridge, or `null` when healthy. */
  error: string | null;
}

/**
 * Stable action handles returned as the second tuple element from {@link useDevices}.
 *
 * All handles are memoized via `useCallback` so consumers can pass them safely
 * into `useEffect` dependency arrays or `React.memo` children without
 * triggering unnecessary re-renders.
 */
interface UseDevicesActions {
  /** Re-fetches the device list for the currently selected kind. */
  refresh: () => void;
  /**
   * Renames a device on the server and re-fetches the list on success.
   * Re-fetches on failure too so local state matches the server.
   */
  rename: (
    device: DeviceOf<keyof DeviceByKind>,
    newName: string,
  ) => Promise<void>;
  /**
   * Deletes a device from the server and re-fetches the list.
   * Re-fetches on failure too so local state matches the server.
   */
  remove: (device: DeviceOf<keyof DeviceByKind>) => Promise<void>;
}

/**
 * Sample-app-local React hook that wires an authenticated Journey session to
 * `@ping-identity/rn-device-client`.
 *
 * @remarks
 * This hook is **not** part of the SDK — it lives in the sample app to keep
 * the foundation `@ping-identity/rn-device-client` package React-agnostic.
 * It illustrates the recommended integration pattern for consuming
 * `createDeviceClient` from within a `<JourneyProvider>` tree:
 *
 * 1. Read the active Journey session via `useJourney()`.
 * 2. Call `journeyActions.user()` to validate the session with AM and
 *    rehydrate in-memory state (see the note inside {@link ensureClient}
 *    for why this ordering matters).
 * 3. Call `journeyActions.ssoToken()` to read the validated SSO token.
 * 4. Pass `{ serverUrl, ssoToken: token.value, realm: token.realm,
 *    cookieName: journeyConfig.cookie }` into `createDeviceClient(...)`.
 * 5. Call repository methods (`client.oath.get()`, `client.push.delete(...)`,
 *    etc.) and reflect results in local state.
 *
 * The underlying `DeviceClient` is cached in a ref across renders and
 * reused for every operation — this keeps the native SDK's internal
 * `userId` cache warm (one `/sessions?_action=getSessionInfo` roundtrip
 * per client instance, not per call).
 *
 * `dispose()` is intentionally **not** called on unmount — the client is
 * app-scoped and the OS reclaims the native handle on process exit.
 * Matches the Journey SDK's lifecycle pattern.
 *
 * @param deviceType - Which device kind the hook should manage. Changing
 *   this value does NOT tear down the underlying `DeviceClient`; the
 *   hook just issues a new fetch for the newly-selected kind.
 * @returns `[state, actions]` tuple.
 *
 * @example
 * ```tsx
 * function OathList() {
 *   const [state, actions] = useDevices('oath');
 *   if (state.status === 'loading') return <Spinner />;
 *   return state.devices.map((d) => (
 *     <Row key={d.id} device={d} onDelete={() => actions.remove(d)} />
 *   ));
 * }
 * ```
 */
export function useDevices(
  deviceType: DeviceKind,
): [UseDevicesState, UseDevicesActions] {
  const [, journeyActions] = useJourney();
  const clientRef = useRef<DeviceClient | null>(null);
  const mountedRef = useRef(true);

  const [state, setState] = useState<UseDevicesState>({
    status: 'idle',
    devices: [],
    error: null,
  });

  // `mountedRef` guards setState calls against firing on an unmounted component.
  // React would just warn in dev, but we also want to avoid stale updates racing
  // with a later mount.
  useEffect(() => {
    mountedRef.current = true;
    return () => {
      mountedRef.current = false;
    };
  }, []);

  /**
   * Lazily creates and caches the underlying `DeviceClient`.
   *
   * Runs only once per hook lifetime — subsequent calls return the cached
   * client. The native SDK caches the `/sessions?_action=getSessionInfo`
   * response internally, so reusing the same client across operations
   * avoids redundant server roundtrips.
   *
   * Throws a plain `Error` when the Journey session is missing so the
   * DevicesScreen can distinguish "sign in required" from a generic error.
   */
  const ensureClient = useCallback(async (): Promise<DeviceClient> => {
    if (clientRef.current) return clientRef.current;

    // On cold start, `journey.ssoToken()` alone returns null — it reads from
    //   in-memory state only. `journey.user()` triggers a native session check
    //   (which validates against AM and rehydrates in-memory state), after
    //   which `ssoToken()` returns a token known to still be valid server-side.
    //   SSO tokens expire (idle / max timeout, admin invalidation), so this
    //   validate-then-read ordering avoids handing stale tokens to the bridge.
    await journeyActions.user();
    const token = await journeyActions.ssoToken();
    if (!token?.value) {
      throw new Error('No active Journey session. Please sign in first.');
    }

    const client = createDeviceClient({
      serverUrl: journeyConfig.serverUrl,
      ssoToken: token.value,
      realm: token.realm,
      cookieName: journeyConfig.cookie,
      logger: logger({ level: 'debug' }),
    });
    clientRef.current = client;
    return client;
  }, [journeyActions]);

  /**
   * Fetches the device list for the currently selected kind.
   *
   * Handles both typed `Error` throws (from our own `ensureClient`) and the
   * plain-object rejections that the native bridge emits
   * (`{ message, type, error, status? }`). Normalized to a display string
   * and stored on `state.error` for the UI to render.
   */
  const fetchDevices = useCallback(async () => {
    setState(s => ({ ...s, status: 'loading', error: null }));
    try {
      const client = await ensureClient();
      const items = await (
        client[deviceType as keyof typeof client] as {
          get: () => Promise<unknown[]>;
        }
      ).get();
      if (mountedRef.current) {
        setState({
          status: 'ready',
          devices: items as DeviceOf<keyof DeviceByKind>[],
          error: null,
        });
      }
    } catch (error: unknown) {
      if (mountedRef.current) {
        const message =
          error instanceof Error
            ? error.message
            : typeof error === 'object' && error !== null && 'message' in error
              ? String((error as { message: string }).message)
              : String(error);
        setState(s => ({
          ...s,
          status: 'error',
          error: message,
        }));
      }
    }
  }, [ensureClient, deviceType]);

  // Auto-fetch on mount and whenever the selected kind changes.
  // `fetchDevices` is memoized via useCallback so this effect fires only on
  // real selector / client changes, not every render. The setState it performs
  // is the whole point (bridge-to-React sync), hence the rule disable.
  useEffect(() => {
    fetchDevices();
  }, [fetchDevices]);

  /**
   * Renames a device on the server, then re-fetches to reflect the server's
   * acknowledged state.
   *
   * No optimistic UI update — the `status: 'loading'` set by `fetchDevices()`
   * is enough feedback for this sample. Failures re-fetch too so the list
   * stays in sync with the server.
   */
  const rename = useCallback(
    async (device: DeviceOf<keyof DeviceByKind>, newName: string) => {
      const client = await ensureClient();
      const updated = { ...device, deviceName: newName };
      try {
        await (
          client[deviceType as keyof typeof client] as {
            update: (d: typeof updated) => Promise<unknown>;
          }
        ).update(updated);
      } finally {
        await fetchDevices();
      }
    },
    [ensureClient, deviceType, fetchDevices],
  );

  /**
   * Deletes a device on the server, then re-fetches so local state matches.
   *
   * Same rationale as `rename`: no optimistic update, re-fetch on both
   * success and failure paths (the catch is in the consumer).
   */
  const remove = useCallback(
    async (device: DeviceOf<keyof DeviceByKind>) => {
      const client = await ensureClient();
      try {
        await (
          client[deviceType as keyof typeof client] as {
            delete: (d: typeof device) => Promise<unknown>;
          }
        ).delete(device);
      } finally {
        await fetchDevices();
      }
    },
    [ensureClient, deviceType, fetchDevices],
  );

  return [state, { refresh: fetchDevices, rename, remove }];
}
