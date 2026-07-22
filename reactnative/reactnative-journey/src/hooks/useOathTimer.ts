/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import {
  useCallback,
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
} from 'react';
import type {
  OathClient,
  OathCodeInfo,
  OathCredential,
} from '@ping-identity/rn-oath';

/**
 * React hook that manages live TOTP countdown timers and HOTP code state for a
 * list of OATH credentials.
 *
 * @param client - An initialised {@link OathClient} instance, or `null` when no
 *   client is available (e.g. before the OATH store is opened). Passing `null`
 *   cancels all active schedulers and leaves `codes` at its current value.
 * @param credentials - The list of {@link OathCredential} objects to track.
 *   Changing this array triggers an immediate code fetch for each credential.
 *
 * @returns An object with:
 * - `codes` — a `Map` keyed by credential ID whose values are the latest
 *   {@link OathCodeInfo} payloads (code, timeRemaining, progress, totalPeriod).
 * - `refreshCode` — a stable callback that immediately re-generates and updates
 *   the code for the given credential ID. Useful for HOTP credentials where the
 *   counter must advance on user request.
 *
 * @remarks
 * **Dual-timer strategy**
 *
 * Two independent timers cooperate to keep the UI responsive:
 *
 * 1. **Per-credential `setTimeout` scheduler** — fires at the end of each TOTP
 *    window and calls `generateCodeWithValidity` to fetch the fresh code + the
 *    exact `timeRemaining` for the next window. This keeps the displayed OTP
 *    value accurate and eliminates clock-drift accumulation that a plain
 *    `setInterval` would cause over many windows.
 *
 * 2. **1 Hz `setInterval` countdown** — decrements `timeRemaining` by 1 every
 *    second for all TOTP entries so the UI can render a smooth progress
 *    indicator without polling the native bridge. HOTP entries
 *    (`totalPeriod === 0`) are skipped.
 *
 * **Locked-credential suppression**
 *
 * Any `generateCodeWithValidity` call that throws (e.g. `OATH_CREDENTIAL_LOCKED`)
 * is silently caught. The scheduler for that credential is removed; the codes
 * map retains the last known value (or has no entry if the credential was
 * never successfully fetched). The UI must check `OathCredential.isLocked`
 * separately to render a locked state indicator.
 *
 * @example
 * ```tsx
 * function OathList({ client, credentials }: Props) {
 *   const { codes, refreshCode } = useOathTimer(client, credentials);
 *   return credentials.map(c => (
 *     <OathRow
 *       key={c.id}
 *       credential={c}
 *       codeInfo={codes.get(c.id)}
 *       onRefresh={() => refreshCode(c.id)}
 *     />
 *   ));
 * }
 * ```
 */
export function useOathTimer(
  client: OathClient | null,
  credentials: OathCredential[],
): {
  codes: Map<string, OathCodeInfo>;
  refreshCode: (credentialId: string) => void;
} {
  const [codes, setCodes] = useState<Map<string, OathCodeInfo>>(
    () => new Map(),
  );

  const schedulerRef = useRef<Map<string, ReturnType<typeof setTimeout>>>(
    new Map(),
  );

  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // clientRef lets the scheduler read the latest client without being a dep.
  const clientRef = useRef<OathClient | null>(client);
  useEffect(() => {
    clientRef.current = client;
  });

  // scheduleTotpRef breaks the recursive self-reference inside useCallback.
  const scheduleTotpRef = useRef<(id: string, timeRemaining: number) => void>(
    () => {},
  );

  const scheduleTotp = useCallback((id: string, timeRemaining: number) => {
    const existing = schedulerRef.current.get(id);
    if (existing !== undefined) {
      clearTimeout(existing);
    }

    const delay = Math.max(timeRemaining, 1) * 1000;
    const timerId = setTimeout(async () => {
      const currentClient = clientRef.current;
      if (currentClient === null) return;
      try {
        const result = await currentClient.generateCodeWithValidity(id);
        setCodes(prev => {
          const next = new Map(prev);
          next.set(id, result);
          return next;
        });
        scheduleTotpRef.current(id, result.timeRemaining);
      } catch {
        schedulerRef.current.delete(id);
      }
    }, delay);

    schedulerRef.current.set(id, timerId);
  }, []);

  useLayoutEffect(() => {
    scheduleTotpRef.current = scheduleTotp;
  });

  // Main effect: fetch codes immediately when client or credentials change.
  useEffect(() => {
    if (client === null) {
      schedulerRef.current.forEach(id => clearTimeout(id));
      schedulerRef.current.clear();
      return;
    }

    // Cancel all existing schedulers before re-fetching; the credential list
    // may have changed and stale schedulers would fire for removed credentials.
    schedulerRef.current.forEach(id => clearTimeout(id));
    schedulerRef.current.clear();

    for (const credential of credentials) {
      const { id, type } = credential;

      if (type === 'TOTP') {
        client
          .generateCodeWithValidity(id)
          .then(result => {
            setCodes(prev => {
              const next = new Map(prev);
              next.set(id, result);
              return next;
            });
            scheduleTotp(id, result.timeRemaining);
          })
          .catch(() => {
            // Locked or unavailable credential — skip silently.
          });
      } else {
        // HOTP: fetch once; no scheduler. Sentinel: timeRemaining = -1, progress = 0.0.
        client
          .generateCodeWithValidity(id)
          .then(result => {
            setCodes(prev => {
              const next = new Map(prev);
              next.set(id, result);
              return next;
            });
          })
          .catch(() => {
            // Locked or unavailable credential — skip silently.
          });
      }
    }

    const schedulers = schedulerRef.current;
    return () => {
      schedulers.forEach(id => clearTimeout(id));
      schedulers.clear();
    };
  }, [client, credentials, scheduleTotp]);

  // 1 Hz countdown: decrement timeRemaining for TOTP entries so the UI can
  // render a smooth progress bar without hitting the native bridge every second.
  useEffect(() => {
    intervalRef.current = setInterval(() => {
      setCodes(prev => {
        let changed = false;
        const next = new Map(prev);
        next.forEach((info, id) => {
          // HOTP sentinel: totalPeriod === 0 — skip.
          if (info.totalPeriod === 0) return;
          const newRemaining = Math.max(info.timeRemaining - 1, 0);
          if (newRemaining !== info.timeRemaining) {
            changed = true;
            const newProgress =
              info.totalPeriod > 0
                ? 1 - newRemaining / info.totalPeriod
                : info.progress;
            next.set(id, {
              ...info,
              timeRemaining: newRemaining,
              progress: newProgress,
            });
          }
        });
        return changed ? next : prev;
      });
    }, 1000);

    return () => {
      if (intervalRef.current !== null) {
        clearInterval(intervalRef.current);
        intervalRef.current = null;
      }
    };
  }, []);

  const refreshCode = useCallback(
    (credentialId: string) => {
      if (client === null) return;
      client
        .generateCodeWithValidity(credentialId)
        .then(result => {
          setCodes(prev => {
            const next = new Map(prev);
            next.set(credentialId, result);
            return next;
          });
          if (result.timeRemaining !== -1) {
            scheduleTotp(credentialId, result.timeRemaining);
          }
        })
        .catch(() => {
          // Locked or unavailable credential — skip silently.
        });
    },
    [client, scheduleTotp],
  );

  return { codes, refreshCode };
}
