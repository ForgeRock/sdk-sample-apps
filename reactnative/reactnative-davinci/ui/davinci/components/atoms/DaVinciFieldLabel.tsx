/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { Text } from 'react-native';
import { davinciFieldStyles } from '../../../../src/styles/davinciStyles';

/**
 * Props for {@link DaVinciFieldLabel}.
 */
export type DaVinciFieldLabelProps = {
  /**
   * Label text.
   */
  label: string;
  /**
   * Whether the underlying collector is required.
   */
  required?: boolean;
};

/**
 * Renders a field label with an optional required marker.
 *
 * @param props Component props.
 * @returns Field label element.
 */
export default function DaVinciFieldLabel(
  props: DaVinciFieldLabelProps,
): React.ReactElement {
  const { label, required } = props;
  return (
    <Text style={davinciFieldStyles.fieldLabel}>
      {label}
      {required ? <Text style={davinciFieldStyles.required}> *</Text> : null}
    </Text>
  );
}
