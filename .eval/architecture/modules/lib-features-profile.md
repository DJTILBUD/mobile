# Module: lib/features/profile

(part 1 of 3) Manages performer profile data, settings, job filters, media files, billing and payment information, self-billing verification, reviews, and performer earnings statistics for DJs and saxophonists on the platform. (part 2 of 3) Provides presentation screens and management workflows for musician and DJ profiles, including editing bio and rates, managing media and promotional clips, configuring job filters, managing billing and payment info, tweaking notification settings, reading FAQs, and submitting platform feedback. (part 3 of 3) Manages musician/DJ profile interfaces, including previewing how profiles appear to customers, viewing and modifying reviews and standard templates, accessing stats and trading conditions (handelsbetingelser), managing billing/self-billing requirements, and displaying song request QR codes.

_This module does not fit in one model call, so it was read in 3 parts and their summaries were combined without a further model call._

## Key files
- `lib/features/profile/data/datasources/profile_remote_datasource.dart`: Direct interface for Supabase database queries and Next.js backend API routes handling encrypted payment info, billing unlock requests, self-billing terms, and media operations.
- `lib/features/profile/data/repositories/profile_repository_impl.dart`: Implementation of ProfileRepository coordinating data transformations between models/entities and executing datasource operations.
- `lib/features/profile/domain/repositories/profile_repository.dart`: Abstract repository interface contract for performer profiles, reviews, files, filters, admin messaging, and payment/billing management.
- `lib/features/profile/domain/entities/payment_info.dart`: Domain entity defining performer payment methods (Invoice vs B-income), billing metadata, and self-billing status.
- `lib/features/profile/domain/entities/dj_profile.dart`: Domain entity defining DJ profile attributes such as regions, genres, rates, extra-hour pricing, and public visibility.
- `lib/features/profile/domain/entities/musician_profile.dart`: Domain entity defining saxophonist/musician profile properties including instruments, hourly rates, genres, and collaboration details.
- `lib/features/profile/domain/self_billing_complete.dart`: Business rule engine evaluating whether profile payment and business details satisfy readiness rules for self-billing payouts and bidding gates.
- `lib/features/profile/domain/performer_stats.dart`: Pure aggregation and calculation logic for completed and upcoming booking earnings, payouts, breakdowns, and stats.
- `lib/features/profile/presentation/providers/profile_provider.dart`: Riverpod providers exposing profile state, filters, admin notifications, and mutation notifiers.
- `lib/features/profile/presentation/providers/stats_provider.dart`: Riverpod providers computing DJ and saxophonist stats and earnings from won quotes and assigned external jobs.
- `lib/features/profile/presentation/screens/edit_profile_screen.dart`: Form screen for editing DJ and Musician profile information (name, bio, hourly rate, regions, genres, sax collaboration) with AI bio assistant integration.
- `lib/features/profile/presentation/screens/media_screen.dart`: Media gallery screen handling the upload, validation, reordering, and deletion of profile pictures, setup photos, videos, and DJ mixes.
- `lib/features/profile/presentation/screens/musician_job_filters_screen.dart`: Configuration screen for instrumentalists to filter available job notifications by regions and sax performance types (lounge or party).
- `lib/features/profile/presentation/screens/my_content_screen.dart`: Library and video uploader screen for DJ job content clips, showing moderation status badges and video previews.
- `lib/features/profile/presentation/screens/notification_settings_screen.dart`: Screen for toggling role-specific push notification preferences stored in the DeviceTokens table.
- `lib/features/profile/presentation/screens/payment_screen.dart`: Screen for managing billing details, bank accounts, CPR/CVR, and business entity types with support for billing locks.
- `lib/features/profile/presentation/screens/faq_screen.dart`: Informational screen providing role-specific FAQs regarding gigs, equipment, payment periods, and cancellations.
- `lib/features/profile/presentation/screens/feedback_screen.dart`: Screen allowing musicians to submit feedback about the platform.
- `lib/features/profile/presentation/screens/profile_screen.dart`: Main profile screen displaying musician/DJ overview, quick navigation to sub-features, and entry point for the AI Profile Coach.
- `lib/features/profile/presentation/screens/profile_preview_screen.dart`: Customer preview screen rendering what event organizers see, including media carousels, bio/about text, past venues, and customer reviews.
- `lib/features/profile/presentation/screens/reviews_screen.dart`: Screen for viewing, creating, updating, and deleting customer reviews linked to the musician's profile.
- `lib/features/profile/presentation/screens/standard_messages_screen.dart`: Manages reusable standard message templates grouped by event type.
- `lib/features/profile/presentation/screens/stats_screen.dart`: Displays musician performer statistics, monthly earnings, event type distribution, and regional breakdown filtered by year.
- `lib/features/profile/presentation/screens/terms_screen.dart`: Provides links to external customer and role-specific trading conditions (handelsbetingelser).
- `lib/features/profile/presentation/widgets/billing_lock_card.dart`: Widget displaying lock status on payment information and dialog to request changes from support.
- `lib/features/profile/presentation/widgets/self_billing_reference_format_card.dart`: Configures and saves self-billing supplier reference formats.
- `lib/features/profile/presentation/widgets/self_billing_terms_gate.dart`: Modal gate blocking user actions until mandatory self-billing terms are accepted.
- `lib/features/profile/presentation/widgets/song_request_qr_dialog.dart`: Dialog generating and displaying a reusable QR code linking to song request submission for upcoming gigs.

## Public interface
- ProfileRepository
- ProfileRemoteDatasource
- DjProfile
- MusicianProfile
- PaymentInfo
- DjJobFilters
- MusicianJobFilters
- BillingChangeRequest
- PerformerStats
- computeStats(List<StatEntry> entries, {required DateTime now, int? year})
- isPaymentInfoComplete(PaymentReadinessInfo? info)
- isSelfBillingPayoutReady(PaymentReadinessInfo? info)
- isDac7Complete(PaymentReadinessInfo? info)
- validateBillingEmail(String? value)
- validateSecondaryBillingEmail(String? value, String? primary)
- validateProfileVideo(String filePath, UserFileType type)
- sortUserFiles(List<UserFile> files)
- djProfileProvider
- musicianProfileProvider
- djPaymentInfoProvider
- musicianPaymentInfoProvider
- profileRepositoryProvider
- performerStatsProvider
- EditProfileScreen
- FaqScreen
- FeedbackScreen
- MediaScreen
- MusicianJobFiltersScreen
- MyContentScreen
- NotificationSettingsScreen
- PaymentScreen
- ProfileScreen
- ProfilePreviewScreen
- ReviewsScreen
- StandardMessagesScreen
- StatsScreen
- TermsScreen
- BillingLockCard
- SelfBillingReferenceFormatCard
- SelfBillingTermsGate
- showSongRequestQrDialog

## Dependencies
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:http/http.dart
- package:supabase_flutter/supabase_flutter.dart
- package:video_player/video_player.dart
- package:video_thumbnail/video_thumbnail.dart
- package:intl/intl.dart
- package:lucide_icons/lucide_icons.dart
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
- cached_network_image
- dj_tilbud_app/core/error/error_messages.dart
- dj_tilbud_app/core/notifications/notifications_service.dart
- dj_tilbud_app/features/agent/presentation/providers/agent_provider.dart
- dj_tilbud_app/features/agent/presentation/widgets/profile_bio_bottom_sheet.dart
- dj_tilbud_app/features/chat/presentation/providers/admin_support_provider.dart
- dj_tilbud_app/features/jobs/data/datasources/job_content_remote_datasource.dart
- dj_tilbud_app/features/jobs/presentation/providers/job_content_provider.dart
- dj_tilbud_app/features/jobs/presentation/widgets/content_video_player.dart
- dj_tilbud_app/features/profile/domain/billing_email_validation.dart
- dj_tilbud_app/features/profile/domain/entities/dj_profile.dart
- dj_tilbud_app/features/profile/domain/entities/musician_job_filters.dart
- dj_tilbud_app/features/profile/domain/entities/musician_profile.dart
- dj_tilbud_app/features/profile/domain/entities/payment_info.dart
- dj_tilbud_app/features/profile/domain/entities/user_file.dart
- dj_tilbud_app/features/profile/domain/self_billing_complete.dart
- dj_tilbud_app/features/profile/domain/sort_user_files.dart
- dj_tilbud_app/features/profile/domain/validate_profile_video.dart
- dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart
- dj_tilbud_app/features/profile/presentation/widgets/billing_lock_card.dart
- dj_tilbud_app/features/profile/presentation/widgets/self_billing_reference_format_card.dart
- file_picker
- flutter/material.dart
- flutter_riverpod
- image_picker
- lucide_icons
- supabase_flutter
- url_launcher
- package:go_router/go_router.dart
- package:url_launcher/url_launcher.dart
- package:qr_flutter/qr_flutter.dart
- dj_tilbud_app/core/router/app_routes.dart
- dj_tilbud_app/features/agent/presentation/widgets/profile_coach_bottom_sheet.dart

## AI touchpoints [AI]
- `lib/features/profile/presentation/screens/edit_profile_screen.dart`
- `lib/features/profile/presentation/screens/profile_screen.dart`

## Open questions
- In FeedbackScreen, feedback submission is only acknowledged in local client state; when will the backend feedback submission endpoint be connected?
