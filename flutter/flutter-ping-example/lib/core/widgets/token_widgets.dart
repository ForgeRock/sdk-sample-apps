/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ping_example/core/theme/app_theme.dart';
import 'package:ping_example/core/util/jwt.dart';
import 'package:ping_example/core/widgets/app_card.dart';

/// A labelled token value in monospace, with a copy button.
class TokenSection extends StatelessWidget {
  const TokenSection({
    super.key,
    required this.label,
    required this.value,
    this.copyable = true,
  });

  final String label;
  final String value;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.sectionHeader(context)),
          const SizedBox(height: 4),
          AppCard(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                if (copyable)
                  InkWell(
                    // Clipboard contents persist system-wide (other apps on Android can read
                    // them) — fine for a sample demonstrating token shapes, but avoid copying
                    // this pattern for production token displays without considering that.
                    onTap: () => Clipboard.setData(ClipboardData(text: value)),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.copy,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A key/value line inside an [AppCard], for userinfo and ID-token claims.
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value});

  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: style?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value?.toString() ?? '', style: style)),
        ],
      ),
    );
  }
}

/// A live countdown to the access token's expiry.
///
/// The bridge exposes the lifetime as issued (`expiresIn`), not an absolute time. When the access
/// token is a JWT its `exp` claim is used, which is exact. Otherwise the countdown starts when this
/// token first reached the app, so it is an estimate. Give the widget a key derived from the token
/// so a refreshed token restarts it.
class ExpiryRow extends StatefulWidget {
  const ExpiryRow({super.key, required this.accessToken, required this.expiresIn});

  final String accessToken;
  final int expiresIn;

  @override
  State<ExpiryRow> createState() => _ExpiryRowState();
}

class _ExpiryRowState extends State<ExpiryRow> {
  /// When each token (by hash, so the token itself isn't retained) was first shown, so leaving and
  /// returning to the screen doesn't restart an estimated countdown.
  static final Map<int, DateTime> _firstSeen = {};

  Timer? _timer;
  late DateTime _expiresAt;
  late bool _fromClaim;

  @override
  void initState() {
    super.initState();
    _resolve();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(ExpiryRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accessToken != widget.accessToken ||
        oldWidget.expiresIn != widget.expiresIn) {
      _resolve();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resolve() {
    final exp = decodeJwtClaims(widget.accessToken)?['exp'];
    if (exp is num) {
      _expiresAt = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
      _fromClaim = true;
    } else {
      final seen = _firstSeen.putIfAbsent(
        widget.accessToken.hashCode,
        DateTime.now,
      );
      _expiresAt = seen.add(Duration(seconds: widget.expiresIn));
      _fromClaim = false;
    }
  }

  static String _format(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return [
      if (hours > 0) '${hours}h',
      if (hours > 0 || minutes > 0) '${minutes}m',
      '${seconds}s',
    ].join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = _expiresAt.difference(DateTime.now());
    final expired = remaining.isNegative;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Expires In', style: AppTheme.sectionHeader(context)),
          const SizedBox(height: 4),
          AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expired
                      ? 'Expired ${_format(-remaining)} ago'
                      : _format(remaining),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: expired ? theme.colorScheme.error : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _fromClaim
                      ? "Lifetime ${widget.expiresIn}s, from the token's exp claim"
                      : 'Lifetime ${widget.expiresIn}s, estimated from when this token reached the app',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The decoded claims of an ID token (not verified), or nothing if [idToken] isn't a JWT.
class IdTokenClaimsCard extends StatelessWidget {
  const IdTokenClaimsCard({super.key, required this.idToken});

  final String idToken;

  static const _timeClaims = {'iat', 'exp', 'nbf', 'auth_time'};

  static String _two(int value) => value.toString().padLeft(2, '0');

  static String _formatClaim(String name, Object? value) {
    if (_timeClaims.contains(name) && value is num) {
      final time = DateTime.fromMillisecondsSinceEpoch(value.toInt() * 1000);
      return '${time.year}-${_two(time.month)}-${_two(time.day)} '
          '${_two(time.hour)}:${_two(time.minute)}:${_two(time.second)}  ($value)';
    }
    return value?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final claims = decodeJwtClaims(idToken);
    if (claims == null || claims.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ID Token Claims (not verified)',
            style: AppTheme.sectionHeader(context),
          ),
          const SizedBox(height: 4),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final MapEntry(:key, :value) in claims.entries)
                  InfoRow(label: key, value: _formatClaim(key, value)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
