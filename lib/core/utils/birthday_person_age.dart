/// Dart mirror of the web app's `useFormatBirthdayPersonAge`
/// (`web-app/src/hooks/useFormatBirthdayPersonAge.ts`) — **change both together.**
///
/// `Jobs.birthday_person_age` / `ExtJobs.birthday_person_age` are free `text`
/// filled from the WordPress customer forms, so the value is usually a plain
/// number ("50") but can be anything the customer typed ("halvtreds", "50-års").
/// A digits-only value gets the " år" suffix; anything else is printed verbatim
/// so we never render "halvtreds år".
///
/// Returns a suffix meant to be appended to the event-type label, exactly like
/// web appends it to the job heading ("Fødselsdagsfest, 50 år"). Empty string
/// when there is nothing to show, so call sites can concatenate unconditionally.
String formatBirthdayPersonAge(String? birthdayPersonAge) {
  if (birthdayPersonAge == null) return '';
  final trimmed = birthdayPersonAge.trim();
  if (trimmed.isEmpty) return '';
  final isDigitsOnly = RegExp(r'^\d+$').hasMatch(trimmed);
  return isDigitsOnly ? ', $trimmed år' : ', $birthdayPersonAge';
}
