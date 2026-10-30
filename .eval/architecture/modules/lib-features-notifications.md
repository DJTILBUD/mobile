# Module: lib/features/notifications

In-app notification center for the marketplace app: stores a per-user feed of pushes (new job invitations, round updates, chat, wins) sent by server-side notify-* functions, lets a musician read/clear them, keeps an unread badge live, and auto-expires 'new job' bid-invitation notifications once the underlying job is no longer open to quotes/offers — so a musician isn't left marking dead invitations read by hand.

## Key files
- `lib/features/notifications/data/notifications_datasource.dart`: Supabase data access for the UserNotifications table: fetch feed, mark single/all read, mark read-on-push-tap by matching (type, reference_id), and best-effort auto-mark-read of stale bid invitations by checking Jobs/ExtJobs/ServiceOffers state
- `lib/features/notifications/domain/entities/app_notification.dart`: AppNotification entity mirroring a UserNotifications row, including the raw FCM data payload used to replay navigation on tap
- `lib/features/notifications/domain/stale_bid_notifications.dart`: Pure domain logic defining which notification types are bid invitations, which job/ext-job statuses are still open to quotes/offers, and the isBidInvitationStale rule (fails closed) used to decide what can be auto-cleared
- `lib/features/notifications/presentation/providers/notifications_provider.dart`: Riverpod StateNotifier holding the feed, subscribing to Realtime changes on UserNotifications, debouncing refetches, reacting to app resume and to push-tap read events, and driving the unread count/app-icon badge
- `lib/features/notifications/presentation/screens/notifications_screen.dart`: Notification center screen: lists unread/read sections, filter chips (Alle/Ulæste), mark-all-read action, tap-to-navigate
- `lib/features/notifications/presentation/widgets/notification_bell.dart`: App-bar bell icon showing unread count badge and opening the notification center

## Public interface
- NotificationsDatasource
- AppNotification
- JobBidState
- isBidInvitationStale
- kBidInvitationNotificationTypes
- kJobStatusesOpenToQuotes
- NotificationsNotifier
- notificationsProvider
- notificationsDatasourceProvider
- unreadNotificationCountProvider
- NotificationsScreen
- NotificationBell

## Dependencies
- supabase_flutter
- flutter_riverpod
- dj_tilbud_app/core/notifications/app_badge
- dj_tilbud_app/core/notifications/notifications_service
- dj_tilbud_app/core/supabase/supabase_client
- dj_tilbud_app/core/supabase/supabase_provider
- dj_tilbud_app/features/jobs/domain/musician_job_availability
- dj_tilbud_app/core/design_system/components
- dj_tilbud_app/core/router/app_routes
- dj_tilbud_app/app.dart
- dj_tilbud_app/core/analytics/analytics_service
- go_router
- lucide_icons
- intl

## Open questions
- What happens to unread badge/state if a new notification type is added to kBidInvitationNotificationTypes without the sender's FCM payload switch (referenced in notifications_datasource.dart) being updated in lockstep?
- Is there any UI surfacing of JobBidState.hasWonOffer vs assignedMusicianId distinctions beyond the stale-check logic, e.g. for saxophonist-specific messaging?
- Does the truncated _NotificationTile in notifications_screen.dart handle all notification types/icons, or only a subset?
