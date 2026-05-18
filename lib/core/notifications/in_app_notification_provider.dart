import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the currently-pending foreground notification.
/// Set to a [RemoteMessage] to show the in-app banner.
/// Cleared (null) automatically after the banner is dismissed.
final inAppNotificationProvider = StateProvider<RemoteMessage?>((ref) => null);

/// Tracks the conversation ID the user currently has open.
/// Set to a conversation ID when entering ConversationDetailScreen,
/// cleared to null on exit. Used to suppress chat_message banners
/// for the conversation already on screen.
final activeConversationIdProvider = StateProvider<int?>((ref) => null);

/// When true, the app-level keyboard dismiss bar is hidden.
/// Set by screens that have their own bottom input (e.g. ConversationDetailScreen)
/// so the global bar doesn't overlay the input field.
final suppressKeyboardDismissBarProvider = StateProvider<bool>((ref) => false);
