# Module: lib/features/featured_jobs

Provides the UI screens for browsing and managing featured/assigned external jobs (Udvalgte jobs), allowing musicians to track upcoming and played jobs, log customer contact, plan contact dates, and mark assignments ready for billing.

## Key files
- `lib/features/featured_jobs/presentation/screens/featured_jobs_screen.dart`: Presents tabbed list views of upcoming ('Kommende') and played ('Spillet') assigned external jobs filtered by active status.
- `lib/features/featured_jobs/presentation/screens/ext_job_detail_screen.dart`: Displays complete details for an external job, including customer contact management, billing readiness triggers, and job metadata.

## Public interface
- FeaturedJobsScreen
- ExtJobDetailScreen

## Dependencies
- package:flutter/material.dart
- package:flutter/services.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:go_router/go_router.dart
- package:intl/intl.dart
- package:lucide_icons/lucide_icons.dart
- dj_tilbud_app/core/design_system/components.dart
- dj_tilbud_app/core/error/app_exception.dart
- dj_tilbud_app/core/error/error_messages.dart
- dj_tilbud_app/core/router/app_routes.dart
- dj_tilbud_app/core/widgets/animated_card.dart
- dj_tilbud_app/core/widgets/skeleton_loading.dart
- dj_tilbud_app/core/utils/event_type_labels.dart
- dj_tilbud_app/core/utils/planned_contact.dart
- dj_tilbud_app/core/analytics/analytics_service.dart
- dj_tilbud_app/features/jobs/domain/entities/ext_job.dart
- dj_tilbud_app/features/jobs/domain/entities/service_offer.dart
- dj_tilbud_app/features/jobs/domain/entities/venue_photo.dart
- dj_tilbud_app/features/jobs/domain/entities/job_action.dart
- dj_tilbud_app/features/jobs/domain/ready_for_billing_gate.dart
- dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart
- dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart
- dj_tilbud_app/features/jobs/presentation/utils/extra_hours_options.dart
- dj_tilbud_app/features/jobs/presentation/widgets/hours_picker_field.dart
- dj_tilbud_app/features/jobs/presentation/widgets/invoice_status_badge.dart
- dj_tilbud_app/features/jobs/presentation/widgets/process_tracker.dart
- dj_tilbud_app/features/jobs/presentation/widgets/customer_deadline_banner.dart
- dj_tilbud_app/features/jobs/presentation/widgets/job_content_section.dart
- dj_tilbud_app/features/jobs/presentation/widgets/sick_disclaimer.dart
- dj_tilbud_app/features/jobs/presentation/widgets/contact_customer_sheet.dart
- dj_tilbud_app/features/jobs/presentation/widgets/event_address_section.dart
- dj_tilbud_app/features/jobs/presentation/widgets/decline_extra_hours.dart
- dj_tilbud_app/features/jobs/presentation/widgets/empty_jobs_view.dart
- dj_tilbud_app/features/jobs/presentation/screens/song_requests_screen.dart
- dj_tilbud_app/shared/widgets/conversation_card.dart
- dj_tilbud_app/shared/widgets/copy_hint_row.dart
- dj_tilbud_app/shared/widgets/chat_bubble_fab.dart
- dj_tilbud_app/shared/widgets/locked_info_banner.dart
- dj_tilbud_app/shared/widgets/job_id_badge.dart
- dj_tilbud_app/shared/widgets/recurring_customer_badge.dart
- dj_tilbud_app/shared/widgets/partner_event_wishes_card.dart
- dj_tilbud_app/shared/widgets/venue_photos_card.dart

## Open questions
- _none_
