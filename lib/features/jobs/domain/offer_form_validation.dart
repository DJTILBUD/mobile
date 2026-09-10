/// Value-level validation for the two bid forms, independent of the widget tree.
///
/// ⚠️ WHY THIS EXISTS — `Form.validate()` alone is NOT trustworthy on these
/// screens. Both bid forms lay their body out as a **lazy `ListView`**, so a
/// field scrolled out of the viewport has its element deactivated;
/// `FormFieldState.deactivate()` then UNREGISTERS it from the enclosing `Form`.
/// `validate()` only walks the fields currently registered, so it silently
/// SKIPS the unmounted ones and returns `true`.
///
/// On the DJ quote form the price input sits far above the submit button (the
/// payout box, the equipment picker and an 8-line salgstale field are in
/// between, well past the default 250px `cacheExtent`), so by the time the DJ
/// taps "Afgiv bud" the price field is normally unmounted. A DJ who never typed
/// a price therefore passed validation with `_price` falling back to 0, and the
/// customer received a 0 kr. bid. (The web route and the `chk_quotes_price_positive`
/// CHECK constraint now reject that server-side, so today it surfaces as an
/// unexplained submit failure instead — still the same missing gate.)
///
/// Validating the VALUES here cannot be skipped, because it reads the
/// controllers, not the tree. Call it in the submit handler and keep
/// `Form.validate()` as well, so whatever IS mounted still paints its inline
/// error.
library;

/// Minimum sales-pitch length. Mirrors the `validator` on both salgstale
/// fields and the web app's own minimum.
const int kSalesPitchMinLength = 100;

/// The first problem with a DJ quote, as a Danish user-facing message, or null
/// when the input is submittable.
///
/// [price] is the parsed price in DKK (0 when the field is empty/unparseable),
/// [salesPitch] the raw pitch text, [equipmentSelected] whether the DJ picked
/// equipment or ticked "intet udstyr".
String? validateDjQuoteInput({
  required int price,
  required String salesPitch,
  required bool equipmentSelected,
}) {
  if (price <= 0) return 'Indtast en gyldig pris';
  if (!equipmentSelected) return 'Vælg mindst ét stykke udstyr';
  if (salesPitch.trim().length < kSalesPitchMinLength) {
    return 'Salgstalen skal være mindst $kSalesPitchMinLength tegn';
  }
  return null;
}

/// The first problem with a musician (saxophonist) offer, or null when it is
/// submittable. The price is derived server-side from the requested hours, so
/// the pitch is the only free-text input here.
String? validateMusicianOfferInput({required String salesPitch}) {
  if (salesPitch.trim().length < kSalesPitchMinLength) {
    return 'Beskeden skal være mindst $kSalesPitchMinLength tegn';
  }
  return null;
}
