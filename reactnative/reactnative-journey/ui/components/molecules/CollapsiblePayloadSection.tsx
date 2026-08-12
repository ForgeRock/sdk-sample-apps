/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { ActivityIndicator, Text, TouchableOpacity, View } from 'react-native';
import { commonStyles } from '../../../src/styles/common';
import { collapsiblePayloadSectionStyles as styles } from '../../../src/styles/componentStyles';
import PayloadViewer from '../atoms/PayloadViewer';

/**
 * Props for the reusable collapsible payload section.
 */
export type CollapsiblePayloadSectionProps = {
  /**
   * Section title.
   */
  title: string;
  /**
   * Payload text to render when expanded.
   */
  payload: string;
  /**
   * Whether the section is currently expanded.
   */
  expanded: boolean;
  /**
   * Called when the section header is pressed.
   */
  onToggle: () => void;
  /**
   * Whether to show loading state in the collapsed header.
   */
  loading?: boolean;
  /**
   * Whether to render payload text using error color.
   */
  isError?: boolean;
};

/**
 * Renders a code-style collapsible section with optional loading indicator.
 *
 * @param props Collapsible section props.
 * @returns Collapsible payload section element.
 */
export default function CollapsiblePayloadSection(
  props: CollapsiblePayloadSectionProps,
): React.ReactElement {
  const {
    title,
    payload,
    expanded,
    onToggle,
    loading = false,
    isError = false,
  } = props;

  return (
    <View style={commonStyles.codeBox}>
      <View style={styles.headerRow}>
        <TouchableOpacity onPress={onToggle}>
          <Text style={commonStyles.codeTitle}>
            {expanded ? 'v' : '>'} {title}
          </Text>
        </TouchableOpacity>
        {!expanded && loading ? (
          <ActivityIndicator style={styles.loadingIndicator} size="small" />
        ) : null}
      </View>
      {expanded ? (
        <PayloadViewer
          payload={payload}
          textStyle={isError ? commonStyles.textError : undefined}
        />
      ) : null}
    </View>
  );
}
