# Module: lib/features/profile

(part 1 of 3) Manages DJ and saxophonist profiles, encrypted billing and payment settings, job filter preferences, media uploads and validation, customer reviews, standard template messages, admin communications, and performer earnings statistics. (part 2 of 3) Provides user profile and account management screens for musicians and DJs, enabling them to edit personal profiles, configure billing and payment settings, upload media/mixes, manage job filters, adjust notification preferences, and submit feedback. (part 3 of 3) Manages performer profile viewing, editing, reviews, standard response messages, earnings statistics, billing lock/terms gates, and gig tools like song request QR codes for DJs and musicians.

_This module does not fit in one model call, so it was read in 3 parts and their summaries were combined without a further model call._

## Key files
- `lib/features/profile/data/datasources/profile_remote_datasource.dart`: Interacts with Supabase tables and external web app API endpoints for profile data, sensitive encrypted payment info, billing change requests, and self-billing terms
- `lib/features/profile/data/repositories/profile_repository_impl.dart`: Implements ProfileRepository, handling model conversions and database exception translation across profile domain entities
- `lib/features/profile/domain/repositories/profile_repository.dart`: Abstract repository contract defining CRUD operations for profiles, payment data, reviews, files, filters, admin messages, and standard messages
- `lib/features/profile/domain/self_billing_complete.dart`: Rules determining payment info completeness and payout readiness for Invoice (self-billing) and B-income payment flows
- `lib/features/profile/domain/performer_stats.dart`: Pure aggregation logic calculating monthly and category revenue, upcoming earnings, and event statistics for musicians
- `lib/features/profile/presentation/providers/profile_provider.dart`: Riverpod providers exposing profile states, payment states, job filter notifiers, and admin message actions
- `lib/features/profile/presentation/providers/stats_provider.dart`: Riverpod providers aggregating won quotes, service offers, and ext jobs into performer earnings and statistics
- `lib/features/profile/presentation/screens/dj_job_filters_screen.dart`: UI screen allowing DJs to configure event types, regions, genres, allowed weekdays, budget, guest count, and duration filter criteria
- `lib/features/profile/presentation/screens/admin_messages_screen.dart`: UI screen for viewing and marking admin messages from DJTILBUD as read
- `lib/features/profile/presentation/screens/edit_profile_screen.dart`: Screen for editing DJ and Musician profile information such as bio, genres, regions, rates, and instruments.
- `lib/features/profile/presentation/screens/payment_screen.dart`: Screen for managing billing information, payment types, CPR/CVR numbers, and bank account details.
- `lib/features/profile/presentation/screens/media_screen.dart`: Screen for uploading and reordering profile pictures, promotional videos, and DJ mixes.
- `lib/features/profile/presentation/screens/musician_job_filters_screen.dart`: Screen for configuring job filtering preferences by region and saxophone gig type.
- `lib/features/profile/presentation/screens/my_content_screen.dart`: Screen for browsing and uploading job-related event video clips and reviewing their approval status.
- `lib/features/profile/presentation/screens/notification_settings_screen.dart`: Screen for toggling device push notification categories.
- `lib/features/profile/presentation/screens/feedback_screen.dart`: Screen allowing musicians to submit feedback about the platform.
- `lib/features/profile/presentation/screens/faq_screen.dart`: FAQ screen providing role-specific guidelines on gigs, payments, bidding, and post-win procedures.
- `lib/features/profile/presentation/screens/profile_screen.dart`: Main performer profile overview screen with entry points to editing, settings, themes, stats, and the AI Profile Coach.
- `lib/features/profile/presentation/screens/profile_preview_screen.dart`: Public preview screen simulating how the performer's profile and media appear to prospective customers.
- `lib/features/profile/presentation/screens/reviews_screen.dart`: Screen for listing, creating, editing, and deleting customer reviews.
- `lib/features/profile/presentation/screens/standard_messages_screen.dart`: Screen for managing reusable canned message templates grouped by event type.
- `lib/features/profile/presentation/screens/stats_screen.dart`: Performer performance and earnings statistics dashboard filtered by year and event type.
- `lib/features/profile/presentation/screens/terms_screen.dart`: Displays terms of service and trade condition links for customers and performers.
- `lib/features/profile/presentation/widgets/billing_lock_card.dart`: Widget managing billing detail lock state and submission of support change requests.
- `lib/features/profile/presentation/widgets/self_billing_reference_format_card.dart`: Form card for configuring self-billing invoice reference numbering schemes.
- `lib/features/profile/presentation/widgets/self_billing_terms_gate.dart`: Modal gate blocking invoicing access until mandatory self-billing terms are accepted.
- `lib/features/profile/presentation/widgets/song_request_qr_dialog.dart`: Modal displaying a reusable QR code linking event guests to the DJ's song-request endpoint.

## Public interface
- ProfileRepository
- profileRepositoryProvider
- djProfileProvider
- musicianProfileProvider
- djPaymentInfoProvider
- musicianPaymentInfoProvider
- billingChangeRequestProvider
- selfBillingLiveProvider
- needsSelfBillingTermsProvider
- djReviewsProvider
- musicianReviewsProvider
- userFilesProvider
- djJobFiltersProvider
- saveDjJobFiltersProvider
- musicianJobFiltersProvider
- saveMusicianJobFiltersProvider
- standardMessagesProvider
- adminMessagesProvider
- unreadAdminMessageCountProvider
- markAdminMessageReadProvider
- hasSessionProvider
- statsYearProvider
- statEntriesProvider
- performerStatsProvider
- statsYearsProvider
- AdminMessagesScreen
- DjJobFiltersScreen
- validateBillingEmail(String? value)
- validateSecondaryBillingEmail(String? value, String? primary)
- validateProfileVideo(String filePath, UserFileType type)
- isPaymentInfoComplete(PaymentReadinessInfo? info)
- isSelfBillingComplete(SelfBillingInfo? info)
- isSelfBillingPayoutReady(PaymentReadinessInfo? info)
- isDac7Complete(PaymentReadinessInfo? info)
- computeStats(List<StatEntry> entries, {required DateTime now, int? year})
- sortUserFiles(List<UserFile> files)
- EditProfileScreen
- FeedbackScreen
- MediaScreen
- MusicianJobFiltersScreen
- MyContentScreen
- NotificationSettingsScreen
- PaymentScreen
- ProfileScreen(role: MusicianRole)
- ProfilePreviewScreen(role: MusicianRole)
- ReviewsScreen(role: MusicianRole)
- StandardMessagesScreen()
- StatsScreen(role: MusicianRole)
- TermsScreen(role: MusicianRole)
- BillingLockCard(lockedAt: DateTime?)
- SelfBillingReferenceFormatCard(isDj: bool, savedFormat: SelfBillingReferenceFormat)
- SelfBillingTermsGate(isDj: bool, child: Widget)
- showSongRequestQrDialog(BuildContext context, String token)

## Dependencies
- http
- supabase_flutter
- video_player
- video_thumbnail
- flutter_riverpod
- intl
- lucide_icons
- dj_tilbud_app/core/config/env_config.dart
- dj_tilbud_app/core/error/app_exception.dart
- dj_tilbud_app/core/design_system/components.dart
- dj_tilbud_app/core/supabase/supabase_client.dart
- dj_tilbud_app/core/supabase/supabase_provider.dart
- dj_tilbud_app/core/utils/event_type_labels.dart
- dj_tilbud_app/core/utils/unsaved_changes_dialog.dart
- dj_tilbud_app/features/auth/domain/entities/musician_role.dart
- dj_tilbud_app/features/auth/presentation/providers/auth_provider.dart
- dj_tilbud_app/features/jobs/domain/entities/ext_job.dart
- dj_tilbud_app/features/jobs/domain/entities/job.dart
- dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart
- flutter
- cached_network_image
- file_picker
- image_picker
- url_launcher
- dj_tilbud_app/core
- dj_tilbud_app/features/agent
- dj_tilbud_app/features/auth
- dj_tilbud_app/features/chat
- dj_tilbud_app/features/jobs
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:go_router/go_router.dart
- package:intl/intl.dart
- package:lucide_icons/lucide_icons.dart
- package:qr_flutter/qr_flutter.dart
- package:url_launcher/url_launcher.dart
- package:chewie/chewie.dart
- package:video_player/video_player.dart
- package:cached_network_image/cached_network_image.dart
- dj_tilbud_app/core/error/error_messages.dart
- dj_tilbud_app/core/router/app_routes.dart
- dj_tilbud_app/core/theme/theme_provider.dart
- dj_tilbud_app/features/agent/presentation/providers/agent_provider.dart
- dj_tilbud_app/features/agent/presentation/widgets/profile_coach_bottom_sheet.dart

## AI touchpoints [AI]
- `lib/features/profile/presentation/screens/edit_profile_screen.dart`
- `lib/features/profile/presentation/screens/profile_screen.dart`

## Open questions
- _none_
