/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useMemo, useState } from 'react';
import {
  ActivityIndicator,
  Text,
  TouchableOpacity,
  View,
  ScrollView,
} from 'react-native';
import {
  collectDeviceProfile,
  type DeviceProfile,
  type DeviceProfileCollector,
} from '@ping-identity/rn-device-profile';
import { formatError } from './utils/formatError';
import { logger } from '@ping-identity/rn-logger';
import { commonStyles } from '../src/styles/common';
import { colors } from '../src/styles/colors';
import { deviceProfileScreenStyles as styles } from '../src/styles/componentStyles';
import PayloadViewer from './components/atoms/PayloadViewer';
import LabeledSwitchRow from './components/atoms/LabeledSwitchRow';

const defaultCollectorSelections: Record<DeviceProfileCollector, boolean> = {
  platform: true,
  hardware: true,
  network: true,
  telephony: false,
  browser: false,
  bluetooth: false,
  location: false,
};

/**
 * Displays a simple device profile collector demo.
 */
export default function DeviceProfileScreen(): React.ReactElement {
  const deviceProfileLogger = useMemo(() => logger({ level: 'debug' }), []);
  const [collectorSelections, setCollectorSelections] = useState<
    Record<DeviceProfileCollector, boolean>
  >(defaultCollectorSelections);
  const [isCollecting, setIsCollecting] = useState(false);
  const [profile, setProfile] = useState<DeviceProfile | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const availableCollectors = useMemo<DeviceProfileCollector[]>(
    () => Object.keys(defaultCollectorSelections) as DeviceProfileCollector[],
    [],
  );

  const toggleCollector = (collector: DeviceProfileCollector): void => {
    setCollectorSelections(prev => ({
      ...prev,
      [collector]: !prev[collector],
    }));
  };

  const onCollect = async (): Promise<void> => {
    const collectors = availableCollectors.filter(
      collector => collectorSelections[collector],
    );

    if (collectors.length === 0) {
      setProfile(null);
      setErrorMessage('Select at least one collector.');
      return;
    }

    setIsCollecting(true);
    setErrorMessage(null);
    setProfile(null);

    try {
      const collectedProfile = await collectDeviceProfile(collectors, {
        logger: deviceProfileLogger,
      });
      setProfile(collectedProfile);
    } catch (err: unknown) {
      setErrorMessage(formatError(err));
    } finally {
      setIsCollecting(false);
    }
  };

  return (
    <ScrollView
      contentContainerStyle={commonStyles.container}
      nestedScrollEnabled
    >
      <View style={commonStyles.card}>
        <Text style={commonStyles.journeySectionTitle}>Device Profile</Text>
        <Text style={commonStyles.helperNote}>
          Choose collectors, then collect a device profile payload.
        </Text>

        <View style={styles.collectorList}>
          {availableCollectors.map(collector => (
            <LabeledSwitchRow
              key={collector}
              label={collector}
              value={collectorSelections[collector]}
              onValueChange={() => toggleCollector(collector)}
            />
          ))}
        </View>

        <TouchableOpacity
          style={commonStyles.buttonPrimary}
          onPress={onCollect}
          disabled={isCollecting}
        >
          {isCollecting ? (
            <ActivityIndicator color={colors.surface} />
          ) : (
            <Text style={commonStyles.buttonText}>Collect Device Profile</Text>
          )}
        </TouchableOpacity>

        {errorMessage && (
          <Text style={commonStyles.textError}>{errorMessage}</Text>
        )}
      </View>

      {profile && (
        <View style={commonStyles.codeBox}>
          <Text style={commonStyles.codeTitle}>Collected Profile</Text>
          <PayloadViewer payload={JSON.stringify(profile, null, 2)} />
        </View>
      )}
    </ScrollView>
  );
}
