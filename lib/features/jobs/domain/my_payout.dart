/// The signed-in performer's own self-billing payout on one played job: when the money goes out,
/// when it is at the latest on their account (bank date + 3), and the afregning PDF once it has
/// been emailed.
///
/// Resolved SERVER-side by `GET /api/payouts/mine` (web `helpers/payoutView.ts` +
/// `helpers/payoutDates.ts`). Mobile cannot compute it: the Payouts / SelfBillingDocuments /
/// PayoutBatchLines tables are admin-only under RLS, and the forecast mirrors admin's weekly
/// batch rule. Web renders the same card in `src/components/PayoutStatusCard.tsx`.
enum MyPayoutState { scheduled, paid, waiting, preparing, manual }

class MyPayout {
  const MyPayout({
    required this.state,
    this.executionDate,
    this.latestOnAccountDate,
    this.isForecast = false,
    this.amountDkk,
    this.waitingFor,
    this.documentSbNumber,
    this.documentUrl,
  });

  final MyPayoutState state;

  /// Bank execution date (YYYY-MM-DD), null when no date can be promised.
  final DateTime? executionDate;

  /// Execution date + 3 days.
  final DateTime? latestOnAccountDate;

  /// True while [executionDate] is a forecast (no batch line yet).
  final bool isForecast;
  final double? amountDkk;

  /// `missing_bank` or `missing_cvr` for [MyPayoutState.waiting].
  final String? waitingFor;
  final String? documentSbNumber;
  final String? documentUrl;

  static DateTime? _date(Object? v) =>
      v is String && v.length >= 10
          ? DateTime.tryParse(v.substring(0, 10))
          : null;

  /// Null for `{payout: null}` or an unknown state (renders nothing rather than guessing).
  static MyPayout? fromResponse(Map<String, dynamic> body) {
    final json = body['payout'];
    if (json is! Map<String, dynamic>) return null;
    final state =
        MyPayoutState.values.where((s) => s.name == json['state']).firstOrNull;
    if (state == null) return null;
    final doc = json['document'];
    return MyPayout(
      state: state,
      executionDate: _date(json['executionDate']),
      latestOnAccountDate: _date(json['latestOnAccountDate']),
      isForecast: json['isForecast'] == true,
      amountDkk: (json['amountDkk'] as num?)?.toDouble(),
      waitingFor: json['waitingFor'] as String?,
      documentSbNumber:
          doc is Map<String, dynamic> ? doc['sbNumber'] as String? : null,
      documentUrl: doc is Map<String, dynamic> ? doc['url'] as String? : null,
    );
  }
}
