import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';

/// Broadcast-based "is typing" for the DJTILBUD support conversation. Ephemeral (no DB / no RLS):
/// both sides join `support-typing-<id>`. This musician side sends `from: 'user'` and listens for
/// the admin's `from: 'admin'`. State is `true` while the admin is typing, auto-clearing ~4s after
/// the last event. Realtime lives in this provider (never in a widget) per the app's architecture.
class SupportTypingNotifier extends StateNotifier<bool> {
  SupportTypingNotifier(this._conversationId) : super(false) {
    _subscribe();
  }

  final int _conversationId;
  RealtimeChannel? _channel;
  DateTime _lastSent = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _clearTimer;

  void _subscribe() {
    _channel =
        supabase
            .channel('support-typing-$_conversationId')
            .onBroadcast(
              event: 'typing',
              callback: (payload) {
                final inner = payload['payload'];
                final from = inner is Map ? inner['from'] : null;
                if (from == 'user') return; // ignore our own role
                if (!mounted) return;
                state = true;
                _clearTimer?.cancel();
                _clearTimer = Timer(const Duration(seconds: 4), () {
                  if (mounted) state = false;
                });
              },
            )
            .subscribe();
  }

  void notifyTyping() {
    final now = DateTime.now();
    if (now.difference(_lastSent).inMilliseconds < 1500) return; // throttle
    _lastSent = now;
    _channel?.sendBroadcastMessage(event: 'typing', payload: {'from': 'user'});
  }

  @override
  void dispose() {
    _clearTimer?.cancel();
    if (_channel != null) supabase.removeChannel(_channel!);
    super.dispose();
  }
}

final supportTypingProvider = StateNotifierProvider.autoDispose
    .family<SupportTypingNotifier, bool, int>(
      (ref, conversationId) => SupportTypingNotifier(conversationId),
    );
