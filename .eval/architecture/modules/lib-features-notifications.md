# Module: lib/features/notifications

Manages fetching, real-time synchronization, auto-expiration, read-state tracking, and display of user in-app notifications and notification center UI for musicians.

## Key files
- `lib/features/notifications/data/notifications_datasource.dart`: Supabase datasource handling direct queries and updates to the UserNotifications, Jobs, ExtJobs, and ServiceOffers tables.
- `lib/features/notifications/domain/entities/app_notification.dart`: Entity model defining in-app notification data structure and JSON serialization.
- `lib/features/notifications/domain/stale_bid_notifications.dart`: Domain logic and rules to evaluate whether job bidding invitation notifications have expired or become stale.
- `lib/features/notifications/presentation/providers/notifications_provider.dart`: Riverpod StateNotifier and providers managing real-time feed updates, unread badge sync, and lifecycle-aware fetching.
- `lib/features/notifications/presentation/screens/notifications_screen.dart`: Notification centre screen UI displaying filterable list of read and unread notifications.
- `lib/features/notifications/presentation/widgets/notification_bell.dart`: App bar action icon displaying real-time unread count badge and navigation to the notification centre.

## Public interface
- NotificationsDatasource.fetch
- NotificationsDatasource.markRead
- NotificationsDatasource.markReadForPush
- NotificationsDatasource.markStaleBidInvitationsRead
- NotificationsDatasource.markAllRead
- isBidInvitationStale
- kBidInvitationNotificationTypes
- kJobStatusesOpenToQuotes
- notificationsDatasourceProvider
- notificationsProvider
- unreadNotificationCountProvider
- NotificationsNotifier.refresh
- NotificationsNotifier.markRead
- NotificationsNotifier.markAllRead
- NotificationsScreen
- NotificationBell

## Dependencies
- package:supabase_flutter/supabase_flutter.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:go_router/go_router.dart
- package:lucide_icons/lucide_icons.dart
- package:intl/intl.dart
- lib/features/jobs/domain/musician_job_availability.dart
- lib/core/notifications/app_badge.dart
- lib/core/notifications/notifications_service.dart
- lib/core/supabase/supabase_client.dart
- lib/core/supabase/supabase_provider.dart
- lib/core/design_system/components.dart
- lib/core/analytics/analytics_service.dart
- lib/core/router/app_routes.dart
- lib/app.dart

## Open questions
- _none_
