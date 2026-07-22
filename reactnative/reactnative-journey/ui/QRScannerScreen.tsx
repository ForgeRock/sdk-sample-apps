/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useCallback, useEffect, useRef, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Pressable,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import {
  useCameraDevice,
  useCameraPermission,
} from 'react-native-vision-camera';
import { CodeScanner } from 'react-native-vision-camera-barcode-scanner';
import type { Barcode } from 'react-native-vision-camera-barcode-scanner';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { createOathClient } from '@ping-identity/rn-oath';
import type { OathClient } from '@ping-identity/rn-oath';
import type { RootStackParamList } from '../App';
import { colors } from '../src/styles/colors';

type Props = NativeStackScreenProps<RootStackParamList, 'QRScanner'>;

/**
 * Converts an unknown error value to a display string.
 *
 * @param err - Unknown error value.
 * @returns A human-readable error message.
 */
function formatError(err: unknown): string {
  if (err && typeof err === 'object' && 'message' in err) {
    return String((err as { message?: string }).message ?? 'Unknown error');
  }
  return String(err);
}

/**
 * Returns the raw URI if it uses a recognised OATH scheme, or `null` otherwise.
 *
 * @param raw - Raw string value decoded from the QR code.
 * @returns The URI to register, or `null` if the input is not a recognised OATH scheme.
 */
function extractOtpUri(raw: string): string | null {
  if (raw.startsWith('otpauth://') || raw.startsWith('mfauth://')) {
    return raw;
  }
  return null;
}

/**
 * Full-screen QR code scanner for OATH credential registration.
 *
 * Matches the UX of the iOS PingExample app: the camera fills the screen
 * with a semi-transparent overlay, a white-bordered scan area in the centre,
 * and an instruction label above it. Once a valid `otpauth://` or `mfauth://`
 * QR code is scanned the credential is registered and the screen navigates
 * back with a success alert.
 *
 * Camera permission is requested on mount. Scanning is debounced so only
 * the first recognised frame triggers registration.
 *
 * @param props - Navigation stack props for the `QRScanner` route.
 * @returns QR scanner screen element.
 *
 * @remarks
 * On Android, `react-native-vision-camera` requires the `CAMERA` permission
 * declared in `AndroidManifest.xml`. On iOS, `NSCameraUsageDescription` must
 * be present in `Info.plist`.
 */
export default function QRScannerScreen({
  navigation,
}: Props): React.ReactElement {
  const { hasPermission, requestPermission } = useCameraPermission();
  const device = useCameraDevice('back');

  const [isProcessing, setIsProcessing] = useState(false);
  const hasScanned = useRef(false);
  const oathClientRef = useRef<OathClient | null>(null);

  // Initialise the OATH client once on mount and close it on unmount.
  useEffect(() => {
    let isMounted = true;
    createOathClient()
      .then(c => {
        if (isMounted) {
          oathClientRef.current = c;
        } else {
          // Component unmounted before the client was ready — close immediately
          // to release the native handle instead of leaking it.
          void c.close();
        }
      })
      .catch(err => {
        console.error('QRScanner: failed to create OATH client', err);
      });
    return () => {
      isMounted = false;
      void oathClientRef.current?.close();
      oathClientRef.current = null;
    };
  }, []);

  // Request camera permission on mount if not yet granted.
  useEffect(() => {
    if (!hasPermission) {
      void requestPermission();
    }
  }, [hasPermission, requestPermission]);

  const handleBarcodeScanned = useCallback(
    (barcodes: Barcode[]) => {
      if (hasScanned.current || isProcessing) return;
      const raw = barcodes[0]?.rawValue;
      if (!raw) return;

      const uri = extractOtpUri(raw);
      if (!uri) {
        // Recognised a QR code but not a supported OATH scheme — tell the user.
        hasScanned.current = true;
        Alert.alert(
          'Unsupported QR Code',
          'Please scan a valid OATH (otpauth:// or mfauth://) QR code.',
          [
            {
              text: 'OK',
              onPress: () => {
                hasScanned.current = false;
              },
            },
          ],
        );
        return;
      }

      hasScanned.current = true;
      setIsProcessing(true);

      const client = oathClientRef.current;
      if (!client) {
        setIsProcessing(false);
        hasScanned.current = false;
        Alert.alert('Error', 'OATH client is not ready. Please try again.');
        return;
      }

      client
        .addCredentialFromUri(uri)
        .then(credential => {
          setIsProcessing(false);
          Alert.alert(
            'Success',
            `Registered OATH account: ${credential.issuer}`,
            [
              {
                text: 'OK',
                onPress: () => navigation.goBack(),
              },
            ],
          );
        })
        .catch(err => {
          Alert.alert('Registration Failed', formatError(err), [
            {
              text: 'OK',
              onPress: () => {
                hasScanned.current = false;
                setIsProcessing(false);
              },
            },
          ]);
        });
    },
    [isProcessing, navigation],
  );

  const handleScanError = useCallback((error: Error) => {
    console.error('QRScanner: scan error', error);
  }, []);

  if (!hasPermission) {
    return (
      <View style={styles.centeredContainer}>
        <Text style={styles.permissionText}>
          Camera access is required to scan QR codes.
        </Text>
        <Pressable style={styles.permissionButton} onPress={requestPermission}>
          <Text style={styles.permissionButtonText}>Grant Permission</Text>
        </Pressable>
      </View>
    );
  }

  if (device == null) {
    return (
      <View style={styles.centeredContainer}>
        <Text style={styles.permissionText}>
          No camera device is available on this device.
        </Text>
        <Pressable
          style={styles.permissionButton}
          onPress={() => navigation.goBack()}
        >
          <Text style={styles.permissionButtonText}>Go Back</Text>
        </Pressable>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      {/* CodeScanner manages its own Camera internally */}
      <CodeScanner
        style={StyleSheet.absoluteFill}
        isActive={!isProcessing}
        barcodeFormats={['qr-code']}
        onBarcodeScanned={handleBarcodeScanned}
        onError={handleScanError}
      />

      {/* Semi-transparent overlay with a transparent scan window */}
      <View style={StyleSheet.absoluteFill} pointerEvents="none">
        <View style={styles.overlayTop} />
        <View style={styles.overlayMiddle}>
          <View style={styles.overlaySide} />
          {/* Scan window with white border */}
          <View style={styles.scanWindow} />
          <View style={styles.overlaySide} />
        </View>
        <View style={styles.overlayBottom} />
      </View>

      {/* Instruction label above the scan window */}
      <View style={styles.labelContainer} pointerEvents="none">
        <Text style={styles.labelText}>Scan QR Code</Text>
      </View>

      {/* Processing indicator */}
      {isProcessing ? (
        <View style={styles.processingOverlay}>
          <ActivityIndicator size="large" color={colors.white} />
          <Text style={styles.processingText}>Registering…</Text>
        </View>
      ) : null}
    </View>
  );
}

const SCAN_WINDOW_SIZE = 250;
const OVERLAY_COLOUR = 'rgba(0,0,0,0.55)';

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000',
  },
  centeredContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
    backgroundColor: colors.background,
  },
  permissionText: {
    fontSize: 16,
    color: colors.textDark,
    textAlign: 'center',
    marginBottom: 20,
  },
  permissionButton: {
    backgroundColor: colors.primary,
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 8,
  },
  permissionButtonText: {
    color: colors.white,
    fontSize: 15,
    fontWeight: '600',
  },
  // Overlay pieces build a dimmed frame around the scan window.
  overlayTop: {
    flex: 1,
    backgroundColor: OVERLAY_COLOUR,
  },
  overlayMiddle: {
    flexDirection: 'row',
    height: SCAN_WINDOW_SIZE,
  },
  overlaySide: {
    flex: 1,
    backgroundColor: OVERLAY_COLOUR,
  },
  scanWindow: {
    width: SCAN_WINDOW_SIZE,
    height: SCAN_WINDOW_SIZE,
    borderWidth: 2,
    borderColor: colors.white,
    borderRadius: 12,
  },
  overlayBottom: {
    flex: 1,
    backgroundColor: OVERLAY_COLOUR,
  },
  // Instruction label sits above the scan window.
  labelContainer: {
    position: 'absolute',
    left: 0,
    right: 0,
    top: '30%',
    marginTop: -SCAN_WINDOW_SIZE / 2 - 42,
    alignItems: 'center',
  },
  labelText: {
    color: colors.white,
    fontSize: 18,
    fontWeight: '600',
  },
  processingOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0,0,0,0.6)',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 12,
  },
  processingText: {
    color: colors.white,
    fontSize: 16,
  },
});
