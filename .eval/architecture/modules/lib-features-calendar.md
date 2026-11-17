# Module: lib/features/calendar

Provides the musician-facing calendar feature to view scheduled bookings (won quotes, assigned external jobs, and won service offers), filter activities, export calendar feeds via iCal/.ics, and manage unavailable dates.

## Key files
- `lib/features/calendar/presentation/screens/calendar_screen.dart`: Main screen displaying the month/day calendar views, unavailable date toggles, event filters, and navigation to quote/offer details.
- `lib/features/calendar/presentation/providers/calendar_provider.dart`: Riverpod state management for fetching DJ/musician calendar events and managing optimistic updates for unavailable dates.
- `lib/features/calendar/presentation/providers/calendar_reminder_provider.dart`: Local state notifier that checks and records monthly reminders to set unavailable dates using SharedPreferences.
- `lib/features/calendar/domain/entities/calendar_event.dart`: Domain models representing calendar events, event types (internal/external), and kinds (newJob, sent, won).
- `lib/features/calendar/data/repositories/calendar_repository_impl.dart`: Repository implementation combining queries from Supabase into sorted CalendarEvent domain objects and managing date exclusions.
- `lib/features/calendar/data/datasources/calendar_remote_datasource.dart`: Remote data source executing Supabase PostgREST queries on Quotes, Jobs, ExtJobs, ServiceOffers, and UnavailableDates.
- `lib/features/calendar/data/models/calendar_event_model.dart`: Data model and parser mapping database records to entities and formatting tier/role-specific budget labels.
- `lib/features/calendar/presentation/widgets/ical_export_bottom_sheet.dart`: Bottom sheet allowing musicians to export events as an .ics file or copy an automatic calendar subscription sync URL.

## Public interface
- calendarRepositoryProvider
- calendarEventsProvider
- djUnavailableDatesProvider
- musicianUnavailableDatesProvider
- calendarReminderProvider
- showIcalExportBottomSheet(BuildContext context, {required List<CalendarEvent> events, required bool isDj})
- CalendarScreen
- CalendarGrid
- CalendarHeader
- CalendarEventCard
- UnavailableDatesPanel

## Dependencies
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:go_router/go_router.dart
- package:intl/intl.dart
- package:lucide_icons/lucide_icons.dart
- package:path_provider/path_provider.dart
- package:share_plus/share_plus.dart
- package:shared_preferences/shared_preferences.dart
- package:supabase_flutter/supabase_flutter.dart
- package:dj_tilbud_app/core/analytics/analytics_service.dart
- package:dj_tilbud_app/core/design_system/components.dart
- package:dj_tilbud_app/core/error/app_exception.dart
- package:dj_tilbud_app/core/router/app_routes.dart
- package:dj_tilbud_app/core/supabase/supabase_client.dart
- package:dj_tilbud_app/core/supabase/supabase_provider.dart
- package:dj_tilbud_app/core/utils/budget_utils.dart
- package:dj_tilbud_app/core/utils/event_type_labels.dart
- package:dj_tilbud_app/core/utils/ical_generator.dart
- package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart
- package:dj_tilbud_app/features/jobs/domain/entities/dj_quote.dart
- package:dj_tilbud_app/features/jobs/domain/entities/ext_job.dart
- package:dj_tilbud_app/features/jobs/domain/entities/job.dart
- package:dj_tilbud_app/features/jobs/domain/entities/service_offer.dart
- package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart
- package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart

## Open questions
- _none_
