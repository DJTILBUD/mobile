/// Customer-name helpers.
///
/// `Jobs.lead_name` / `ExtJobs.lead_name` hold whatever the WordPress customer form was given —
/// usually a full name ("Anna Hansen"), sometimes just a first name, sometimes junk ("-", "ikke
/// oplyst"). DJs and musicians should see only the customer's FIRST name while a job is open/sent
/// (full name + contact details stay reserved for the won view), so every pre-win surface goes
/// through [customerFirstName].
library;

/// Returns the customer's first name, or null when [leadName] holds nothing usable.
///
/// Takes the first whitespace-separated token and drops tokens that are pure punctuation
/// (a lead name of "-" must not render as a customer called "-").
String? customerFirstName(String? leadName) {
  final raw = leadName?.trim();
  if (raw == null || raw.isEmpty) return null;

  for (final token in raw.split(RegExp(r'\s+'))) {
    if (RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(token)) return token;
  }
  return null;
}
