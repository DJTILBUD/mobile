/// Withdrawing a bid ("Træk bud tilbage"): the pure window rule.
///
/// Dart mirror of web `web-app/src/helpers/bidWithdrawal.ts`. A performer may
/// withdraw their own still-open bid (DJ quote `pending`, sax offer `sent`)
/// within 10 minutes of placing it, the same window as editing a DJ quote.
/// The server routes (`DELETE /api/quotes/{id}`,
/// `DELETE /api/service-offer/{offerId}`) are the authority; the app only uses
/// this to decide whether to show the action.
library;

/// Same window as the DJ quote edit (`kEditWindowMinutes`).
const kBidWithdrawWindowMinutes = 10;

DateTime bidWithdrawDeadline(DateTime createdAt) =>
    createdAt.add(const Duration(minutes: kBidWithdrawWindowMinutes));

/// True while `now <= createdAt + 10 minutes`. A missing timestamp is never
/// withdrawable (web: an unparseable timestamp returns false).
bool isWithinBidWithdrawWindow(DateTime? createdAt, [DateTime? now]) {
  if (createdAt == null) return false;
  final current = now ?? DateTime.now();
  return !current.isAfter(bidWithdrawDeadline(createdAt));
}

/// Whole seconds left in the window, never negative.
int bidWithdrawSecondsLeft(DateTime createdAt, [DateTime? now]) {
  final diff =
      bidWithdrawDeadline(
        createdAt,
      ).difference(now ?? DateTime.now()).inSeconds;
  return diff < 0 ? 0 : diff;
}

/// `mm:ss` for the countdown copy.
String formatBidWithdrawCountdown(int secondsLeft) {
  final s = secondsLeft < 0 ? 0 : secondsLeft;
  final mm = (s ~/ 60).toString().padLeft(2, '0');
  final ss = (s % 60).toString().padLeft(2, '0');
  return '$mm:$ss';
}

/// Pins the bids still inside the 10 minute edit/withdraw window to the top,
/// keeping the existing order inside both groups (stable partition). Mirror of
/// web `pinBidsInWithdrawWindow` in `helpers/bidWithdrawal.ts`.
List<T> pinBidsInWithdrawWindow<T>(
  List<T> items,
  DateTime? Function(T item) createdAt, [
  DateTime? now,
]) {
  final current = now ?? DateTime.now();
  final inWindow = <T>[];
  final rest = <T>[];
  for (final item in items) {
    (isWithinBidWithdrawWindow(createdAt(item), current) ? inWindow : rest)
        .add(item);
  }
  return [...inWindow, ...rest];
}

/// Time until the first of these bids leaves its window, or null when none is
/// inside one. Mirror of web `msUntilNextBidWindowEnd`.
Duration? timeUntilNextBidWindowEnd(
  Iterable<DateTime?> createdAts, [
  DateTime? now,
]) {
  final current = now ?? DateTime.now();
  Duration? next;
  for (final createdAt in createdAts) {
    if (createdAt == null) continue;
    final left = bidWithdrawDeadline(createdAt).difference(current);
    if (!left.isNegative && (next == null || left < next)) next = left;
  }
  return next;
}
