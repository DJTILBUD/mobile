/// Whether a planned customer-contact date has arrived: today or any earlier day.
///
/// Compares calendar days only (local time), so a date planned for "today" counts as due
/// from midnight regardless of the stored time-of-day. Used by the "Kundekontakt" card to
/// switch the primary action from "Ændr kontaktdato" (still in the future) to
/// "Kunde kontaktet" (the DJ should be calling now).
bool isPlannedContactDue(DateTime? plannedFor, {DateTime? now}) {
  if (plannedFor == null) return false;
  final today = now ?? DateTime.now();
  final todayDay = DateTime(today.year, today.month, today.day);
  final planned = plannedFor.toLocal();
  final plannedDay = DateTime(planned.year, planned.month, planned.day);
  return !plannedDay.isAfter(todayDay);
}
