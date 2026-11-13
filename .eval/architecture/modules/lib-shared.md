# Module: lib/shared

Provides reusable cross-feature UI widgets for job details, external jobs, customer wishes, chat triggers, avatars, copy actions, status indicators, and venue photo viewing across the musician mobile app.

## Key files
- `lib/shared/widgets/chat_bubble_fab.dart`: Floating action button with unread count and dual avatars that navigates directly to the chat conversation for a job or external job.
- `lib/shared/widgets/conversation_avatar.dart`: Participant avatar widget handling network images, initials fallback, or a support agent icon.
- `lib/shared/widgets/conversation_card.dart`: Card linking to the active job conversation with support for custom labels, compact mode, and partner names.
- `lib/shared/widgets/copy_hint_row.dart`: Clipboard copy affordance with an inline success toast notification.
- `lib/shared/widgets/job_id_badge.dart`: Visual badge formatting internal (#123) and external (#E123) job IDs.
- `lib/shared/widgets/locked_info_banner.dart`: Explanatory banner indicating gated or locked actions in the musician/DJ workflow.
- `lib/shared/widgets/partner_event_wishes_card.dart`: Event specifications card showing partner booking details, customer wishes, setup timing, and saxophonist requirements.
- `lib/shared/widgets/recurring_customer_badge.dart`: Pill badge highlighting jobs belonging to recurring or partner venue customers.
- `lib/shared/widgets/venue_photos_card.dart`: Horizontal photo carousel and full-screen zoomable photo gallery screen for partner venue location photos.

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
- VenuePhotoViewerScreen.open(context, photos, initialIndex)

## Dependencies
- package:flutter/material.dart
- package:flutter/services.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:go_router/go_router.dart
- package:cached_network_image/cached_network_image.dart
- package:lucide_icons/lucide_icons.dart
- dj_tilbud_app/core/design_system/components.dart
- dj_tilbud_app/core/router/app_routes.dart
- dj_tilbud_app/core/supabase/supabase_client.dart
- dj_tilbud_app/features/chat/domain/entities/conversation.dart
- dj_tilbud_app/features/chat/presentation/providers/chat_provider.dart
- dj_tilbud_app/features/jobs/domain/entities/venue_photo.dart
- dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart

## Open questions
- _none_
