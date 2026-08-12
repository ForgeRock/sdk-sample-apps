/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import Svg, { Circle, G } from 'react-native-svg';
import { colors } from '../../../../src/styles/colors';

/**
 * Props for {@link OathCircularProgress}.
 */
type OathCircularProgressProps = {
  /**
   * Elapsed fraction of the TOTP period (0 = just started, 1 = expired).
   * The ring drains clockwise as this value increases.
   */
  progress: number;
  /**
   * Seconds remaining in the current TOTP window, shown in the centre.
   */
  timeRemaining: number;
  /**
   * Diameter of the ring in logical pixels.
   * @default 40
   */
  size?: number;
  /**
   * Width of the arc stroke in logical pixels.
   * @default 3
   */
  strokeWidth?: number;
  /**
   * Whether the credential is locked.
   * Locked state renders a muted red ring with no countdown.
   * @default false
   */
  locked?: boolean;
};

/**
 * Circular countdown ring used on OATH credential cards and the detail modal.
 *
 * The ring drains clockwise as `progress` increases from 0 to 1, mirroring
 * the `CircularProgressView` in the iOS PingExample app. A second stroke
 * underneath acts as the track (gray guide ring).
 *
 * @param props - Ring dimensions, progress value, and locked state.
 * @returns Circular ring element with the remaining seconds in the centre.
 *
 * @example
 * ```tsx
 * <OathCircularProgress
 *   progress={codeInfo.progress}
 *   timeRemaining={codeInfo.timeRemaining}
 *   size={40}
 *   strokeWidth={3}
 * />
 * ```
 */
export default function OathCircularProgress({
  progress,
  timeRemaining,
  size = 40,
  strokeWidth = 3,
  locked = false,
}: OathCircularProgressProps): React.ReactElement {
  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;
  // Clamp remaining fraction [0, 1] and compute the visible arc length.
  const remaining = Math.max(0, Math.min(1, 1 - progress));
  const strokeDashoffset = circumference * (1 - remaining);

  const progressColor = locked
    ? colors.error
    : remaining <= 0.17 // ~5 s for a 30 s period
      ? colors.error
      : colors.primary;

  return (
    <View style={[styles.container, { width: size, height: size }]}>
      <Svg width={size} height={size}>
        <G rotation="-90" origin={`${size / 2}, ${size / 2}`}>
          {/* Track ring */}
          <Circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            stroke="rgba(0,0,0,0.12)"
            strokeWidth={strokeWidth}
            fill="none"
          />
          {/* Progress arc */}
          <Circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            stroke={progressColor}
            strokeWidth={strokeWidth}
            strokeDasharray={circumference}
            strokeDashoffset={strokeDashoffset}
            strokeLinecap="round"
            fill="none"
          />
        </G>
      </Svg>

      {/* Centre label */}
      <View style={styles.centreContent}>
        {locked ? null : (
          <Text
            style={[
              styles.centreText,
              {
                fontSize: size <= 50 ? size * 0.3 : size * 0.27,
                color: progressColor,
              },
            ]}
          >
            {Math.max(0, timeRemaining)}
          </Text>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  centreContent: {
    ...StyleSheet.absoluteFillObject,
    alignItems: 'center',
    justifyContent: 'center',
  },
  centreText: {
    fontWeight: '700',
    textAlign: 'center',
  },
});
