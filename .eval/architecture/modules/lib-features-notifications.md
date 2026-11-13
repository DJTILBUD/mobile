# Module: lib/features/notifications

Manages in-app user notifications for musicians, including fetching notification feeds, synchronizing unread badges with real-time updates and push events, displaying the notification center, and automatically clearing stale bid invitations when jobs are no longer open.

## Key files
- `lib/features/notifications/data/notifications_datasource.dart`: Direct Supabase data source for fetching UserNotifications, updating read timestamps, handling push read state, and batch-marking stale bid notifications read.
- `lib/features/notifications/domain/entities/app_notification.dart`: Domain entity model representing a single in-app notification entry and its push payload data.
- `lib/features/notifications/domain/stale_bid_notifications.dart`: Domain logic and predicates for identifying expired or unbiddable job invitations (internal Jobs and ExtJobs) that should be auto-marked read.
- `lib/features/notifications/presentation/providers/notifications_provider.dart`: Riverpod StateNotifier maintaining the live notifications feed via Supabase Realtime subscriptions, app lifecycle observers, and OS app-icon badge updates.
- `lib/features/notifications/presentation/screens/notifications_screen.dart`: UI screen displaying the in-app notification center with filter tabs (All/Unread), pull-to-refresh, and bulk mark-all-read actions.
- `lib/features/notifications/presentation/widgets/notification_bell.dart`: App bar icon button widget displaying an unread notification count badge and routing to the notification center.

## Public interface
- NotificationsDatasource
- AppNotification
- kBidInvitationNotificationTypes
- kJobStatusesOpenToQuotes
- JobBidState
- isBidInvitationStale
- notificationsDatasourceProvider
- NotificationsNotifier
- notificationsProvider
- unreadNotificationCountProvider
- NotificationsScreen
- NotificationBell

## Dependencies
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:supabase_flutter/supabase_flutter.dart
- package:intl/intl.dart
- package:lucide_icons/lucide_icons.dart
- package:go_router/go_router.dart
- package:dj_tilbud_app/core/notifications/app_badge.dart
- package:dj_tilbud_app/core/notifications/notifications_service.dart
- package:dj_tilbud_app/core/supabase/supabase_client.dart
- package:dj_tilbud_app/core/supabase/supabase_provider.dart
- package:dj_tilbud_app/core/design_system/components.dart
- package:dj_tilbud_app/core/router/app_routes.dart
- package:dj_tilbud_app/core/analytics/analytics_service.dart
- package:dj_tilbud_app/features/jobs/domain/musician_job_availability.dart

## Open questions
- _none_
