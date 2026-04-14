import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the currently-pending foreground notification.
/// Set to a [RemoteMessage] to show the in-app banner.
/// Cleared (null) automatically after the banner is dismissed.
final inAppNotificationProvider = StateProvider<RemoteMessage?>((ref) => null);
