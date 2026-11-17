# Module: lib/features/notifications

Manages in-app notifications for musicians, including real-time feed updates from Supabase, badge counts, auto-clearing stale bid invitation notifications, and notification UI screens and widgets.

## Key files
- `lib/features/notifications/data/notifications_datasource.dart`: Supabase data source for querying and updating UserNotifications feed rows and inspecting job states to identify stale invitations.
- `lib/features/notifications/domain/entities/app_notification.dart`: Domain entity model representing a notification item in the feed.
- `lib/features/notifications/domain/stale_bid_notifications.dart`: Domain logic determining whether job bid invitations are stale based on job status, offers, and musician roles.
- `lib/features/notifications/presentation/providers/notifications_provider.dart`: Riverpod StateNotifier managing notification state, real-time channel subscriptions, OS badge syncing, and read status.
- `lib/features/notifications/presentation/screens/notifications_screen.dart`: Screen displaying the list of notifications grouped by read status with filtering and batch mark-read capabilities.
- `lib/features/notifications/presentation/widgets/notification_bell.dart`: App bar action icon displaying unread notification count badge and routing to the notification centre.

## Public interface
- NotificationsDatasource.fetch(String userId, {int limit})
- NotificationsDatasource.markRead(int id)
- NotificationsDatasource.markReadForPush({required String userId, required String type, String? referenceId})
- NotificationsDatasource.markStaleBidInvitationsRead(String userId, List<AppNotification> notifications)
- NotificationsDatasource.markAllRead(String userId)
- AppNotification
- JobBidState
- isBidInvitationStale({required String type, required String? role, required JobBidState? state})
- kBidInvitationNotificationTypes
- kJobStatusesOpenToQuotes
- notificationsDatasourceProvider
- notificationsProvider
- NotificationsNotifier
- unreadNotificationCountProvider
- NotificationsScreen
- NotificationBell

## Dependencies
- flutter/material.dart
- flutter/widgets.dart
- flutter_riverpod
- supabase_flutter
- intl
- lucide_icons
- go_router
- dj_tilbud_app/core/notifications/app_badge.dart
- dj_tilbud_app/core/notifications/notifications_service.dart
- dj_tilbud_app/core/supabase/supabase_client.dart
- dj_tilbud_app/core/supabase/supabase_provider.dart
- dj_tilbud_app/core/analytics/analytics_service.dart
- dj_tilbud_app/core/design_system/components.dart
- dj_tilbud_app/core/router/app_routes.dart
- dj_tilbud_app/features/jobs/domain/musician_job_availability.dart
- dj_tilbud_app/app.dart

## Open questions
- _none_
