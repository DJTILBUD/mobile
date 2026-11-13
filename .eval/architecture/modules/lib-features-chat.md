# Module: lib/features/chat

(part 1 of 2) Manages in-app communication for musicians and administrators, including musician job coordination conversations and support threads with the DJTILBUD team, featuring real-time messaging, emoji reactions, image attachments, typing indicators, and inline job reference linking. (part 2 of 2) Provides the chat and messaging interface for musicians and administrators, including conversation lists, real-time message exchange with media attachments and job references, and admin support messaging threads.

_This module does not fit in one model call, so it was read in 2 parts and their summaries were combined without a further model call._

## Key files
- `lib/features/chat/data/datasources/chat_remote_datasource.dart`: Interacts with Supabase and backend web API to fetch conversations, messages, reactions, upload chat images, and manage support conversation initialization.
- `lib/features/chat/data/datasources/admin_support_datasource.dart`: Communicates with authenticated backend admin web API endpoints to manage admin support threads, search queries, recipient selection, and thread handling state.
- `lib/features/chat/data/datasources/job_link_remote_datasource.dart`: Resolves inline job mention references (@job/extjob) and searches linkable jobs via backend endpoints.
- `lib/features/chat/data/repositories/chat_repository_impl.dart`: Implements ChatRepository by delegating chat operations and transformations between models and domain entities.
- `lib/features/chat/domain/repositories/chat_repository.dart`: Defines the abstract interface for fetching and sending messages, editing, marking as read, uploading attachments, and managing reactions.
- `lib/features/chat/presentation/providers/chat_provider.dart`: Provides Riverpod state notifiers for real-time conversation lists and conversation message streams using Supabase Realtime channels.
- `lib/features/chat/presentation/providers/admin_support_provider.dart`: Manages admin support thread listings, unread badges, handling toggles, and live updates for administrators.
- `lib/features/chat/presentation/providers/reactions_provider.dart`: Handles real-time emoji reactions mapped by message ID for individual conversations.
- `lib/features/chat/presentation/providers/typing_provider.dart`: Manages broadcast-based typing indicators over Supabase Realtime for the DJTILBUD support conversation.
- `lib/features/chat/presentation/screens/admin_support_thread_screen.dart`: Provides the UI screen for admins to view, search, reply to, edit, and react in customer support threads.
- `lib/features/chat/presentation/screens/chat_screen.dart`: Main chat inbox screen displaying musician conversations and, for admin users, an admin support tab with search capabilities.
- `lib/features/chat/presentation/screens/conversation_detail_screen.dart`: Conversation detail view supporting real-time chat, message search, replies, message editing, image attachments, quick emoji reactions, and job token mentions.
- `lib/features/chat/presentation/widgets/chat_message_input.dart`: Reusable composer input bar widget featuring text input, image attachment triggering, and message submission.
- `lib/features/chat/presentation/widgets/new_support_message_sheet.dart`: Modal bottom sheet allowing administrators to search for musicians, compose messages with job link mentions, and initiate new support threads.

## Public interface
- chatRepositoryProvider
- conversationsProvider
- conversationReactionsProvider
- supportTypingProvider
- adminSupportThreadsProvider
- adminSupportUnreadCountProvider
- adminThreadMessagesProvider
- adminSupportSearchProvider
- adminSupportRecipientsProvider
- jobLinkResolutionsProvider
- linkableJobsProvider
- AdminSupportThreadScreen
- AdminSupportThreadArgs
- ChatScreen
- ConversationDetailScreen
- ChatMessageInput
- NewSupportMessageSheet

## Dependencies
- flutter/widgets.dart
- flutter/material.dart
- flutter_riverpod/flutter_riverpod.dart
- supabase_flutter/supabase_flutter.dart
- http/http.dart
- cached_network_image/cached_network_image.dart
- image_picker/image_picker.dart
- dj_tilbud_app/core/config/env_config.dart
- dj_tilbud_app/core/error/app_exception.dart
- dj_tilbud_app/core/supabase/supabase_client.dart
- dj_tilbud_app/core/supabase/supabase_provider.dart
- dj_tilbud_app/core/design_system/components.dart
- dj_tilbud_app/shared/widgets/conversation_avatar.dart
- flutter
- flutter_riverpod
- go_router
- cached_network_image
- image_picker
- lucide_icons
- dj_tilbud_app/core/design_system
- dj_tilbud_app/core/notifications
- dj_tilbud_app/core/router
- dj_tilbud_app/core/supabase
- dj_tilbud_app/core/error
- dj_tilbud_app/features/chat/domain
- dj_tilbud_app/features/chat/presentation/providers
- dj_tilbud_app/features/chat/data/datasources
- dj_tilbud_app/features/jobs

## Open questions
- _none_
