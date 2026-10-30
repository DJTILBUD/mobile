# Module: lib/features/featured_jobs

Shows musicians (DJs) their 'Udvalgte jobs' (featured/assigned external jobs) — a list screen separating upcoming vs. played jobs, plus a detail screen for managing a single assigned job (contacting the customer, marking ready for billing, viewing conversation, song requests, venue photos, etc.).

## Key files
- `lib/features/featured_jobs/presentation/screens/featured_jobs_screen.dart`: Tab-based list screen showing assigned ext jobs filtered by status (closed, reopened, customerContacted, readyForBilling) and split into 'Kommende' (upcoming) and 'Spillet' (played) tabs; sorts and renders job cards that navigate to the detail screen.
- `lib/features/featured_jobs/presentation/screens/ext_job_detail_screen.dart`: Detail screen for a single ext job: lets the DJ open a contact sheet to mark/plan customer contact, confirm closing the deal and sending an invoice ('ready for billing'), and surfaces related widgets like conversation, song requests, venue photos, and process tracker.

## Public interface
- ExtJobDetailScreen
- FeaturedJobsScreen

## Dependencies
- lib/features/jobs/domain/entities/ext_job.dart
- lib/features/jobs/domain/entities/service_offer.dart
- lib/features/jobs/domain/entities/job_action.dart
- lib/features/jobs/domain/entities/venue_photo.dart
- lib/features/jobs/domain/ready_for_billing_gate.dart
- lib/features/jobs/presentation/providers/jobs_provider.dart
- lib/features/jobs/presentation/utils/extra_hours_options.dart
- lib/features/jobs/presentation/widgets/hours_picker_field.dart
- lib/features/jobs/presentation/widgets/invoice_status_badge.dart
- lib/features/jobs/presentation/widgets/process_tracker.dart
- lib/features/jobs/presentation/widgets/customer_deadline_banner.dart
- lib/features/jobs/presentation/widgets/job_content_section.dart
- lib/features/jobs/presentation/widgets/sick_disclaimer.dart
- lib/features/jobs/presentation/widgets/contact_customer_sheet.dart
- lib/features/jobs/presentation/widgets/event_address_section.dart
- lib/features/jobs/presentation/screens/song_requests_screen.dart
- lib/features/jobs/presentation/widgets/decline_extra_hours.dart
- lib/features/jobs/presentation/widgets/empty_jobs_view.dart
- lib/features/profile/presentation/providers/profile_provider.dart
- lib/shared/widgets/conversation_card.dart
- lib/shared/widgets/copy_hint_row.dart
- lib/shared/widgets/chat_bubble_fab.dart
- lib/shared/widgets/locked_info_banner.dart
- lib/shared/widgets/job_id_badge.dart
- lib/shared/widgets/recurring_customer_badge.dart
- lib/shared/widgets/partner_event_wishes_card.dart
- lib/shared/widgets/venue_photos_card.dart
- lib/core/design_system/components.dart
- lib/core/error/app_exception.dart
- lib/core/error/error_messages.dart
- lib/core/utils/event_type_labels.dart
- lib/core/utils/planned_contact.dart
- lib/core/analytics/analytics_service.dart
- lib/core/router/app_routes.dart
- lib/core/widgets/animated_card.dart
- lib/core/widgets/skeleton_loading.dart

## Open questions
- What exactly distinguishes an 'ext job' from a regular job in the jobs feature — the truncated file doesn't show the full ExtJob entity definition.
- Is there any AI involvement in generating job content or matching, or is this module purely manual contact/billing workflow management?
- What determines the 'hasAction' flag used for sorting jobs with pending actions first?
