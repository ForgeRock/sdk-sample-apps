/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'callback/callback.dart';

/// A step in a Journey. Dart-side re-inflation of the wire [NodeMessage]/`NodeType` pair — see
/// `node_mapper.dart`.
sealed class JourneyNode {
  const JourneyNode();
}

/// The Journey is waiting on user input: render [callbacks] and submit via `JourneyClient.next`.
final class ContinueNode extends JourneyNode {
  /// Creates a continue node from its wire-message fields.
  const ContinueNode({
    required this.journeyId,
    required this.callbacks,
    this.header,
    this.description,
    this.stage,
  });

  /// The native `Journey` handle this node belongs to; needed to call `next()`.
  final String journeyId;

  /// The callbacks to render and collect values for before calling `JourneyClient.next()`.
  final List<Callback> callbacks;

  /// The title to display for this step, if provided by the server.
  final String? header;

  /// Additional descriptive text to display for this step, if provided by the server.
  final String? description;

  /// The server-defined stage identifier for this step, if provided.
  final String? stage;
}

/// The Journey completed successfully; call `JourneyClient.user()` for tokens/userinfo.
final class SuccessNode extends JourneyNode {
  /// Creates a success node.
  const SuccessNode();
}

/// A recoverable error was reported by the server (e.g. invalid credentials).
final class ErrorNode extends JourneyNode {
  /// Creates an error node from its wire-message fields.
  const ErrorNode({required this.message, this.status});

  /// The human-readable error message reported by the server.
  final String message;

  /// HTTP status of the server error response, when present.
  final int? status;
}

/// An unrecoverable failure (network, native SDK exception, or unmapped node type).
final class FailureNode extends JourneyNode {
  /// Creates a failure node describing why the Journey could not continue.
  const FailureNode({required this.cause});

  /// A description of the underlying failure (e.g. network error, native exception).
  final String cause;
}
