import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/ext_job.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:dj_tilbud_app/features/profile/domain/performer_stats.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';

/// Stats count a booking ONLY once it reaches `ready_for_billing` — for internal
/// jobs and ext jobs alike.
///
/// IMPORTANT: `ready_for_billing` does NOT imply the event already happened. Real
/// profiles carry ready_for_billing jobs months in the future, so the screen must
/// split earned (event date passed) from upcoming rather than calling the sum
/// "tjent". Do not assume this status means "played".
///
/// Note `djExtJobsProvider` also returns `sent`/`closed`/`customer_contacted` (the
/// date-collision guard needs them), so this filter is load-bearing — without it an
/// unconfirmed job would be counted as earnings.

/// Normalised stat entries plus a count of played bookings we could NOT attribute
/// money to (a null honorar / musician payout on legacy rows). Surfaced in the UI:
/// silently dropping them would understate someone's earnings, which reads as a bug.
class StatEntries {
  const StatEntries({required this.entries, required this.excluded});

  final List<StatEntry> entries;
  final int excluded;
}

/// Whether a signed-in session exists.
///
/// Behind a provider on purpose: (a) it re-evaluates when auth flips, so sign-out is
/// caught rather than a stale `true` being cached, and (b) widget tests can override
/// it without booting Supabase. The screen MUST check this before watching anything
/// below — the session-scoped providers resolve `supabase.auth.currentUser!.id` in
/// their factories and throw the instant the session is gone.
final hasSessionProvider = Provider<bool>((ref) {
  ref.watch(authStateProvider); // recompute on every auth change
  return supabase.auth.currentUser != null;
});

/// Selected calendar year for the stats screen; null = all time.
final statsYearProvider = StateProvider<int?>((ref) => DateTime.now().year);

/// Builds the role's stat entries from the existing won-work providers.
final statEntriesProvider =
    Provider.family<AsyncValue<StatEntries>, MusicianRole>((ref, role) {
      return role == MusicianRole.dj ? _djEntries(ref) : _musicianEntries(ref);
    });

AsyncValue<StatEntries> _djEntries(Ref ref) {
  // A DJ earns from BOTH won internal quotes and assigned ext jobs — counting only
  // one would understate their total.
  final quotesAsync = ref.watch(wonDjQuotesProvider);
  final extAsync = ref.watch(djExtJobsProvider);

  final error = quotesAsync.error ?? extAsync.error;
  if (error != null) return AsyncValue.error(error, StackTrace.current);

  final quotes = quotesAsync.valueOrNull;
  final extJobs = extAsync.valueOrNull;
  if (quotes == null || extJobs == null) return const AsyncValue.loading();

  final entries = <StatEntry>[];
  var excluded = 0;

  for (final q in quotes) {
    if (q.job.status != JobStatus.readyForBilling) continue;
    // djPayout is the canonical figure: honours dj_payout_override and the
    // date-aware platform fee (0.80 / 0.75 / 0.715 by job created_at).
    entries.add(
      StatEntry(
        date: q.job.date,
        payoutDkk: q.djPayout,
        eventType: q.job.eventType,
        region: q.job.region,
        guestsAmount: q.job.guestsAmount,
        genres: q.job.genres,
      ),
    );
  }

  for (final e in extJobs) {
    if (e.status != ExtJobStatus.readyForBilling) continue;
    // NEVER fall back to fullAmount — that is the customer total and would both
    // leak our cut and wildly overstate the DJ's earnings.
    final honorar = e.honorar;
    if (honorar == null) {
      excluded++;
      continue;
    }
    entries.add(
      StatEntry(
        date: e.date,
        payoutDkk: honorar.round(),
        eventType: e.eventType,
        region: e.region,
        guestsAmount: e.guestsAmount,
      ),
    );
  }

  return AsyncValue.data(StatEntries(entries: entries, excluded: excluded));
}

AsyncValue<StatEntries> _musicianEntries(Ref ref) {
  // A saxophonist ALWAYS has a ServiceOffer — internal job or ext job — so won
  // offers are the complete picture; there is no admin-assigned-without-offer case
  // to chase. For an ext job, `offer.job` comes from ExtJobModel.toJobModel(), which
  // carries the ext job's status through, so the ready_for_billing gate below works
  // identically for both.
  final offersAsync = ref.watch(wonServiceOffersProvider);
  if (offersAsync.error != null) {
    return AsyncValue.error(offersAsync.error!, StackTrace.current);
  }
  final offers = offersAsync.valueOrNull;
  if (offers == null) return const AsyncValue.loading();

  final entries = <StatEntry>[];
  var excluded = 0;

  for (final o in offers) {
    if (o.job.status != JobStatus.readyForBilling) continue;
    final payout = o.musicianPayoutDkk;
    if (payout == null) {
      excluded++; // legacy offer with no stored payout — cannot be attributed
      continue;
    }
    // A saxophonist's pay is ALWAYS exactly ServiceOffers.musician_payout_dkk and
    // nothing else (product rule). It is kept in sync server-side — the extra-hours
    // route rewrites it as base + extra — so do NOT add extra hours or the
    // special-request fee on top here; that would double-count.
    entries.add(
      StatEntry(
        date: o.job.date,
        payoutDkk: payout,
        eventType: o.job.eventType,
        region: o.job.region,
        guestsAmount: o.job.guestsAmount,
      ),
    );
  }

  return AsyncValue.data(StatEntries(entries: entries, excluded: excluded));
}

/// The aggregated stats for the current role + selected year.
final performerStatsProvider =
    Provider.family<AsyncValue<PerformerStats>, MusicianRole>((ref, role) {
      final year = ref.watch(statsYearProvider);
      return ref
          .watch(statEntriesProvider(role))
          .whenData(
            (e) => computeStats(e.entries, now: DateTime.now(), year: year),
          );
    });

/// Years the performer actually has played bookings in (newest first).
final statsYearsProvider = Provider.family<List<int>, MusicianRole>((
  ref,
  role,
) {
  final entries = ref.watch(statEntriesProvider(role)).valueOrNull;
  if (entries == null) return const [];
  return statYears(entries.entries);
});
