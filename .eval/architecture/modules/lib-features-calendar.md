# Module: lib/features/calendar

Manages calendar views, event scheduling, and availability management for musicians (DJs and instrumentalists/saxophonists), including tracking won quotes, assigned external jobs, won service offers, manual unavailability dates ('optaget'), and iCal export/sync.

## Key files
- `lib/features/calendar/data/datasources/calendar_remote_datasource.dart`: Interacts with Supabase tables (Quotes, ExtJobs, ServiceOffers, UnavailableDates) to fetch bookings and manage unavailable dates.
- `lib/features/calendar/data/models/calendar_event_model.dart`: Maps database rows for quotes, external jobs, and service offers into calendar events, ensuring tier- and sax-adjusted DJ budget display or musician payout labels.
- `lib/features/calendar/data/repositories/calendar_repository_impl.dart`: Implements CalendarRepository, transforming raw remote datasource entries into domain CalendarEvent entities and handling unavailable date mappings.
- `lib/features/calendar/domain/entities/calendar_event.dart`: Domain entity defining CalendarEvent along with CalendarEventKind and CalendarEventType enums.
- `lib/features/calendar/domain/repositories/calendar_repository.dart`: Abstract contract for fetching DJ/musician events and managing unavailable dates.
- `lib/features/calendar/presentation/providers/calendar_provider.dart`: Riverpod providers and state notifiers for calendar events and unavailable date toggles for DJs and musicians.
- `lib/features/calendar/presentation/providers/calendar_reminder_provider.dart`: Tracks monthly local reminder state prompting users to update their unavailable dates via SharedPreferences.
- `lib/features/calendar/presentation/screens/calendar_screen.dart`: Main calendar UI displaying the monthly grid, event list filtering (new jobs, sent quotes, won jobs), unavailable date toggles, and navigation.
- `lib/features/calendar/presentation/widgets/ical_export_bottom_sheet.dart`: Bottom sheet providing options for one-time .ics file downloads and subscription link generation for calendar synchronization.

## Public interface
- CalendarRepository
- CalendarEvent
- CalendarEventKind
- CalendarEventType
- calendarRepositoryProvider
- calendarEventsProvider
- djUnavailableDatesProvider
- musicianUnavailableDatesProvider
- calendarReminderProvider
- CalendarScreen
- showIcalExportBottomSheet
- CalendarGrid
- CalendarHeader
- CalendarEventCard
- UnavailableDatesPanel

## Dependencies
- package:supabase_flutter/supabase_flutter.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:shared_preferences/shared_preferences.dart
- package:go_router/go_router.dart
- package:share_plus/share_plus.dart
- package:path_provider/path_provider.dart
- package:intl/intl.dart
- package:lucide_icons/lucide_icons.dart
- package:dj_tilbud_app/core/error/app_exception.dart
- package:dj_tilbud_app/core/design_system/components.dart
- package:dj_tilbud_app/core/router/app_routes.dart
- package:dj_tilbud_app/core/utils/budget_utils.dart
- package:dj_tilbud_app/core/utils/event_type_labels.dart
- package:dj_tilbud_app/core/utils/ical_generator.dart
- package:dj_tilbud_app/core/analytics/analytics_service.dart
- package:dj_tilbud_app/core/supabase/supabase_client.dart
- package:dj_tilbud_app/core/supabase/supabase_provider.dart
- package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart
- package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart
- package:dj_tilbud_app/features/jobs/domain/entities/job.dart
- package:dj_tilbud_app/features/jobs/domain/entities/dj_quote.dart
- package:dj_tilbud_app/features/jobs/domain/entities/ext_job.dart
- package:dj_tilbud_app/features/jobs/domain/entities/service_offer.dart
- package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart

## Open questions
- _none_
