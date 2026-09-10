/// Which musician walkthrough to show. Mirrors the web app's `MusicianVariant`
/// (`useFirstWinPopup.ts`) and the `p_variant` argument of the DB RPC
/// `mark_first_win_shown`. The DJ role has no variant.
enum MusicianVariant {
  /// Won a job played together with a DJ (an internal `Jobs` win, or an ExtJob
  /// whose `role_type` is not `musician_only`).
  withDj,

  /// Won a job played alone — a `musician_only` ExtJob.
  solo;

  /// The exact string the RPC expects. Never send `.name` — it would be
  /// `withDj`, which the function rejects with "Invalid variant for musician".
  String get rpcValue => switch (this) {
    MusicianVariant.withDj => 'with_dj',
    MusicianVariant.solo => 'solo',
  };
}

/// Which musician walkthrough is still owed, given what they have already seen
/// and what they have actually won. Pure mirror of step 3 of the web hook's
/// `musicianVariantToShowQuery` — `with_dj` wins when both are pending.
///
/// A variant is only returned when a REAL win backs it, so a musician who has
/// only ever played with a DJ never gets the solo walkthrough (which tells them
/// to agree invoicing with the customer — the DJ's job on that booking).
MusicianVariant? pendingMusicianVariant({
  required bool withDjPending,
  required bool soloPending,
  required bool hasWithDjWin,
  required bool hasSoloWin,
}) {
  if (!withDjPending && !soloPending) return null;
  if (withDjPending && hasWithDjWin) return MusicianVariant.withDj;
  if (soloPending && hasSoloWin) return MusicianVariant.solo;
  return null;
}

/// Whether the first-win walkthrough should run, and (for musicians) which one.
class FirstWinDecision {
  const FirstWinDecision({required this.shouldShow, this.musicianVariant});

  const FirstWinDecision.hidden() : shouldShow = false, musicianVariant = null;

  final bool shouldShow;

  /// Null for DJs (they have a single walkthrough) and whenever [shouldShow] is
  /// false. Must be carried all the way to `markShown` — the RPC needs it.
  final MusicianVariant? musicianVariant;
}
