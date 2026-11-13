# Module: lib/features/calendar

Provides calendar management for DJs and musicians, including viewing won quotes, assigned external jobs, job service offers, setting and managing unavailable/busy dates, and exporting calendar events to iCal (.ics) format or synchronised subscription links.

## Key files
- `lib/features/calendar/data/datasources/calendar_remote_datasource.dart`: Supabase client data source querying Quotes, Jobs, ExtJobs, ServiceOffers, and managing UnavailableDates for both DJs and musicians.
- `lib/features/calendar/data/models/calendar_event_model.dart`: Data model mapping Supabase database rows into domain CalendarEvent instances with DJ tier-adjusted and musician payout budget formatting.
- `lib/features/calendar/data/repositories/calendar_repository_impl.dart`: Implements CalendarRepository, orchestrating data calls from CalendarRemoteDatasource and transforming records to CalendarEvent domain models.
- `lib/features/calendar/domain/entities/calendar_event.dart`: Domain entity and enums representing calendar events (internal/external job types, event kinds like newJob/sent/won).
- `lib/features/calendar/domain/repositories/calendar_repository.dart`: Abstract contract interface defining fetching events and managing unavailable dates for DJs and musicians.
- `lib/features/calendar/presentation/providers/calendar_provider.dart`: Riverpod providers and state notifiers managing calendar event lists and optimistic updates for DJ/musician unavailable dates.
- `lib/features/calendar/presentation/providers/calendar_reminder_provider.dart`: Local SharedPreferences state notifier tracking monthly reminders to mark unavailable dates.
- `lib/features/calendar/presentation/screens/calendar_screen.dart`: Main screen widget rendering the calendar month/day view, unavailable date management mode, and navigation to jobs/quotes.
- `lib/features/calendar/presentation/widgets/calendar_event_card.dart`: Card widget displaying an event's details (status, type, time, location, guest count, and payout/budget).
- `lib/features/calendar/presentation/widgets/calendar_grid.dart`: Monthly calendar grid widget displaying days, unavailable tags, selection state, and event indicator dots.
- `lib/features/calendar/presentation/widgets/calendar_header.dart`: Header widget providing month/year navigation controls, year picker modal, jump-to-today, and export triggers.
- `lib/features/calendar/presentation/widgets/ical_export_bottom_sheet.dart`: Modal bottom sheet facilitating one-time .ics file export and generating automatic sync subscription links.
- `lib/features/calendar/presentation/widgets/unavailable_dates_panel.dart`: Reusable toggle banner UI allowing musicians to enter edit mode for toggling unavailable/busy dates.

## Public interface
- calendarRepositoryProvider
- calendarEventsProvider
- djUnavailableDatesProvider
- musicianUnavailableDatesProvider
- calendarReminderProvider
- showIcalExportBottomSheet
- CalendarScreen
- CalendarEventCard
- CalendarGrid
- CalendarHeader
- UnavailableDatesPanel
- CalendarEvent
- CalendarEventKind
- CalendarEventType
- CalendarRepository

## Dependencies
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:supabase_flutter/supabase_flutter.dart
- package:shared_preferences/shared_preferences.dart
- package:intl/intl.dart
- package:lucide_icons/lucide_icons.dart
- package:go_router/go_router.dart
- package:path_provider/path_provider.dart
- package:share_plus/share_plus.dart
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
