# Module: lib/features/calendar

Shows musicians (DJs and other musician roles) a calendar view combining new/sent/won jobs and their own manually-marked unavailable dates, so they can see upcoming bookings alongside the job feed and manage when they're free to quote. Won events are pulled from Quotes (DJ) or ServiceOffers (other musicians) joined with Jobs/ExtJobs, with money figures built via the same budget-label logic used in the job feed so a won job's price matches what was shown when it was quoted on. Also supports exporting the calendar as .ics (one-time or subscription link).

## Key files
- `lib/features/calendar/data/datasources/calendar_remote_datasource.dart`: Supabase queries for won Quotes/ServiceOffers joined with Jobs/ExtJobs, and CRUD for per-user UnavailableDates (dj/musician).
- `lib/features/calendar/data/models/calendar_event_model.dart`: Maps raw Quote/ExtJob/ServiceOffer rows into CalendarEventModel, computing the correct budget/payout label per role via budget_utils so money figures match the job list.
- `lib/features/calendar/data/repositories/calendar_repository_impl.dart`: Implements CalendarRepository, combining quote/ext-job/offer datasource calls into sorted event lists and translating Postgrest errors to DatabaseException.
- `lib/features/calendar/domain/entities/calendar_event.dart`: CalendarEvent entity with CalendarEventKind (newJob/sent/won) and CalendarEventType (internal/external) plus display helpers.
- `lib/features/calendar/domain/repositories/calendar_repository.dart`: Abstract repository contract for fetching DJ/musician events and managing unavailable dates.
- `lib/features/calendar/presentation/providers/calendar_provider.dart`: Riverpod providers/notifiers: loads events per role (watching DJ tier for budget adjustment) and manages optimistic add/toggle of unavailable dates.
- `lib/features/calendar/presentation/providers/calendar_reminder_provider.dart`: Local (SharedPreferences-backed) monthly reminder nudging the musician to mark unavailable dates.
- `lib/features/calendar/presentation/screens/calendar_screen.dart`: Main calendar screen: merges new job-feed jobs, sent quotes/offers, and won events into one filterable monthly view; handles day selection, unavailable-date edit mode, and navigation to job/quote/offer detail.
- `lib/features/calendar/presentation/widgets/calendar_event_card.dart`: Card rendering a single calendar event with kind-based color/tag and time/location/budget info.
- `lib/features/calendar/presentation/widgets/calendar_grid.dart`: Month grid widget showing day cells with event-kind dots and unavailable ('Optaget') marking, supports swipe month navigation.
- `lib/features/calendar/presentation/widgets/calendar_header.dart`: Month/year navigation header with 'today' shortcut and optional export button.
- `lib/features/calendar/presentation/widgets/ical_export_bottom_sheet.dart`: Bottom sheet offering one-time .ics file share or generating a subscription iCal link.
- `lib/features/calendar/presentation/widgets/unavailable_dates_panel.dart`: Shared inline panel toggling an edit mode for marking calendar dates unavailable.

## Public interface
- CalendarRemoteDatasource
- CalendarEventModel
- CalendarRepositoryImpl
- CalendarEvent
- CalendarEventKind
- CalendarEventType
- CalendarRepository
- calendarRepositoryProvider
- CalendarEventsNotifier
- calendarEventsProvider
- DjUnavailableDatesNotifier
- djUnavailableDatesProvider
- MusicianUnavailableDatesNotifier
- musicianUnavailableDatesProvider
- CalendarReminderNotifier
- calendarReminderProvider
- CalendarScreen
- CalendarEventCard
- CalendarGrid
- CalendarHeader
- showIcalExportBottomSheet
- UnavailableDatesPanel

## Dependencies
- supabase_flutter
- flutter_riverpod
- shared_preferences
- go_router
- intl
- lucide_icons
- path_provider
- share_plus
- dj_tilbud_app/core/utils/budget_utils.dart
- dj_tilbud_app/core/utils/ical_generator.dart
- dj_tilbud_app/core/utils/event_type_labels.dart
- dj_tilbud_app/core/error/app_exception.dart
- dj_tilbud_app/core/supabase/supabase_client.dart
- dj_tilbud_app/core/supabase/supabase_provider.dart
- dj_tilbud_app/core/analytics/analytics_service.dart
- dj_tilbud_app/core/design_system/components.dart
- dj_tilbud_app/features/auth/domain/entities/musician_role.dart
- dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart
- dj_tilbud_app/features/jobs/domain/entities/dj_quote.dart
- dj_tilbud_app/features/jobs/domain/entities/ext_job.dart
- dj_tilbud_app/features/jobs/domain/entities/job.dart
- dj_tilbud_app/features/jobs/domain/entities/service_offer.dart
- dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart

## Open questions
- What does generateIcalTokenProvider / icalTokenProvider (used in ical_export_bottom_sheet.dart) do and where is it defined — not shown in provided files.
- The truncated portions of calendar_screen.dart and ical_export_bottom_sheet.dart may contain additional logic (e.g., subscription link display, sharing flow) not fully captured here.
- How CalendarEventKind.newJob/sent events are sourced for musicians (non-DJ) beyond what's shown — jobs_provider.dart referenced but not included in this module's files.
