import 'package:app_badge_plus/app_badge_plus.dart';

/// Sets the OS app-icon badge to [count] (0 clears it).
///
/// Best-effort + client-side: it reflects the unread notification count while the
/// app is open/opened (and clears as the user reads), reconciling on launch/resume.
/// It does NOT update the icon while the app is fully closed — that would require
/// sending the badge inside each push (aps.badge). Numeric badges are primarily an
/// iOS feature; on unsupported Android launchers this simply no-ops.
Future<void> setAppIconBadge(int count) async {
  try {
    await AppBadgePlus.updateBadge(count < 0 ? 0 : count);
  } catch (_) {
    // Unsupported device/launcher — ignore.
  }
}
