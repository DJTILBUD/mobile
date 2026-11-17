# Module: lib/features/chat

(part 1 of 2) Manages in-app chat and customer support messaging for musicians and DJs on the platform, providing real-time conversations, admin support thread management, emoji reactions, typing indicators, job reference tagging (@job), and chat rate-limiting handling. (part 2 of 2) Provides user messaging and administrative support chat interfaces, allowing musicians to converse with support/platform admins, exchange image attachments and message reactions, reference jobs using @-mentions, and allowing administrators to manage support threads and start new conversations.

_This module does not fit in one model call, so it was read in 2 parts and their summaries were combined without a further model call._

## Key files
- `lib/features/chat/domain/repositories/chat_repository.dart`: Abstract domain repository contract defining operations for conversations, messages, image attachments, read receipts, and emoji reactions.
- `lib/features/chat/data/repositories/chat_repository_impl.dart`: Concrete repository implementation bridging domain contracts with remote data sources.
- `lib/features/chat/data/datasources/chat_remote_datasource.dart`: Remote datasource interfacing with Supabase tables and endpoints for fetching and updating conversation lists, message histories, and user profile images.
- `lib/features/chat/data/datasources/admin_support_datasource.dart`: Datasource managing admin support threads, thread search, handled states, and admin support messaging via web-app REST endpoints.
- `lib/features/chat/data/datasources/job_link_remote_datasource.dart`: Datasource resolving '@job:' and '@extjob:' references and searching linkable jobs via web-app API endpoints.
- `lib/features/chat/presentation/providers/chat_provider.dart`: StateNotifier providers managing conversations, message streams, debounced Realtime Postgres subscriptions, and message error handling.
- `lib/features/chat/presentation/providers/admin_support_provider.dart`: StateNotifier and Future providers managing admin support thread feeds, search, unread badge counts, and thread statuses.
- `lib/features/chat/presentation/providers/reactions_provider.dart`: StateNotifier managing live emoji reactions per message backed by Supabase Realtime.
- `lib/features/chat/presentation/providers/typing_provider.dart`: Broadcast-based realtime provider managing ephemeral typing indicators for support chats.
- `lib/features/chat/presentation/screens/admin_support_thread_screen.dart`: Screen widget presenting the admin view of a support conversation thread with search, jumps, attachments, and reaction support.
- `lib/features/chat/presentation/screens/chat_screen.dart`: Main screen displaying the user's active conversations list, and an additional Admin Support inbox tab with search and unread badges for admin users.
- `lib/features/chat/presentation/screens/conversation_detail_screen.dart`: Conversation detail view supporting messaging, message replies/editing/reactions, typing indicators, image previews, job mentions, and in-chat message search.
- `lib/features/chat/presentation/widgets/chat_message_input.dart`: Reusable composer bar component containing image attachment, text input, and send triggers.
- `lib/features/chat/presentation/widgets/new_support_message_sheet.dart`: Admin modal bottom sheet to select a recipient (DJ/musician), tag jobs with @-mentions, and start a new support conversation thread.

## Public interface
- ChatRepository
- conversationsProvider
- adminSupportThreadsProvider
- isAdminProvider
- adminSupportSearchProvider
- adminSupportRecipientsProvider
- adminSupportUnreadCountProvider
- adminThreadMessagesProvider
- conversationReactionsProvider
- supportTypingProvider
- jobLinkResolutionsProvider
- linkableJobsProvider
- AdminSupportThreadScreen
- extractJobRefs(String text)
- ChatScreen
- ConversationDetailScreen
- ChatMessageInput
- NewSupportMessageSheet

## Dependencies
- supabase_flutter
- flutter_riverpod
- http
- image_picker
- cached_network_image
- dj_tilbud_app/core/config/env_config.dart
- dj_tilbud_app/core/error/app_exception.dart
- dj_tilbud_app/core/supabase/supabase_client.dart
- dj_tilbud_app/core/supabase/supabase_provider.dart
- dj_tilbud_app/core/utils/event_type_labels.dart
- dj_tilbud_app/core/design_system/components.dart
- dj_tilbud_app/shared/widgets/conversation_avatar.dart
- package:flutter/material.dart
- package:flutter/services.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:go_router/go_router.dart
- package:image_picker/image_picker.dart
- package:cached_network_image/cached_network_image.dart
- package:lucide_icons/lucide_icons.dart
- lib/core/design_system/components.dart
- lib/core/router/app_routes.dart
- lib/core/error/app_exception.dart
- lib/core/notifications/in_app_notification_provider.dart
- lib/core/supabase/supabase_client.dart
- lib/features/chat/domain/entities/conversation.dart
- lib/features/chat/domain/entities/chat_message.dart
- lib/features/chat/domain/entities/job_link.dart
- lib/features/chat/presentation/providers/chat_provider.dart
- lib/features/chat/presentation/providers/admin_support_provider.dart
- lib/features/chat/presentation/providers/typing_provider.dart
- lib/features/chat/presentation/providers/reactions_provider.dart
- lib/features/chat/presentation/providers/job_links_provider.dart
- lib/features/chat/data/datasources/admin_support_datasource.dart
- lib/features/chat/presentation/screens/admin_support_thread_screen.dart
- lib/features/jobs/presentation/providers/jobs_provider.dart
- lib/features/jobs/data/models/dj_quote_model.dart
- lib/features/jobs/data/models/ext_job_model.dart
- lib/features/jobs/data/models/job_model.dart
- lib/features/jobs/data/models/service_offer_model.dart
- lib/shared/widgets/conversation_avatar.dart

## Open questions
- _none_
