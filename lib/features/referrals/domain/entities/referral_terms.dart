/// The referral terms a performer must accept before creating referrals (web-app
/// `referral_terms_accepted_at`, `GET/POST /api/referrals/terms`). Mirrors web
/// `REFERRAL_TERMS_URL` in `helpers/referrals.ts`.
const String kReferralTermsUrl =
    'https://djtilbud.dk/referral-handelsbetingelser';

class ReferralTermsStatus {
  const ReferralTermsStatus({
    required this.accepted,
    this.acceptedAt,
    this.termsUrl = kReferralTermsUrl,
  });

  final bool accepted;
  final DateTime? acceptedAt;
  final String termsUrl;

  factory ReferralTermsStatus.fromJson(Map<String, dynamic> json) {
    final at = json['acceptedAt'] as String?;
    final url = json['termsUrl'] as String?;
    return ReferralTermsStatus(
      accepted: json['accepted'] as bool? ?? false,
      acceptedAt: at == null ? null : DateTime.tryParse(at),
      termsUrl: (url == null || url.isEmpty) ? kReferralTermsUrl : url,
    );
  }
}
