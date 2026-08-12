/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { View } from 'react-native';
import { commonStyles } from '../../../../src/styles/common';

/**
 * Renders a separator between device rows.
 *
 * @returns Separator element.
 */
export default function DeviceListSeparator(): React.ReactElement {
  return <View style={commonStyles.deviceSeparator} />;
}
