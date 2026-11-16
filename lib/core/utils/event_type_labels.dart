/// Returns a human-readable Danish label for an event type key.
/// Mirrored in web-app/src/helpers/reviewEventType.ts and admin/lib/services/trustpilot/eventTypes.ts
/// (review labels + the admin's Trustpilot categories). Change all three together.
/// The DB stores Danish keys (e.g. 'bryllup', 'firmafest').
String eventTypeLabel(String type) {
  return switch (type) {
    'bryllup' => 'Bryllup',
    'firmafest' => 'Firmafest',
    'fødselsdagsfest' => 'Fødselsdagsfest',
    'fødselsdag' => 'Fødselsdag',
    'julefrokost' => 'Julefrokost',
    'privatfest' => 'Privatfest',
    'ungdomsfest' => 'Ungdomsfest',
    'klub/bar' => 'Klub/bar',
    'lounge' => 'Lounge',
    'konfirmation' => 'Konfirmation',
    'studenterfest' => 'Studenterfest',
    'sommerfest' => 'Sommerfest',
    'andet' => 'Andet',
    _ => type,
  };
}
