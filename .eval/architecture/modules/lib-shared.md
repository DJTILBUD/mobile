# Module: lib/shared

Provides reusable UI widgets shared across DJ and musician views for displaying chat buttons/cards, job badges, venue information, delivery setup notices, and event details.

## Key files
- `lib/shared/widgets/chat_bubble_fab.dart`: Floating action button with user/partner avatars and unread badge that opens a job conversation.
- `lib/shared/widgets/conversation_card.dart`: Tappable summary card linking directly to an active job chat thread.
- `lib/shared/widgets/conversation_avatar.dart`: Circular avatar renderer for chat participants with image loading, initials fallback, and support agent icon styling.
- `lib/shared/widgets/copy_hint_row.dart`: Affordance for copying text snippets to clipboard with toast notification.
- `lib/shared/widgets/delivered_setup_notice.dart`: Equipment delivery card explaining standard WKNDS setup gear for quotes and profiles.
- `lib/shared/widgets/job_id_badge.dart`: Badge widget displaying internal and external job identifiers.
- `lib/shared/widgets/locked_info_banner.dart`: Informational banner explaining gated or locked workflow steps to musicians.
- `lib/shared/widgets/partner_event_wishes_card.dart`: Card showing partner portal event details, room assignments, playlists, and saxophonist requirements.
- `lib/shared/widgets/recurring_customer_badge.dart`: Badge indicating an external job is booked by a recurring venue partner.
- `lib/shared/widgets/venue_photos_card.dart`: Card displaying venue preview photos with full-screen viewer support.

## Public interface
- ChatBubbleFab({Key? key, int? jobId, int? extJobId})
- ConversationAvatar({Key? key, required String name, String? imageUrl, bool isSupport, double size})
- ConversationCard({Key? key, int? jobId, int? extJobId, String title, bool showPartnerName, bool compact})
- CopyHintRow({Key? key, required String text, String copiedTitle})
- DeliveredSetupNotice({Key? key, bool forQuote})
- JobIdBadge({Key? key, required int id, bool isExtJob})
- LockedInfoBanner({Key? key, required String label, IconData icon})
- PartnerEventWishesCard({Key? key, String? room, String? addressAs, String? guestAge, String? firstDanceSong, String? spotifyPlaylistUrl, String? specialConditions, bool earlySetup, bool? wantsIc, String? saxType, String? musicianStartTime, double? requestedMusicianHours, String? musicianSpecialRequest, bool musicianView})
- RecurringCustomerBadge({Key? key, required String name, bool compact})
- VenuePhotosCard({Key? key, required List<VenuePhoto> photos})
- VenuePhotoViewerScreen.open(BuildContext context, {required List<VenuePhoto> photos, int initialIndex})

## Dependencies
- package:flutter/material.dart
- package:flutter/services.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:go_router/go_router.dart
- package:lucide_icons/lucide_icons.dart
- package:cached_network_image/cached_network_image.dart
- package:dj_tilbud_app/core/design_system/components.dart
- package:dj_tilbud_app/core/router/app_routes.dart
- package:dj_tilbud_app/core/supabase/supabase_client.dart
- package:dj_tilbud_app/core/utils/wknds_delivery.dart
- package:dj_tilbud_app/features/chat/domain/entities/conversation.dart
- package:dj_tilbud_app/features/chat/presentation/providers/chat_provider.dart
- package:dj_tilbud_app/features/jobs/domain/entities/venue_photo.dart
- package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart

## Open questions
- _none_
