# Module: lib/shared

Shared, reusable UI widgets used across the app's job/chat screens: chat entry points (floating chat bubble, conversation card), avatars, job id badges, locked/gated action banners, and partner-venue details (event wishes, venue photos, recurring-customer badge) shown on job/offer detail screens.

## Key files
- `lib/shared/widgets/chat_bubble_fab.dart`: Floating 'Beskeder' chat button shown on job/offer screens that opens the matching conversation for a given internal or ext job, with an unread-count badge and partner/current-user avatar stack.
- `lib/shared/widgets/conversation_avatar.dart`: Shared circular avatar for a chat participant (image -> initials -> fallback icon), with a support/agent variant.
- `lib/shared/widgets/conversation_card.dart`: Tappable card summarizing an existing conversation for a job/ext job, linking into the conversation detail screen.
- `lib/shared/widgets/copy_hint_row.dart`: Small 'Kopier' tap-to-copy affordance with a success toast, used under customer-request/notes text blocks.
- `lib/shared/widgets/job_id_badge.dart`: Renders the job ID badge shown on job cards/detail screens (#id for internal jobs, #Eid for external jobs).
- `lib/shared/widgets/locked_info_banner.dart`: Muted banner explaining why an action is currently disabled (e.g. waiting for a ready window or for the winning musician to make contact), paired with a disabled button.
- `lib/shared/widgets/partner_event_wishes_card.dart`: 'Til festen' card showing couple/event details collected for a partner-portal booking (room, how the couple is addressed, guest age, first dance, playlist, special conditions, saxophonist subsection), with a reduced musician-facing view.
- `lib/shared/widgets/recurring_customer_badge.dart`: Pill badge marking an ext job as belonging to a recurring (venue) customer, showing the resolved customer name.
- `lib/shared/widgets/venue_photos_card.dart`: Shows team-taken photos of a partner venue with captions, and a full-screen swipeable photo viewer, so a musician can see the room before arriving.

## Public interface
- ChatBubbleFab
- ConversationAvatar
- ConversationCard
- CopyHintRow
- JobIdBadge
- LockedInfoBanner
- PartnerEventWishesCard
- RecurringCustomerBadge
- VenuePhotosCard
- VenuePhotoViewerScreen

## Dependencies
- lib/core/design_system/components.dart
- lib/core/router/app_routes.dart
- lib/core/supabase/supabase_client.dart
- lib/features/chat/presentation/providers/chat_provider.dart
- lib/features/chat/domain/entities/conversation.dart
- lib/features/jobs/presentation/providers/jobs_provider.dart
- lib/features/jobs/domain/entities/venue_photo.dart

## Open questions
- The truncated remainder of partner_event_wishes_card.dart and venue_photos_card.dart was not shown in full, so any additional fields or behavior past the cutoff are unverified.
- No AI/LLM or agent logic appears in this shared-widgets module itself; such logic (e.g. the profile/sales-pitch agent) likely lives elsewhere and is not evidenced by these files.
