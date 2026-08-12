/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { useCallback, useEffect, useRef, useState } from 'react';
import { Alert, Linking } from 'react-native';
import { JourneyError } from '@ping-identity/rn-journey';

/**
 * Configuration contract for `useJourneyResumeController`.
 */
export type UseJourneyResumeControllerOptions = {
  /**
   * True when active node includes `SuspendedTextOutputCallback`.
   */
  hasSuspendedCallback: boolean;
  /**
   * Journey resume action.
   */
  resume: (uri: string) => Promise<unknown>;
  /**
   * Debug append helper.
   */
  appendDebug: (title: string, payload?: unknown) => void;
};

/**
 * Resume URL state and deep-link resume handling for Journey sample flows.
 *
 * @param options - Resume controller options.
 * @returns Resume URL state and manual resume action.
 */
export function useJourneyResumeController(
  options: UseJourneyResumeControllerOptions,
): {
  /**
   * Current resume URL field value.
   */
  resumeUrl: string;
  /**
   * Resume URL updater.
   *
   * @param value - Next resume URL value.
   * @returns Void.
   */
  setResumeUrl: (value: string) => void;
  /**
   * Performs manual resume with current `resumeUrl`.
   *
   * @returns Promise resolved after resume attempt completes.
   */
  onResume: () => Promise<void>;
} {
  const { hasSuspendedCallback, resume, appendDebug } = options;
  const [resumeUrl, setResumeUrl] = useState<string>('');
  // Deduplicates repeated deep-link events for the same resume URI.
  const lastAutoResumedUrlRef = useRef<string | null>(null);

  const onResume = useCallback(async (): Promise<void> => {
    const trimmedResumeUrl = resumeUrl.trim();
    if (!trimmedResumeUrl) {
      Alert.alert('Paste the resume URL first.');
      return;
    }

    try {
      await resume(trimmedResumeUrl);
      appendDebug('Journey resumed', { url: trimmedResumeUrl });
      setResumeUrl('');
    } catch (cause) {
      appendDebug('Journey resume failed', {
        cause:
          cause instanceof JourneyError
            ? `[${cause.code}] ${cause.message}`
            : String(cause),
      });
      Alert.alert(
        'Resume failed',
        cause instanceof JourneyError
          ? `[${cause.code}] ${cause.message}`
          : String(cause),
      );
    }
  }, [appendDebug, resume, resumeUrl]);

  useEffect(() => {
    if (!hasSuspendedCallback) {
      return;
    }

    const subscription = Linking.addEventListener('url', ({ url }) => {
      const trimmedResumeUrl = url.trim();
      if (
        !trimmedResumeUrl ||
        lastAutoResumedUrlRef.current === trimmedResumeUrl
      ) {
        return;
      }

      // Mark before async call to avoid duplicate auto-resume attempts.
      lastAutoResumedUrlRef.current = trimmedResumeUrl;

      const runAutoResume = async (): Promise<void> => {
        try {
          setResumeUrl(trimmedResumeUrl);
          await resume(trimmedResumeUrl);
          appendDebug('Journey auto-resume handled', { url: trimmedResumeUrl });
          setResumeUrl('');
        } catch (cause) {
          appendDebug('Journey auto-resume failed', {
            cause:
              cause instanceof JourneyError
                ? `[${cause.code}] ${cause.message}`
                : String(cause),
          });
          Alert.alert(
            'Resume failed',
            cause instanceof JourneyError
              ? `[${cause.code}] ${cause.message}`
              : String(cause),
          );
        }
      };

      void runAutoResume();
    });

    return () => {
      subscription.remove();
    };
  }, [appendDebug, hasSuspendedCallback, resume]);

  return {
    resumeUrl,
    setResumeUrl,
    onResume,
  };
}
