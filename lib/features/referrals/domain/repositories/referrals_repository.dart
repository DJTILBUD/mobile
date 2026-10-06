import 'package:dj_tilbud_app/features/referrals/domain/entities/referral.dart';
import 'package:dj_tilbud_app/features/referrals/domain/entities/referral_terms.dart';

abstract class ReferralsRepository {
  /// The signed-in performer's own referrals, newest first.
  Future<List<Referral>> fetchMyReferrals();

  /// Hands a job to DJTILBUD. All logic (ExtJob + Referrals row + admin Action + push) lives in
  /// the web-app route `POST /api/referrals`; mobile only calls it.
  Future<Referral> createReferral(ReferralInput input);

  /// Whether the performer accepted the referral terms. They must, before the form and list show
  /// and before `POST /api/referrals` accepts a referral.
  Future<ReferralTermsStatus> fetchReferralTerms();

  /// Records the acceptance via the web-app (`POST /api/referrals/terms`).
  Future<ReferralTermsStatus> acceptReferralTerms();
}
