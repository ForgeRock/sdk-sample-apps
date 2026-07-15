/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React, { useState } from 'react';
import { View, Text, TouchableOpacity, ScrollView } from 'react-native';
import { commonStyles } from '../src/styles/common';
import {
  getTokenStorages,
  configureOidcStorageInfo,
  configureSessionStorageInfo,
  configureBindingUserKeyStorageInfo,
} from '../src/tokenStorages';
import PayloadViewer from './components/atoms/PayloadViewer';

export default function MultiStorageScreen() {
  const [oidcStorage, setOidcStorage] = useState(
    () => getTokenStorages().oidcStorage,
  );
  const [sessionStorage, setSessionStorage] = useState(
    () => getTokenStorages().sessionStorage,
  );
  const [bindingUserKeyStorage, setBindingUserKeyStorage] = useState(
    () => getTokenStorages().bindingUserKeyStorage,
  );

  return (
    <ScrollView
      contentContainerStyle={commonStyles.container}
      nestedScrollEnabled
    >
      {/* OIDC STORAGE CARD */}
      <View style={commonStyles.card}>
        <Text style={commonStyles.journeySectionTitle}>OIDC Storage</Text>

        {!oidcStorage ? (
          <TouchableOpacity
            style={commonStyles.buttonPrimary}
            onPress={() => {
              setOidcStorage(configureOidcStorageInfo());
            }}
          >
            <Text style={commonStyles.buttonText}>Configure OIDC Storage</Text>
          </TouchableOpacity>
        ) : (
          <View>
            <PayloadViewer
              payload={`Config: ${JSON.stringify(oidcStorage.config, null, 2)}`}
            />
          </View>
        )}
      </View>

      {/* SESSION STORAGE CARD */}
      <View style={commonStyles.card}>
        <Text style={commonStyles.journeySectionTitle}>Session Storage</Text>

        {!sessionStorage ? (
          <TouchableOpacity
            style={commonStyles.buttonPrimary}
            onPress={() => {
              setSessionStorage(configureSessionStorageInfo());
            }}
          >
            <Text style={commonStyles.buttonText}>
              Configure Session Storage
            </Text>
          </TouchableOpacity>
        ) : (
          <View>
            <PayloadViewer
              payload={`Config: ${JSON.stringify(
                sessionStorage.config,
                null,
                2,
              )}`}
            />
          </View>
        )}
      </View>

      {/* BINDING USER KEY STORAGE CARD */}
      <View style={commonStyles.card}>
        <Text style={commonStyles.journeySectionTitle}>
          Binding User Key Storage
        </Text>

        {!bindingUserKeyStorage ? (
          <TouchableOpacity
            style={commonStyles.buttonPrimary}
            onPress={() => {
              setBindingUserKeyStorage(configureBindingUserKeyStorageInfo());
            }}
          >
            <Text style={commonStyles.buttonText}>
              Configure Binding User Key Storage
            </Text>
          </TouchableOpacity>
        ) : (
          <View>
            <PayloadViewer
              payload={`Config: ${JSON.stringify(
                bindingUserKeyStorage.config,
                null,
                2,
              )}`}
            />
          </View>
        )}
      </View>
    </ScrollView>
  );
}
