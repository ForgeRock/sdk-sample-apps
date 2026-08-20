/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'messages.g.dart';

/// iOS-only browser presentation options for [OidcClient.configure].
///
/// Android ignores both fields — it only has Chrome Custom Tabs, with no `BrowserType`/
/// `BrowserMode` equivalent to select.
class OidcBrowserOptions {
  /// Creates a set of browser presentation options.
  const OidcBrowserOptions({this.browserType, this.browserMode});

  /// One of `authSession` / `ephemeralAuthSession` (both implemented on iOS at 2.1.0).
  /// `nativeBrowserApp` / `sfViewController` are declared but not implemented natively — the iOS
  /// bridge rejects them rather than passing through to a silent no-op.
  final String? browserType;

  /// One of `login` / `logout` / `custom`.
  final String? browserMode;

  /// Builds the wire [BrowserOptionsMessage] for this configuration.
  BrowserOptionsMessage toMessage() => BrowserOptionsMessage()
    ..browserType = browserType
    ..browserMode = browserMode;
}
