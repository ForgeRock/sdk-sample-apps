/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useCallback, useEffect, useRef, useState } from 'react';
import { Modal, Pressable, StyleSheet, Text, View } from 'react-native';
import { PushProvider, usePush } from '@ping-identity/rn-push';
import type { PushConfig, PushNotification } from '@ping-identity/rn-push';
import { logger } from '@ping-identity/rn-logger';
import { CacheStrategy, configurePushStorage } from '@ping-identity/rn-storage';
import NotificationCardView from './NotificationCardView';
import { colors } from '../../src/styles/colors';

type Props = { children: React.ReactNode };

const pushLogger = logger({ level: 'debug' });

const pushStorage = configurePushStorage(
  {
    android: {
      keyAlias: 'com.pingidentity.rnsampleapp.push',
      fileName: 'ping_push_prefs',
      strongBoxPreferred: true,
      cacheStrategy: CacheStrategy.CACHE_ON_FAILURE,
    },
    ios: {
      account: 'com.pingidentity.rnsampleapp.push',
      encryptor: true,
      cacheable: true,
    },
  },
  { logger: pushLogger },
);

const pushConfig: PushConfig = {
  logger: pushLogger,
  storage: pushStorage,
  timeoutMs: 20000,
  enableCredentialCache: true,
  notificationCleanupConfig: {
    cleanupMode: 'COUNT_BASED',
    maxStoredNotifications: 5,
  },
  ios: {
    encryptionEnabled: true,
  },
};

/**
 * Mounts a {@link PushProvider} at the app root and adds an automatic
 * notification modal on top.
 *
 * When a push notification arrives while the app is foregrounded, a
 * bottom-sheet modal is presented over whatever screen is active.
 * All push data is available to descendant screens via `usePush()`.
 */
export function PushNotificationProvider({ children }: Props) {
  return (
    <PushProvider config={pushConfig}>
      <PushNotificationModal>{children}</PushNotificationModal>
    </PushProvider>
  );
}

function PushNotificationModal({ children }: Props) {
  const [data, { refresh }] = usePush();
  const [activeNotification, setActiveNotification] =
    useState<PushNotification | null>(null);
  const dismissedIds = useRef<Set<string>>(new Set());

  const show = useCallback((n: PushNotification) => {
    if (!dismissedIds.current.has(n.id)) setActiveNotification(n);
  }, []);

  // Surface any notification that arrived before the listener was registered.
  useEffect(() => {
    if (!data || activeNotification) return;
    const first = data.pendingNotifications[0];
    if (first) show(first);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [data?.pendingNotifications]);

  useEffect(() => {
    if (!data) return;
    const { client } = data;

    const unsub = client.onNotification(notification => {
      if (notification) {
        show(notification);
        void refresh();
      } else {
        client
          .getPendingNotifications()
          .then(pending => {
            if (pending.length > 0) show(pending[0]!);
          })
          .catch(() => {});
      }
    });

    return unsub;
  }, [data, refresh, show]);

  const dismiss = useCallback(() => {
    if (activeNotification) dismissedIds.current.add(activeNotification.id);
    setActiveNotification(null);
    void refresh();
  }, [activeNotification, refresh]);

  const credential =
    activeNotification && data
      ? data.credentials.find(c => c.id === activeNotification.credentialId)
      : undefined;

  return (
    <>
      {children}
      {activeNotification && data ? (
        <Modal
          transparent
          animationType="slide"
          visible
          onRequestClose={dismiss}
        >
          <Pressable style={styles.overlay} onPress={dismiss}>
            <Pressable style={styles.sheet} onPress={e => e.stopPropagation()}>
              <View style={styles.sheetHandle} />
              <View style={styles.sheetHeader}>
                <Text style={styles.sheetTitle}>Push Authentication</Text>
                <Pressable onPress={dismiss} hitSlop={12}>
                  <Text style={styles.closeBtn}>✕</Text>
                </Pressable>
              </View>
              <NotificationCardView
                notification={activeNotification}
                credential={credential}
                pushClient={data.client}
                onDone={dismiss}
              />
            </Pressable>
          </Pressable>
        </Modal>
      ) : null}
    </>
  );
}

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.4)',
    justifyContent: 'flex-end',
  },
  sheet: {
    backgroundColor: colors.background,
    borderTopLeftRadius: 16,
    borderTopRightRadius: 16,
    paddingHorizontal: 16,
    paddingBottom: 32,
    paddingTop: 8,
  },
  sheetHandle: {
    width: 36,
    height: 4,
    borderRadius: 2,
    backgroundColor: colors.border,
    alignSelf: 'center',
    marginBottom: 12,
  },
  sheetHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 12,
  },
  sheetTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.textDark,
  },
  closeBtn: {
    fontSize: 16,
    color: colors.gray,
    fontWeight: '600',
  },
});
