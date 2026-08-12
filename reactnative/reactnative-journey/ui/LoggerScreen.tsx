/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useEffect, useMemo } from 'react';
import { ScrollView, Text, TouchableOpacity, View } from 'react-native';
import { logger } from '@ping-identity/rn-logger';
import { commonStyles } from '../src/styles/common';

/**
 * Logger SDK demonstration screen.
 */
export default function LoggerScreen() {
  const log = useMemo(() => logger({ level: 'info' }), []);

  useEffect(() => {
    log.info('Logger demo: screen opened');
    log.warn('Logger demo: warning');
    log.debug('Logger demo: debug (hidden at info)');
  }, [log]);

  return (
    <ScrollView contentContainerStyle={commonStyles.container}>
      <View style={commonStyles.card}>
        <Text style={commonStyles.journeySectionTitle}>Logger Demo</Text>
        <TouchableOpacity
          style={commonStyles.buttonSecondary}
          onPress={() => {
            log.changeLevel('debug');
            log.debug('Logger demo: native level set to debug');
          }}
        >
          <Text style={commonStyles.buttonTextSecondary}>Enable Debug</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={commonStyles.buttonSecondary}
          onPress={() => {
            log.changeLevel('warn');
            log.warn('Logger demo: native level set to warn');
          }}
        >
          <Text style={commonStyles.buttonTextSecondary}>Enable Warn</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={commonStyles.buttonDanger}
          onPress={() => {
            log.error('Logger demo: error');
          }}
        >
          <Text style={commonStyles.buttonText}>Emit Error</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
}
