import 'package:dj_tilbud_app/features/referrals/data/datasources/referrals_remote_datasource.dart';
import 'package:dj_tilbud_app/features/referrals/domain/entities/referral.dart';
import 'package:dj_tilbud_app/features/referrals/domain/entities/referral_terms.dart';
import 'package:dj_tilbud_app/features/referrals/domain/repositories/referrals_repository.dart';

class ReferralsRepositoryImpl implements ReferralsRepository {
  ReferralsRepositoryImpl(this._datasource);

  final ReferralsRemoteDatasource _datasource;

  @override
  Future<List<Referral>> fetchMyReferrals() async {
    final rows = await _datasource.fetchMyReferrals();
    return rows.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Referral> createReferral(ReferralInput input) async {
    final row = await _datasource.createReferral(input);
    return row.toEntity();
  }

  @override
  Future<ReferralTermsStatus> fetchReferralTerms() =>
      _datasource.fetchReferralTerms();

  @override
  Future<ReferralTermsStatus> acceptReferralTerms() =>
      _datasource.acceptReferralTerms();
}
