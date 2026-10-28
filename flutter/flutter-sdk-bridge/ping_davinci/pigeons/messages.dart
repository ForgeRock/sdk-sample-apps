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
        'android/src/main/kotlin/com/pingidentity/flutter/davinci/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.pingidentity.flutter.davinci'),
    swiftOut: 'ios/ping_davinci/Sources/ping_davinci/Messages.g.swift',
    swiftOptions: SwiftOptions(),
    copyrightHeader: 'pigeons/copyright.txt',
    dartPackageName: 'ping_davinci',
  ),
)
/// Node type tag mirroring the native `Node` sealed hierarchy
/// (`ContinueNode`/`SuccessNode`/`ErrorNode`/`FailureNode`).
///
/// Identical to `ping_journey`'s, and deliberately duplicated rather than shared: Pigeon generates
/// per-package types, and cross-package Pigeon enums are not a supported shape.
enum NodeType { continueNode, successNode, errorNode, failureNode }

/// SDK HTTP/diagnostic logging verbosity. Defaults to [none] (matching the native Android SDK's
/// own default) if [DaVinciConfigMessage.logLevel] is unset — [standard] is a development aid
/// that routes every SDK request/response through platform logs and should not ship as a
/// production default, since it can surface session and token material there.
enum DaVinciLogLevel { none, standard }

/// Structured kind of a local collector validation failure. Bridged instead of the native
/// rendered message, because iOS's `ValidationError.errorMessage` strings are hardcoded English.
enum ValidationErrorKind {
  /// The field is required and has no value.
  required,

  /// The value does not match the collector's validation regex.
  regex,

  /// The value's length is outside the password policy's `[min, max]`.
  invalidLength,

  /// The value has fewer unique characters than the password policy's `min`.
  uniqueCharacter,

  /// The value repeats a character more than the password policy's `max` times.
  maxRepeat,

  /// The value has fewer than `min` characters from the password policy's `character` set.
  minCharacters,
}

/// Which native `PollingStatus` case a [PollingEventMessage] carries.
enum PollingStatusKind {
  /// Native `Continue(retryCount, maxRetries)`: an attempt came back incomplete and polling goes
  /// on. Named so because `continue` is reserved.
  continuing,

  /// Native `TimedOut`: every retry was used. Terminal.
  timedOut,

  /// Native `Expired`: the server reports the challenge expired. Terminal.
  expired,

  /// Native `Error(exception)`. Terminal.
  error,

  /// Native `Complete(status)`. Terminal.
  complete,
}

/// Explicit OpenID endpoint configuration, used in place of a discovery document.
class OpenIdConfigMessage {
  OpenIdConfigMessage({
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    required this.userinfoEndpoint,
  });

  /// The authorization endpoint URL.
  String authorizationEndpoint;

  /// The token endpoint URL.
  String tokenEndpoint;

  /// The userinfo endpoint URL.
  String userinfoEndpoint;

  /// The end-session endpoint URL.
  String? endSessionEndpoint;

  /// The Ping end-IDP-session endpoint URL.
  String? pingEndIdpSessionEndpoint;

  /// The token revocation endpoint URL.
  String? revocationEndpoint;
}

/// Flat, wire-serializable DaVinci configuration.
///
/// DaVinci always runs through an OIDC module, so the OIDC client must be configured through
/// **exactly one** of two paths: the hoisted OIDC fields below (mirroring
/// `ping_journey`'s `JourneyConfigMessage`), or [oidcClientId], an id into `ping_core`'s shared
/// `CoreRuntime.oidcClientRegistry`. Supplying both, or neither, is rejected natively with a
/// typed `argument` error. The hoisted path also requires [clientId], [redirectUri], and at
/// least one of [discoveryEndpoint] or [openId].
class DaVinciConfigMessage {
  DaVinciConfigMessage();

  /// Milliseconds.
  int? timeoutMillis;

  /// Defaults to [DaVinciLogLevel.none] when unset. See [DaVinciLogLevel] for what [standard]
  /// exposes and why it isn't the default.
  DaVinciLogLevel? logLevel;

  /// The OAuth2/OIDC client id.
  String? clientId;

  /// The discovery endpoint URL.
  String? discoveryEndpoint;

  /// Explicit endpoints. When set without [discoveryEndpoint], discovery is skipped.
  OpenIdConfigMessage? openId;

  /// The redirect URI registered for this client.
  String? redirectUri;

  /// OAuth2 scopes requested during authorization.
  List<String?>? scopes;

  /// The `acr_values` authorization parameter. Selects the DaVinci flow on PingOne.
  String? acrValues;

  /// The sign-out redirect URI. Applied on Android only — no equivalent field on iOS.
  String? signOutRedirectUri;

  /// The `state` authorization parameter.
  String? state;

  /// The `nonce` authorization parameter.
  String? nonce;

  /// The `ui_locales` authorization parameter.
  String? uiLocales;

  /// Seconds.
  int? refreshThreshold;

  /// The `login_hint` authorization parameter.
  String? loginHint;

  /// The `display` authorization parameter.
  String? display;

  /// The `prompt` authorization parameter.
  String? prompt;

  /// Additional authorization parameters.
  Map<String?, String?>? additionalParameters;

  /// Whether to use Pushed Authorization Requests (RFC 9126).
  bool? par;

  /// Id of a native OIDC client already registered in `ping_core`'s shared
  /// `CoreRuntime.oidcClientRegistry` (e.g. via `ping_oidc`'s `OidcClient.configure`).
  /// Mutually exclusive with the hoisted OIDC fields above — set this OR them, never both.
  String? oidcClientId;
}

/// One choice of a single- or multi-select collector.
class OptionMessage {
  OptionMessage({required this.label, required this.value});

  /// Display label.
  String label;

  /// Submitted value.
  String value;
}

/// One MFA device offered by a device registration or authentication collector.
class DeviceMessage {
  DeviceMessage({required this.type});

  /// Device id. Present for authentication, absent for registration.
  String? id;

  /// Device type, e.g. `EMAIL`, `SMS`, `TOTP`.
  String type;

  /// Display title.
  String? title;

  /// Display description. Named so because `description` is rejected by Pigeon.
  String? deviceDescription;

  /// Icon URL.
  String? iconSrc;

  /// Whether this is the user's default device. Named so because `default` is reserved.
  bool? isDefault;
}

/// The constraints of a PingOne password policy, so Dart can render hints before submit.
class PasswordPolicyMessage {
  PasswordPolicyMessage();

  /// Minimum length.
  int? lengthMin;

  /// Maximum length.
  int? lengthMax;

  /// Minimum number of unique characters.
  int? minUniqueCharacters;

  /// Maximum number of times one character may repeat.
  int? maxRepeatedCharacters;

  /// Minimum count required from each character set, keyed by the set's characters.
  Map<String?, int?>? minCharacters;
}

/// One `{{key}}` substitution inside a label's [RichContentMessage.content].
class RichContentReplacementMessage {
  RichContentReplacementMessage({required this.key});

  /// The placeholder key, without braces.
  String key;

  /// Display text.
  String? value;

  /// Link target, for `link` replacements.
  String? href;

  /// Replacement type, e.g. `link`.
  String? type;

  /// Link target window, e.g. `_blank`.
  String? target;
}

/// Label content with inline link substitutions.
class RichContentMessage {
  RichContentMessage({required this.content});

  /// Content containing `{{key}}` placeholders.
  String content;

  /// The substitutions for the placeholders in [content].
  List<RichContentReplacementMessage?>? replacements;
}

/// Flat union of every collector's fields. `value` is `Object?`, StandardMessageCodec-backed
/// (covers String/bool/num/Map/List).
///
/// One flat message with nullable fields, following `ping_journey`'s `CallbackMessage`: Pigeon
/// has no sum types, and a class per collector would mean a host-API overload per collector.
class CollectorMessage {
  CollectorMessage({
    required this.type,
    required this.index,
    required this.kind,
  });

  /// The server's field `type` (e.g. `DROPDOWN`, which the factory resolved through its
  /// `inputType` `SINGLE_SELECT`), or the registry key for display collectors that carry none.
  /// Addresses the collector on submit, together with [index].
  String type;

  /// The native collector class this message was mapped from, as a stable camel-case name
  /// (`text`, `password`, `singleSelect`, …), or the native class name for a collector the
  /// bridge has no mapping for. Picks the Dart collector subtype: `PASSWORD` and
  /// `PASSWORD_VERIFY` share one class, and `DROPDOWN`/`RADIO` both resolve to `singleSelect`.
  String kind;

  /// Position among the node's collectors. Addresses the collector on submit.
  int index;

  /// Native collector id.
  String? id;

  /// Form field key.
  String? key;

  /// Display label.
  String? label;

  /// Whether a value is required.
  bool? required;

  /// Current value.
  Object? value;

  /// Choices (single/multi-select).
  List<OptionMessage?>? options;

  /// Text content (label, read-only text, QR code data URI).
  String? content;

  /// Label content with link substitutions.
  RichContentMessage? richContent;

  /// Text shown when a QR code image cannot be rendered.
  String? fallbackText;

  /// Agreement title.
  String? title;

  /// Whether the agreement title is shown.
  bool? titleEnabled;

  /// Whether the field is enabled.
  bool? enabled;

  /// Agreement id.
  String? agreementId;

  /// Whether the agreement content is fetched dynamically.
  bool? useDynamicAgreement;

  /// Button appearance hint.
  String? appearance;

  /// Server-supplied error message for the field.
  String? errorMessage;

  /// Default phone country code.
  String? defaultCountryCode;

  /// Whether the phone number is validated.
  bool? validatePhoneNumber;

  /// Whether the phone extension field is shown.
  bool? showExtension;

  /// Label of the phone extension field.
  String? extensionLabel;

  /// Phone country code.
  String? countryCode;

  /// Phone number.
  String? phoneNumber;

  /// Phone extension. Named so because `extension` is reserved in Dart and Swift.
  String? phoneExtension;

  /// MFA devices (device registration/authentication).
  List<DeviceMessage?>? devices;

  /// Polling interval in milliseconds.
  int? pollIntervalMillis;

  /// Maximum polling retries.
  int? pollRetries;

  /// Polling retries left. Both SDKs carry the count across the server's rewinds to the same
  /// polling form, so it falls by one per simple-polling cycle.
  int? retriesAllowed;

  /// Whether polling checks a challenge's status on the server, rather than only waiting.
  bool? pollChallengeStatus;

  /// The challenge whose status is polled, when [pollChallengeStatus] is set.
  String? challenge;

  /// Password policy constraints.
  PasswordPolicyMessage? passwordPolicy;

  /// Local validation regex.
  String? validationRegex;

  /// Message shown when [validationRegex] does not match.
  String? validationErrorMessage;

  /// Image URL (`ImageCollector`, 2.2.0).
  String? imageUrl;

  /// Link opened when the image is tapped (`ImageCollector`, 2.2.0).
  String? hyperlinkUrl;

  /// Image description. Named so because `description` is rejected by Pigeon.
  String? imageDescription;

  /// Connector metadata (`MetadataCollector`, 2.2.0).
  Map<String?, Object?>? metadata;
}

/// Dart -> native collector value, addressed by `{type, index}` so native can re-resolve it
/// against the cached `ContinueNode`.
class CollectorValueMessage {
  CollectorValueMessage({required this.type, required this.index});

  /// The collector's [CollectorMessage.type].
  String type;

  /// The collector's [CollectorMessage.index].
  int index;

  /// The value to apply.
  Object? value;
}

/// One local validation failure, structured rather than rendered (see [ValidationErrorKind]).
class ValidationErrorMessage {
  ValidationErrorMessage({
    required this.collectorType,
    required this.index,
    required this.kind,
  });

  /// The failing collector's [CollectorMessage.type].
  String collectorType;

  /// The failing collector's [CollectorMessage.index].
  int index;

  /// What failed.
  ValidationErrorKind kind;

  /// Server-supplied message, for [ValidationErrorKind.regex].
  String? message;

  /// Lower bound, for [ValidationErrorKind.invalidLength], [ValidationErrorKind.uniqueCharacter]
  /// and [ValidationErrorKind.minCharacters].
  int? min;

  /// Upper bound, for [ValidationErrorKind.invalidLength] and [ValidationErrorKind.maxRepeat].
  /// Null when the policy leaves it unbounded (native `Int.MAX_VALUE` / `Int.max`).
  int? max;

  /// Character set, for [ValidationErrorKind.minCharacters].
  String? character;
}

/// A mapped native `Node`.
class NodeMessage {
  NodeMessage({required this.type});

  /// Which node subtype this is.
  NodeType type;

  /// Error or failure message.
  String? message;

  /// Failure cause.
  String? cause;

  /// HTTP status of an `ErrorNode` (native 2.2.0 `ErrorNode.status`).
  int? status;

  /// Page id. On an ErrorNode, the id of the ContinueNode it can be retried from.
  String? id;

  /// Page name. On an ErrorNode, the retry node's.
  String? name;

  /// Page description. Named so because `description` is rejected by Pigeon. On an ErrorNode,
  /// the retry node's.
  String? pageDescription;

  /// Page category. On an ErrorNode, the retry node's.
  String? category;

  /// The node's collectors. On an ErrorNode, the collectors of the ContinueNode it can be
  /// retried from (native `ErrorNode.continueNode()`), or null when there is none — non-null is
  /// what marks an ErrorNode as retryable. Native keeps that node cached, so `next` and
  /// `validate` address it by `{type, index}` exactly as before the error.
  List<CollectorMessage?>? collectors;

  /// The raw node input.
  Map<String?, Object?>? input;

  /// An ErrorNode's `ErrorNode.details()`, one map per native `Detail`:
  /// `{statusCode, rawResponse: {id, code, message, details: [{code, target, message,
  /// innerError}]}}`, where `innerError` is native `InnerError.errors` (requirement name to
  /// message) or null. Flattened into per-field errors in Dart, once for both platforms.
  ///
  /// Typed as `List<Object?>?` because Pigeon's generated decoder does an unchecked
  /// `.cast<Map<String?, Object?>?>()` on nested collection element types, which throws at
  /// runtime the first time a real non-empty map arrives. Cast elementwise on read.
  List<Object?>? errorDetails;

  /// `{key, type}` maps for form fields the native collector factory dropped because no
  /// collector is registered for them. `type` is the key the factory looked up (`inputType`,
  /// falling back to `type`); `key` is null for key-less fields such as `ERROR_DISPLAY`.
  /// `List<Object?>?` for the same reason as [errorDetails].
  List<Object?>? unsupportedFields;
}

/// DaVinci's `SuccessNode.session`. Its value is the OAuth authorization code, not tokens —
/// tokens come from [PingDaVinciHostApi.getToken]. The native SDK redeems the code itself
/// (Android at `SuccessNode` time, iOS on the first `token()`), so it is single-use and already
/// spent by the time an app could send it anywhere.
class SessionMessage {
  SessionMessage({required this.authorizationCode});

  /// The authorization code.
  String authorizationCode;
}

/// The OIDC token set of a signed-in DaVinci user.
class TokenMessage {
  TokenMessage({required this.accessToken, required this.expiresIn});

  /// The access token.
  String accessToken;

  /// The OAuth token type, when the server returned one.
  String? tokenType;

  /// The granted scope string, when the server returned one.
  String? scope;

  /// Lifetime in seconds.
  int expiresIn;

  /// The refresh token, when the server returned one.
  String? refreshToken;

  /// The ID token, when the server returned one.
  String? idToken;
}

/// What [PingDaVinciHostApi.retainedState] reports. Every count is 0 once each configured handle
/// has been disposed.
class RetainedStateMessage {
  /// Handles in the shared `davinciRegistry`.
  late int registeredHandles;

  /// Cached `ContinueNode`s: a current form or an `ErrorNode`'s retry node.
  late int cachedNodes;

  /// Cached `SuccessNode` sessions.
  late int cachedSessions;

  /// Per-handle locks serializing the calls that move a flow on. iOS drops each one when its
  /// queue drains, Android on dispose.
  late int flowLocks;

  /// Polls whose native task the bridge still holds.
  late int activePolls;
}

/// One status a running poll reported, normalized so both platforms send the same sequence (see
/// [PingDaVinciHostApi.startPolling]).
class PollingEventMessage {
  PollingEventMessage({required this.pollId, required this.kind});

  /// The id the poll was started with.
  String pollId;

  /// Which status this is.
  PollingStatusKind kind;

  /// The attempt that came back incomplete, from 1, for [PollingStatusKind.continuing].
  int? retryCount;

  /// The number of attempts allowed, for [PollingStatusKind.continuing].
  int? maxRetries;

  /// The server's status, e.g. `approved`, or `continue` for a simple-polling cycle, for
  /// [PollingStatusKind.complete].
  String? status;

  /// What failed, for [PollingStatusKind.error].
  String? errorMessage;
}

/// Native DaVinci operations, all addressed by the handle id [configureDaVinci] returns.
@HostApi()
abstract class PingDaVinciHostApi {
  /// Builds a native DaVinci workflow and registers it in `CoreRuntime.davinciRegistry`,
  /// returning its handle id.
  @async
  String configureDaVinci(DaVinciConfigMessage config);

  /// Starts the flow and returns the first node.
  @async
  NodeMessage start(String daVinciId);

  /// Applies [values] to the current node's collectors and advances the flow.
  @async
  NodeMessage next(String daVinciId, List<CollectorValueMessage?> values);

  /// Applies [values] to the current node's collectors and runs their local validation.
  @async
  List<ValidationErrorMessage?> validate(
    String daVinciId,
    List<CollectorValueMessage?> values,
  );

  /// The authorization code of the `SuccessNode` this handle reached, or null when it has not
  /// reached one. Fails with type `auth` when that node carries no code.
  @async
  SessionMessage? getSession(String daVinciId);

  /// The OIDC tokens of the signed-in user. Fails with type `state` when there is no user —
  /// never an empty token.
  @async
  TokenMessage getToken(String daVinciId);

  /// The OIDC userinfo claims of the signed-in user. [cache] is always passed, because the
  /// native defaults differ (Android `false`, iOS `true`).
  @async
  Map<String?, Object?> getUserInfo(String daVinciId, bool cache);

  /// Signs the user off: ends the OIDC session, revokes the stored tokens, and deletes the
  /// session cookies. `false` means the native sign-off threw; `true` does not prove a session
  /// existed.
  @async
  bool signOff(String daVinciId);

  /// Removes the handle and its cached nodes, cancelling its polls.
  @async
  void dispose(String daVinciId);

  /// Starts polling the `POLLING` collector at `{collectorType, index}` of the current node, and
  /// reports its statuses on [PingDaVinciEventApi.pollingEvents], tagged with [pollId] (chosen
  /// by Dart, so it can listen before any status arrives). The native collector keeps the value
  /// each status implies, which the next [next] submits.
  ///
  /// The sequence is normalized: zero or more [PollingStatusKind.continuing] events, each sent
  /// once that attempt came back incomplete, then exactly one terminal event. A simple-polling
  /// cycle is a single terminal event. The poll is cancelled by [cancelPolling], and by [start],
  /// [next], [signOff] and [dispose] on the same handle; a cancelled poll sends nothing more.
  @async
  void startPolling(
    String daVinciId,
    String pollId,
    String collectorType,
    int index,
  );

  /// Stops reporting [pollId]'s statuses and cancels its native task. Unknown or finished ids
  /// are ignored.
  @async
  void cancelPolling(String pollId);

  /// Diagnostic: the number of polls whose native task the bridge still holds. Exists for the
  /// leak check; not part of the public Dart API.
  @async
  int activePollCount();

  /// Diagnostic: how much per-handle state the bridge holds across every DaVinci handle. Exists
  /// for the configure-to-dispose leak check; not part of the public Dart API.
  @async
  RetainedStateMessage retainedState();

  /// Diagnostic: the collector type keys the native collector factory resolves right now,
  /// sorted. Exists to check that iOS's asynchronous collector registration has completed by
  /// the time [configureDaVinci] returns; not part of the public Dart API. Android lists the
  /// factory's keys; iOS's factory has no key listing, so it probes the core keys only.
  @async
  List<String> registeredCollectorTypes(String daVinciId);
}

/// Native-to-Dart streams. One channel carries every poll's statuses, tagged with their
/// [PollingEventMessage.pollId]: Pigeon's event-channel methods take no parameters, and a
/// channel per poll would need registering and tearing down natively for each one.
@EventChannelApi()
abstract class PingDaVinciEventApi {
  /// Every running poll's statuses.
  PollingEventMessage pollingEvents();
}
