/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

/// The outcome of a browser-based [OidcClient.authorize] call.
///
/// A two-case closed union is a value type, not a `Node`/mapper hierarchy — see
/// `IMPLEMENTATION_PLAN_OIDC.md`'s explicit carve-out for this and [OidcError].
sealed class AuthorizeResult {
  const AuthorizeResult();
}

/// The user completed the browser login flow successfully.
final class AuthorizeSuccess extends AuthorizeResult {
  /// Creates an [AuthorizeSuccess].
  const AuthorizeSuccess();
}

/// The user dismissed the browser without completing login. Not an error — a valid outcome the
/// UI should route back to a login screen for.
final class AuthorizeCancel extends AuthorizeResult {
  /// Creates an [AuthorizeCancel].
  const AuthorizeCancel();
}
