/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ping_davinci/ping_davinci.dart';

import 'support/davinci_fixtures.dart';
import 'support/davinci_harness.dart';
import 'support/test_config.dart';

/// A `QR_CODE` arrives as its data URI on both platforms (2.2.0 gave iOS `content`), decodes to
/// a real image, and renders; a corrupted image falls back to the `fallbackText`. Hermetically
/// the URI must equal the captured field's byte for byte, which pins the two platforms to the
/// same string. Runs in both modes.
///
/// The render half pumps an `Image.memory` with an `errorBuilder` — what an app does with
/// `QRCodeCollector.imageBytes` — so a bad image is shown as text instead of crashing.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a QR code decodes and renders, and a corrupt one falls back', (
    tester,
  ) async {
    final skipReason = E2eConfig.liveFlowSkipReason(
      E2eConfig.acrMetadataImage,
      'E2E_ACR_METADATA_IMAGE',
    );
    if (skipReason != null) {
      markTestSkipped(skipReason);
      return;
    }
    final harness = await DaVinciHarness.create(
      liveAcr: E2eConfig.acrMetadataImage,
      hermeticAcr: 'metadata-image',
      hermeticFlow: (baseUrl) => [
        DaVinciFixtures.metadataImageMenu(baseUrl),
        DaVinciFixtures.qrCodeForm(baseUrl),
        DaVinciFixtures.metadataImageMenu(baseUrl),
      ],
    );
    addTearDown(harness.dispose);

    final menu = await tester.runAsync(harness.client.start);
    expect(menu, isA<ContinueNode>(), reason: harness.diagnose(menu!));
    collectorWithKey<FlowCollector>(
      menu as ContinueNode,
      DaVinciFixtures.qrCodeBranch,
    ).select();
    final form = await tester.runAsync(() => harness.client.next(menu));
    expect(form, isA<ContinueNode>(), reason: harness.diagnose(form!));
    final qrCode = (form as ContinueNode).collectors
        .whereType<QRCodeCollector>()
        .single;

    expect(qrCode.key, 'qr-code');
    expect(qrCode.content, startsWith('data:image/png;base64,'));
    if (harness.isHermetic) {
      expect(qrCode.content, DaVinciFixtures.qrCodeContent());
    }
    expect(qrCode.fallbackText, startsWith("If you can't scan the QR code"));

    final bytes = qrCode.imageBytes!;
    final size = await tester.runAsync(() => _decodedSize(bytes));
    expect(size!.width, greaterThan(0));
    expect(size.width, size.height, reason: 'a QR code is square');

    await tester.pumpWidget(
      _QrView(bytes: bytes, fallback: qrCode.fallbackText),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(_QrView.imageKey), findsOneWidget);
    expect(find.text(qrCode.fallbackText), findsNothing);

    // The same image with its data cut short no longer decodes.
    final corrupt = Uint8List.sublistView(bytes, 0, bytes.length ~/ 3);
    await tester.pumpWidget(
      _QrView(bytes: corrupt, fallback: qrCode.fallbackText),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    expect(find.text(qrCode.fallbackText), findsOneWidget);

    form.collectors.whereType<SubmitCollector>().single.select();
    final after = await tester.runAsync(() => harness.client.next(form));
    expect(after, isA<ContinueNode>(), reason: harness.diagnose(after!));
    harness.mock?.expectNoUnmatchedRequests();
  });
}

Future<Size> _decodedSize(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final size = Size(
    frame.image.width.toDouble(),
    frame.image.height.toDouble(),
  );
  frame.image.dispose();
  codec.dispose();
  return size;
}

/// What an app renders for a `QRCodeCollector`: the image, or the fallback text when it fails.
class _QrView extends StatelessWidget {
  const _QrView({required this.bytes, required this.fallback});

  static const imageKey = Key('qr-image');

  final Uint8List bytes;
  final String fallback;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: Image.memory(
          bytes,
          frameBuilder: (context, child, frame, _) =>
              frame == null ? child : KeyedSubtree(key: imageKey, child: child),
          errorBuilder: (context, error, stackTrace) => Text(fallback),
        ),
      ),
    ),
  );
}
