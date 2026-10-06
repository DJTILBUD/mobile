import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_provider.dart';
import 'package:dj_tilbud_app/features/referrals/data/datasources/referrals_remote_datasource.dart';
import 'package:dj_tilbud_app/features/referrals/data/repositories/referrals_repository_impl.dart';
import 'package:dj_tilbud_app/features/referrals/domain/entities/referral.dart';
import 'package:dj_tilbud_app/features/referrals/domain/entities/referral_terms.dart';
import 'package:dj_tilbud_app/features/referrals/domain/repositories/referrals_repository.dart';

final referralsRepositoryProvider = Provider<ReferralsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ReferralsRepositoryImpl(ReferralsRemoteDatasource(client));
});

/// The signed-in performer's referrals. Screen-scoped, so autoDispose.
final referralsProvider = FutureProvider.autoDispose<List<Referral>>((ref) {
  return ref.watch(referralsRepositoryProvider).fetchMyReferrals();
});

/// Whether the performer accepted the referral terms. Screen-scoped, so autoDispose: re-checked
/// every time the screen opens (an acceptance on the web counts here too).
final referralTermsProvider = FutureProvider.autoDispose<ReferralTermsStatus>((
  ref,
) {
  return ref.watch(referralsRepositoryProvider).fetchReferralTerms();
});

class CreateReferralNotifier extends StateNotifier<AsyncValue<void>> {
  CreateReferralNotifier(this._repository, this._ref)
    : super(const AsyncData(null));

  final ReferralsRepository _repository;
  final Ref _ref;

  /// Returns true on success. The error (a Danish, user-facing message from the web route) is
  /// left in [state] for the screen to show.
  Future<bool> submit(ReferralInput input) async {
    if (mounted) state = const AsyncLoading();
    try {
      await _repository.createReferral(input);
      if (mounted) state = const AsyncData(null);
      _ref.invalidate(referralsProvider);
      return true;
    } catch (e, st) {
      // An autoDispose notifier can be disposed mid-await; see MarkAdminMessageReadNotifier.
      if (mounted) state = AsyncError(e, st);
      return false;
    }
  }
}

final createReferralProvider = StateNotifierProvider.autoDispose<
  CreateReferralNotifier,
  AsyncValue<void>
>((ref) => CreateReferralNotifier(ref.watch(referralsRepositoryProvider), ref));
