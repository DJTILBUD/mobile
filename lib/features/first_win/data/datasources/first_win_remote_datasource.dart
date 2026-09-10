import 'package:dj_tilbud_app/features/first_win/domain/entities/first_win_decision.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads/writes the first-win popup state. Mirrors the web-app hook
/// `web-app/src/hooks/useFirstWinPopup.ts` — keep the two in sync.
///
/// ⚠️ Musicians have TWO independent popups (migration
/// `20260522000002_musician_first_win_split`): `Musicians.first_win_with_dj_shown_at`
/// and `first_win_solo_shown_at`. The legacy single `Musicians.first_win_shown_at`
/// column still exists but is **no longer written by anything** — reading it (which
/// this file used to do) means the popup can never be marked as seen. DJs are
/// unchanged and still use `DjInfos.first_win_shown_at`.
class FirstWinRemoteDatasource {
  FirstWinRemoteDatasource(this._client);

  final SupabaseClient _client;

  // ── DJ ────────────────────────────────────────────────────────────────────

  Future<DateTime?> fetchDjShownAt(String userId) async {
    final row =
        await _client
            .from('DjInfos')
            .select('first_win_shown_at')
            .eq('id', userId)
            .maybeSingle();
    final value = row?['first_win_shown_at'] as String?;
    return value == null ? null : DateTime.parse(value);
  }

  Future<bool> djHasWon(String userId) async {
    final rows = await _client
        .from('Quotes')
        .select('id')
        .eq('dj_id', userId)
        .eq('status', 'won')
        .limit(1);
    return rows.isNotEmpty;
  }

  // ── Musician ──────────────────────────────────────────────────────────────

  /// The variant still pending for this musician, or null when there is nothing
  /// to show. Mirrors `musicianVariantToShowQuery` in the web hook exactly.
  Future<MusicianVariant?> fetchMusicianVariantToShow(String userId) async {
    final musician =
        await _client
            .from('Musicians')
            .select('first_win_with_dj_shown_at, first_win_solo_shown_at')
            .eq('id', userId)
            .maybeSingle();
    if (musician == null) return null;

    final withDjPending = musician['first_win_with_dj_shown_at'] == null;
    final soloPending = musician['first_win_solo_shown_at'] == null;
    if (!withDjPending && !soloPending) return null;

    final wonOffers = await _client
        .from('ServiceOffers')
        .select('job_id, ext_job_id')
        .eq('musician_id', userId)
        .eq('status', 'won');
    if (wonOffers.isEmpty) return null;

    final hasWithDjViaJob = wonOffers.any((o) => o['job_id'] != null);
    final extJobIds =
        wonOffers
            .where((o) => o['ext_job_id'] != null)
            .map((o) => (o['ext_job_id'] as num).toInt())
            .toList();

    var hasWithDjViaExt = false;
    var hasSoloViaExt = false;
    if (extJobIds.isNotEmpty) {
      final extJobs = await _client
          .from('ExtJobs')
          .select('id, role_type')
          .inFilter('id', extJobIds);
      hasWithDjViaExt = extJobs.any((e) => e['role_type'] != 'musician_only');
      hasSoloViaExt = extJobs.any((e) => e['role_type'] == 'musician_only');
    }

    return pendingMusicianVariant(
      withDjPending: withDjPending,
      soloPending: soloPending,
      hasWithDjWin: hasWithDjViaJob || hasWithDjViaExt,
      hasSoloWin: hasSoloViaExt,
    );
  }

  // ── Dismiss ───────────────────────────────────────────────────────────────

  /// ⚠️ [variant] is REQUIRED for musicians. The RPC signature is
  /// `mark_first_win_shown(p_role text, p_variant text DEFAULT NULL)` and it
  /// raises `Invalid variant for musician: <NULL>` when the role is `musician`
  /// and no variant is passed — which is exactly how the popup ended up
  /// reappearing on every app launch.
  Future<void> markShown({required bool isDj, MusicianVariant? variant}) async {
    if (isDj) {
      await _client.rpc('mark_first_win_shown', params: {'p_role': 'dj'});
      return;
    }
    if (variant == null) {
      throw ArgumentError(
        'mark_first_win_shown requires a variant for the musician role',
      );
    }
    await _client.rpc(
      'mark_first_win_shown',
      params: {'p_role': 'musician', 'p_variant': variant.rpcValue},
    );
  }
}
