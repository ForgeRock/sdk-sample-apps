/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { Image, Text, View } from 'react-native';
import type { QRCodeCollector } from '@ping-identity/rn-davinci';
import { davinciFieldStyles } from '../../../../src/styles/davinciStyles';
import type { DaVinciCollectorRendererProps } from './types';

/**
 * Renders a {@link QRCodeCollector} as a scannable image.
 *
 * @remarks
 * `content` is a full data URI supplied by the bridge — no client-side QR
 * generation is required. Falls back to `fallbackText` when the image fails
 * to load.
 *
 * @param props Renderer props.
 * @returns QR code field element.
 */
export default function DaVinciQrCodeField(
  props: DaVinciCollectorRendererProps,
): React.ReactElement {
  const { collector } = props;
  const qrCollector = collector as QRCodeCollector;
  const [failed, setFailed] = React.useState(false);

  return (
    <View style={davinciFieldStyles.card}>
      {failed || !qrCollector.content ? (
        <Text style={davinciFieldStyles.labelContent}>
          {qrCollector.fallbackText}
        </Text>
      ) : (
        <Image
          source={{ uri: qrCollector.content }}
          style={davinciFieldStyles.qrCodeImage}
          resizeMode="contain"
          onError={() => setFailed(true)}
          accessibilityLabel={qrCollector.fallbackText}
        />
      )}
    </View>
  );
}
