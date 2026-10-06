/// Can the signed-in DJ still place a quote on an internal job?
///
/// Resolved SERVER-side by `GET /api/dj/jobs/{id}/bid-status` (web `domain/djBidStatus.ts`, the
/// read-only twin of the guard chain in `POST /api/jobs/{id}/quotes`). Mobile cannot compute this
/// itself: the answer needs every DJ's pending quotes on the job and their tiers, and RLS hides
/// both from a DJ session. It only ever matters on the quote form, which a push deep-link (or a
/// days-old row in the notification centre) can open for a job the feed correctly hides.
///
/// ⚠️ `Job.status` alone is NOT this answer. A `sent` job is still biddable when a pending quote
/// was lost/overwritten, and an `open` job can already be full (`first_quote_only`) or closed to
/// THIS DJ by the tier quota. Do not "simplify" the gate to a status check.
///
/// Fails OPEN: a malformed body resolves to [DjBidStatus.open], and the datasource maps any
/// transport error to it too. The quote route remains the authority.
class DjBidStatus {
  const DjBidStatus({required this.canBid, this.reason, this.message});

  const DjBidStatus.open() : canBid = true, reason = null, message = null;

  final bool canBid;

  /// Stable server code: `archived`, `paused`, `not_biddable_status`, `already_bid`, `full`,
  /// `tier_quota`, `not_found`. Null when [canBid] is true.
  final String? reason;

  /// User-facing Danish reason from the server. Null when [canBid] is true.
  final String? message;

  factory DjBidStatus.fromJson(Map<String, dynamic> json) {
    final canBid = json['can_bid'];
    if (canBid is! bool) return const DjBidStatus.open();
    if (canBid) return const DjBidStatus.open();
    return DjBidStatus(
      canBid: false,
      reason: json['reason'] as String?,
      message: json['message'] as String?,
    );
  }

  /// Banner headline for the blocked card. Body is [message] (or [fallbackMessage]).
  String get title => switch (reason) {
    'already_bid' => 'Du har allerede budt på jobbet',
    'full' || 'tier_quota' => 'Jobbet kan ikke modtage flere tilbud',
    _ => 'Jobbet er ikke længere åbent for bud',
  };

  static const fallbackMessage =
      'Dette job tager ikke imod bud lige nu. Du kan se andre ledige jobs under "Nye jobs".';
}
