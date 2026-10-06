/// The performer's own reference on their self-billing afregning
/// (`PrivateDjInfos` / `PrivateMusiciansInfo.self_billing_reference_format`).
///
/// Mirrors `web-app/src/helpers/selfBillingReferenceFormat.ts` (same values,
/// same Danish copy; change both together). Our Afregningsnr. stays the legal
/// number; a format only adds the performer's own number per gig, computed by
/// admin when the afregning is issued. NOT billing-locked, so it is saved on
/// its own, never as part of the locked payment form.
enum SelfBillingReferenceFormat {
  standard('standard'),
  dateSeq('date_seq');

  const SelfBillingReferenceFormat(this.dbValue);

  final String dbValue;

  /// Unknown or missing values read as [standard], like the DB default.
  static SelfBillingReferenceFormat fromDb(String? value) =>
      SelfBillingReferenceFormat.values.firstWhere(
        (f) => f.dbValue == value,
        orElse: () => SelfBillingReferenceFormat.standard,
      );

  String get label => switch (this) {
    SelfBillingReferenceFormat.standard => 'Brug afregningsnummeret',
    SelfBillingReferenceFormat.dateSeq => 'Dato + løbenummer',
  };

  String get description => switch (this) {
    SelfBillingReferenceFormat.standard =>
      'Du bogfører afregningen under vores afregningsnr., fx SB-2026-0142.',
    SelfBillingReferenceFormat.dateSeq =>
      'Hvert job får også din egen reference ud fra datoen. Spiller du to jobs den 5. oktober 2026, bliver det 051026-1 og 051026-2.',
  };
}
