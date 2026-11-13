# Module: lib/shared

Provides reusable cross-feature UI widgets for displaying job identifiers, locked state banners, clipboard copy hints, chat affordances, recurring customer indicators, partner event notes, and venue photo carousels/viewers.

## Key files
- `lib/shared/widgets/chat_bubble_fab.dart`: Floating action button pill displaying unread counts, conversation avatars, and deep links to conversation detail
- `lib/shared/widgets/conversation_avatar.dart`: Circular avatar widget rendering user image, initials fallback, or support agent badge
- `lib/shared/widgets/conversation_card.dart`: Tappable chat card linking directly to an active conversation for a specific job or external job
- `lib/shared/widgets/copy_hint_row.dart`: Tappable row component to copy text to clipboard with a toast notification
- `lib/shared/widgets/job_id_badge.dart`: Displays formatted job IDs for standard and external (Udvalgte) jobs
- `lib/shared/widgets/locked_info_banner.dart`: Informational banner explaining gated actions in the musician/DJ workflow
- `lib/shared/widgets/partner_event_wishes_card.dart`: Card showing partner portal booking event details, music requests, setup information, and saxophone preferences
- `lib/shared/widgets/recurring_customer_badge.dart`: Pill badge indicating an external job is from a recurring venue/customer
- `lib/shared/widgets/venue_photos_card.dart`: Horizontal photo carousel and full-screen swipeable photo viewer for venue layout photos and comments

## Public interface
- ChatBubbleFab(jobId, extJobId)
- ConversationAvatar(name, imageUrl, isSupport, size)
- ConversationCard(jobId, extJobId, title, showPartnerName, compact)
- CopyHintRow(text, copiedTitle)
- JobIdBadge(id, isExtJob)
- LockedInfoBanner(label, icon)
- PartnerEventWishesCard(room, addressAs, guestAge, firstDanceSong, spotifyPlaylistUrl, specialConditions, earlySetup, wantsIc, saxType, musicianStartTime, requestedMusicianHours, musicianSpecialRequest, musicianView)
- RecurringCustomerBadge(name, compact)
- VenuePhotosCard(photos)
- VenuePhotoViewerScreen(photos, initialIndex)

## Dependencies
- flutter/material.dart
- flutter/services.dart
- flutter_riverpod
- go_router
- lucide_icons
- cached_network_image
- dj_tilbud_app/core/design_system/components.dart
- dj_tilbud_app/core/router/app_routes.dart
- dj_tilbud_app/core/supabase/supabase_client.dart
- dj_tilbud_app/features/chat/domain/entities/conversation.dart
- dj_tilbud_app/features/chat/presentation/providers/chat_provider.dart
- dj_tilbud_app/features/jobs/domain/entities/venue_photo.dart
- dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart

## Open questions
- _none_
