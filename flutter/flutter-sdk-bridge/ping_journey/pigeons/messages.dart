// Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    dartOptions: DartOptions(),
    kotlinOut:
        'android/src/main/kotlin/com/pingidentity/flutter/journey/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.pingidentity.flutter.journey'),
    swiftOut: 'ios/ping_journey/Sources/ping_journey/Messages.g.swift',
    swiftOptions: SwiftOptions(),
    copyrightHeader: 'pigeons/copyright.txt',
    dartPackageName: 'ping_journey',
  ),
)
/// Node type tag mirroring the native `Node` sealed hierarchy
/// (`ContinueNode`/`SuccessNode`/`ErrorNode`/`FailureNode`).
enum NodeType { continueNode, successNode, errorNode, failureNode }

/// Flat, wire-serializable Journey configuration. OIDC fields are hoisted to
/// the top level rather than nested, since Pigeon classes can't express an
/// "OIDC configured only if any OIDC field is present" union cleanly.
class JourneyConfigMessage {
  JourneyConfigMessage({required this.serverUrl});

  String serverUrl;
  String? realm;
  String? cookie;

  /// Milliseconds.
  int? timeoutMillis;

  String? clientId;
  String? discoveryEndpoint;
  String? redirectUri;
  List<String?>? scopes;
  String? acrValues;
  String? signOutRedirectUri;
  String? state;
  String? nonce;
  String? uiLocales;

  /// Seconds.
  int? refreshThreshold;
  String? loginHint;
  String? display;
  String? prompt;
  Map<String?, String?>? additionalParameters;
}

class StartOptionsMessage {
  StartOptionsMessage({required this.forceAuth, required this.noSession});

  bool forceAuth;
  bool noSession;
}

/// Flat union of the v1 callback fields (~10 callback types). `value` is
/// `Object?`, StandardMessageCodec-backed (covers String/bool/num/Map/List).
class CallbackMessage {
  CallbackMessage({required this.type, required this.index});

  String type;
  int index;
  String? prompt;
  String? message;
  bool? required;
  Object? value;
  List<String?>? choices;
  int? defaultChoice;
  int? selectedIndex;

  /// Full terms-and-conditions text (TermsAndConditionsCallback).
  String? terms;
  String? version;
  String? createDate;
  bool? accepted;

  /// Placeholder/default text (TextInputCallback).
  String? defaultText;
  List<String?>? predefinedQuestions;
  String? selectedQuestion;
  String? selectedAnswer;
  bool? allowUserDefinedQuestions;

  /// Attribute name/label (Attribute*InputCallback), distinct from [value].
  String? name;

  /// Validate-without-advancing flag (ValidatedUsername/ValidatedPassword/
  /// Attribute*InputCallback). Read-only: reflects native state at mapping
  /// time; [CallbackValueMessage] has no field to send an updated value back
  /// to native (same limitation as the React Native bridge).
  bool? validateOnly;
  Map<String?, Object?>? policies;

  /// Each element is a `Map<String?, Object?>?`. Typed as `List<Object?>?` (rather than
  /// `List<Map<String?, Object?>?>?`) because Pigeon's generated decoder does an unchecked
  /// `.cast<Map<String?, Object?>?>()` on nested collection element types, which throws at
  /// runtime the first time a real (non-empty) map element arrives over the wire — see
  /// `NodeMapper._castFailedPolicies` for the safe elementwise cast this requires on read.
  List<Object?>? failedPolicies;

  /// Whether to mask input (ValidatedPasswordCallback).
  bool? echoOn;

  /// TextOutputCallback message classification: INFORMATION/WARNING/ERROR/SCRIPT/UNKNOWN.
  String? messageType;
  Map<String?, Object?>? raw;
}

/// Dart -> native callback value, addressed by `{type, index}` so native can
/// re-resolve it against the cached `ContinueNode`.
class CallbackValueMessage {
  CallbackValueMessage({required this.type, required this.index});

  String type;
  int index;
  Object? value;
}

class NodeMessage {
  NodeMessage({required this.type});

  NodeType type;
  String? message;
  String? cause;
  int? status;

  /// Page metadata (ContinueNode only) — native extension properties on
  /// `ContinueNode`, exposed as real fields rather than left opaque.
  String? header;
  String? pageDescription;
  String? stage;
  List<CallbackMessage?>? callbacks;
  Map<String?, Object?>? input;
}

class SessionMessage {
  SessionMessage({required this.accessToken, required this.expiresIn});

  String accessToken;
  String? refreshToken;
  int expiresIn;
  Map<String?, Object?>? userInfo;
}

@HostApi()
abstract class PingJourneyHostApi {
  @async
  String configureJourney(JourneyConfigMessage config);

  @async
  NodeMessage start(String journeyId, String name, StartOptionsMessage options);

  @async
  NodeMessage next(String journeyId, List<CallbackValueMessage?> values);

  @async
  SessionMessage? getSession(String journeyId);

  @async
  bool signOff(String journeyId);

  @async
  void dispose(String journeyId);
}
