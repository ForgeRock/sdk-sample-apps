/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useState } from 'react';
import {
  ActivityIndicator,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import MaterialIcon from 'react-native-vector-icons/MaterialIcons';
import type { PushCredential, PushNotification } from '@ping-identity/rn-push';
import { commonStyles } from '../../src/styles/common';
import { colors } from '../../src/styles/colors';
import { usePush } from '@ping-identity/rn-push';
import NotificationCardView from './NotificationCardView';

function isExpired(n: PushNotification): boolean {
  return Date.now() > n.createdAt + n.ttl * 1000;
}

/**
 * Shows incoming push authentication requests and a history of past responses.
 *
 * Two tabs:
 * - **Pending** — unanswered notifications; pull-to-refresh to check for new ones.
 * - **History** — all notifications (approved, denied, expired).
 *
 * Tapping a pending notification opens `NotificationCardView` inline in the list.
 * The provider's modal handles notifications that arrive while this screen is not active.
 */
export default function PushNotificationsScreen() {
  const [data, { loading, error, refresh }] = usePush();
  const [tab, setTab] = useState<'pending' | 'history'>('pending');
  const [refreshing, setRefreshing] = useState(false);

  const onRefresh = async () => {
    setRefreshing(true);
    await refresh();
    setRefreshing(false);
  };

  if (loading) {
    return (
      <View style={commonStyles.container}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  }

  if (error) {
    return (
      <View style={commonStyles.container}>
        <Text style={commonStyles.textError}>{error.message}</Text>
      </View>
    );
  }

  if (!data) return null;
  const { client, credentials, pendingNotifications, allNotifications } = data;

  const credentialFor = (n: PushNotification): PushCredential | undefined =>
    credentials.find((c: PushCredential) => c.id === n.credentialId);

  return (
    <View style={commonStyles.screen}>
      {/* Segmented control */}
      <View style={commonStyles.segmentWrapper}>
        <View style={commonStyles.segment}>
          <TouchableOpacity
            style={[
              commonStyles.segmentTab,
              tab === 'pending' && commonStyles.segmentTabActive,
            ]}
            onPress={() => setTab('pending')}
          >
            <Text
              style={[
                commonStyles.segmentText,
                tab === 'pending' && commonStyles.segmentTextActive,
              ]}
            >
              Pending
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[
              commonStyles.segmentTab,
              tab === 'history' && commonStyles.segmentTabActive,
            ]}
            onPress={() => setTab('history')}
          >
            <Text
              style={[
                commonStyles.segmentText,
                tab === 'history' && commonStyles.segmentTextActive,
              ]}
            >
              History
            </Text>
          </TouchableOpacity>
        </View>
      </View>

      {tab === 'pending' ? (
        <ScrollView
          contentContainerStyle={styles.tabContent}
          refreshControl={
            <RefreshControl
              refreshing={refreshing}
              onRefresh={() => void onRefresh()}
            />
          }
        >
          {pendingNotifications.length === 0 ? (
            <View style={commonStyles.emptyState}>
              <MaterialIcon
                name="notifications-off"
                size={48}
                color={colors.gray}
                style={{ opacity: 0.4 }}
              />
              <Text style={commonStyles.emptyTitle}>
                No Pending Notifications
              </Text>
              <Text style={commonStyles.emptySubtitle}>
                You're all caught up! New push authentication requests will
                appear here.
              </Text>
            </View>
          ) : (
            pendingNotifications.map((n: PushNotification) => (
              <NotificationCardView
                key={n.id}
                notification={n}
                credential={credentialFor(n)}
                pushClient={client}
                onDone={refresh}
              />
            ))
          )}
        </ScrollView>
      ) : (
        <ScrollView
          contentContainerStyle={styles.tabContent}
          refreshControl={
            <RefreshControl
              refreshing={refreshing}
              onRefresh={() => void onRefresh()}
            />
          }
        >
          {allNotifications.length === 0 ? (
            <View style={commonStyles.emptyState}>
              <MaterialIcon
                name="history"
                size={48}
                color={colors.gray}
                style={{ opacity: 0.4 }}
              />
              <Text style={commonStyles.emptyTitle}>No History</Text>
              <Text style={commonStyles.emptySubtitle}>
                Your notification history will appear here after you respond to
                push requests.
              </Text>
            </View>
          ) : (
            allNotifications.map((n: PushNotification) => (
              <HistoryCard
                key={n.id}
                notification={n}
                credential={credentialFor(n)}
              />
            ))
          )}
        </ScrollView>
      )}
    </View>
  );
}

function HistoryCard({
  notification: n,
  credential,
}: {
  notification: PushNotification;
  credential: PushCredential | undefined;
}) {
  const expired = isExpired(n);

  const statusIconName =
    expired && n.pending
      ? 'schedule'
      : n.pending
        ? 'pending'
        : n.approved
          ? 'check-circle'
          : 'cancel';
  const statusText =
    expired && n.pending
      ? 'Expired'
      : n.pending
        ? 'Pending'
        : n.approved
          ? 'Approved'
          : 'Denied';
  const statusColor =
    expired && n.pending
      ? '#FF9500'
      : n.pending
        ? colors.blue
        : n.approved
          ? colors.success
          : colors.error;

  const typeIconName =
    n.pushType === 'biometric'
      ? 'fingerprint'
      : n.pushType === 'challenge'
        ? 'pin'
        : 'touch-app';
  const ts = n.respondedAt ?? n.createdAt;
  const relativeTime = formatRelative(ts);

  return (
    <View style={[commonStyles.card, { gap: 6 }]}>
      <View
        style={{
          flexDirection: 'row',
          alignItems: 'center',
          gap: 6,
          marginBottom: 2,
        }}
      >
        <MaterialIcon name={statusIconName} size={18} color={statusColor} />
        <Text style={{ fontSize: 15, fontWeight: '600', color: statusColor }}>
          {statusText}
        </Text>
        <View style={{ flex: 1 }} />
        <Text style={commonStyles.metaLabel}>{relativeTime}</Text>
      </View>
      {credential && (
        <Text style={commonStyles.sectionTitle}>
          {credential.displayIssuer} · {credential.displayAccountName}
        </Text>
      )}
      {n.messageText ? (
        <Text style={commonStyles.metaValue} numberOfLines={2}>
          {n.messageText}
        </Text>
      ) : null}
      <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
        <MaterialIcon name={typeIconName} size={14} color={colors.gray} />
        <Text style={commonStyles.metaLabel}>{n.pushType.toUpperCase()}</Text>
      </View>
    </View>
  );
}

function formatRelative(ts: number): string {
  const diff = Math.floor((Date.now() - ts) / 1000);
  if (diff < 60) return `${diff}s ago`;
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
  return `${Math.floor(diff / 86400)}d ago`;
}

const styles = StyleSheet.create({
  tabContent: {
    padding: 16,
    gap: 12,
    paddingBottom: 32,
  },
});
