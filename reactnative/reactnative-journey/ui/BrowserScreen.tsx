/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useMemo, useState } from 'react';
import { View, Text, TouchableOpacity, ScrollView } from 'react-native';
import { open } from '@ping-identity/rn-browser';
import { formatError } from './utils/formatError';
import { logger } from '@ping-identity/rn-logger';
import { commonStyles } from '../src/styles/common';
import PingTextInput from './components/atoms/PingTextInput';
import PayloadViewer from './components/atoms/PayloadViewer';

/**
 * Browser SDK demonstration screen.
 */
export default function BrowserScreen() {
  const browserLogger = useMemo(() => logger({ level: 'debug' }), []);
  const [url, setUrl] = useState('https://www.pingidentity.com');
  const [callbackUrlScheme, setCallbackUrlScheme] =
    useState('org.forgerock.demo');
  const [redirectUri, setRedirectUri] = useState(
    'org.forgerock.demo://oauth2redirect',
  );
  const [result, setResult] = useState<string>('');
  const [error, setError] = useState<string>('');

  const suggestedUrls = [
    'https://www.pingidentity.com',
    'https://httpbin.org/redirect-to?url=org.forgerock.demo://oauth2redirect?code=123',
  ];

  const handleOpen = async (overrideUrl?: string) => {
    setError('');
    setResult('');

    try {
      const response = await open(
        overrideUrl ?? url,
        {
          callbackUrlScheme,
          redirectUri: redirectUri.trim() ? redirectUri : undefined,
          ios: {
            browserMode: 'login',
            browserType: 'ephemeralAuthSession',
          },
        },
        {
          logger: browserLogger,
        },
      );
      setResult(JSON.stringify(response, null, 2));
    } catch (e: unknown) {
      setError(formatError(e));
    }
  };

  return (
    <ScrollView
      contentContainerStyle={commonStyles.container}
      nestedScrollEnabled
    >
      <View style={commonStyles.card}>
        <Text style={commonStyles.journeySectionTitle}>Browser</Text>

        <PingTextInput
          label="URL"
          value={url}
          onChangeText={setUrl}
          placeholder="https://example.com"
          autoCapitalize="none"
          autoCorrect={false}
        />
        <View style={commonStyles.suggestionContainer}>
          {suggestedUrls.map(item => (
            <TouchableOpacity
              key={item}
              onPress={() => setUrl(item)}
              style={commonStyles.suggestionChip}
            >
              <Text style={commonStyles.suggestionText}>{item}</Text>
            </TouchableOpacity>
          ))}
        </View>

        <PingTextInput
          label="Callback URL Scheme"
          value={callbackUrlScheme}
          onChangeText={setCallbackUrlScheme}
          placeholder="myapp"
          autoCapitalize="none"
          autoCorrect={false}
        />

        <PingTextInput
          label="Redirect URI (optional)"
          value={redirectUri}
          onChangeText={setRedirectUri}
          placeholder="myapp://callback"
          autoCapitalize="none"
          autoCorrect={false}
        />

        <TouchableOpacity
          style={commonStyles.buttonPrimary}
          onPress={() => handleOpen()}
        >
          <Text style={commonStyles.buttonText}>Open Browser</Text>
        </TouchableOpacity>

        {error ? <Text style={commonStyles.textError}>{error}</Text> : null}
      </View>

      {result ? (
        <View style={commonStyles.codeBox}>
          <Text style={commonStyles.codeTitle}>Result</Text>
          <PayloadViewer payload={result} />
        </View>
      ) : null}
    </ScrollView>
  );
}
