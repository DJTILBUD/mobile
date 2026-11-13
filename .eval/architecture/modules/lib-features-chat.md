# Module: lib/features/chat

(part 1 of 2) Provides chat functionality for musicians and administrators, including real-time messaging, support conversations, emoji reactions, message editing, attachments, ephemeral typing indicators, and embedded job reference linking. (part 2 of 2) Provides the chat user interface and conversation views in the mobile app, allowing musicians and admin users to participate in direct messaging, admin support threads, message replies, image attachments, message reactions, in-conversation search, and inline @job mentions.

_This module does not fit in one model call, so it was read in 2 parts and their summaries were combined without a further model call._

## Key files
- `lib/features/chat/data/datasources/admin_support_datasource.dart`: Handles admin-specific support operations communicating with web-app endpoints for inbox threads, recipients, job links, and thread management
- `lib/features/chat/data/datasources/chat_remote_datasource.dart`: Manages conversation and message data fetching from Supabase database tables and web-app endpoints
- `lib/features/chat/data/datasources/job_link_remote_datasource.dart`: Interacts with web-app endpoints to search linkable jobs and resolve job tokens (@job:/@extjob:)
- `lib/features/chat/data/models/chat_message_model.dart`: Data model for serialization and entity mapping of individual chat messages
- `lib/features/chat/data/models/conversation_model.dart`: Data model for serialization, role-based filtering, and entity mapping of conversations
- `lib/features/chat/data/repositories/chat_repository_impl.dart`: Implements ChatRepository interface to orchestrate chat operations through data sources
- `lib/features/chat/domain/chat_errors.dart`: Defines rate limit error detection and localized error messaging
- `lib/features/chat/domain/chat_message_preview.dart`: Formats one-line conversation list preview text handling text and media attachments
- `lib/features/chat/domain/entities/chat_message.dart`: Domain entities representing chat messages and message reactions
- `lib/features/chat/domain/entities/conversation.dart`: Domain entity representing a conversation thread (job coordination or support)
- `lib/features/chat/domain/entities/job_link.dart`: Entities and regex utilities for extracting, resolving, and targeting job links in messages
- `lib/features/chat/domain/repositories/chat_repository.dart`: Contract defining chat operations including message sending, editing, media upload, reactions, and read status
- `lib/features/chat/presentation/providers/admin_support_provider.dart`: Riverpod state management for admin support threads, search, job link resolution, and real-time updates
- `lib/features/chat/presentation/providers/chat_provider.dart`: Riverpod state management for user conversations and active message feeds with real-time Supabase sync
- `lib/features/chat/presentation/providers/job_links_provider.dart`: Riverpod providers for resolving message job tokens and querying linkable jobs for composer picker
- `lib/features/chat/presentation/providers/reactions_provider.dart`: Riverpod state notifier managing live emoji reactions via Supabase Realtime
- `lib/features/chat/presentation/providers/typing_provider.dart`: Riverpod state notifier managing broadcast-based typing indicators on support channels
- `lib/features/chat/presentation/screens/admin_support_thread_screen.dart`: Admin UI screen for viewing, searching, reacting, jumping to messages, and sending replies in support threads
- `lib/features/chat/presentation/screens/chat_screen.dart`: Main chat dashboard screen providing tabs for user conversations ('Beskeder') and admin support inbox ('Support') with unread indicators and search.
- `lib/features/chat/presentation/screens/conversation_detail_screen.dart`: Detail view for active chat conversations handling message streaming, typing state, read markers, reactions, image attachments, full-screen previews, reply quotes, and @mention job autocompletion.
- `lib/features/chat/presentation/widgets/chat_message_input.dart`: Rechargeable chat composer bar widget offering text input, image attach action, and send triggers.
- `lib/features/chat/presentation/widgets/new_support_message_sheet.dart`: Modal bottom sheet facilitating the initiation of a new support conversation by an admin, including musician recipient search and inline job referencing.

## Public interface
- adminSupportDatasourceProvider
- isAdminProvider
- adminSupportThreadsProvider
- adminSupportSearchProvider
- adminSupportRecipientsProvider
- adminSupportUnreadCountProvider
- adminLinkableJobsProvider
- adminJobLinkResolutionsProvider
- adminThreadMessagesProvider
- chatRepositoryProvider
- conversationsProvider
- jobLinkDatasourceProvider
- jobLinkResolutionsProvider
- linkableJobsProvider
- conversationReactionsProvider
- supportTypingProvider
- AdminSupportThreadArgs
- AdminSupportThreadScreen
- extractJobRefs(String text)
- ChatScreen
- ConversationDetailScreen
- ChatMessageInput
- NewSupportMessageSheet

## Dependencies
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:supabase_flutter/supabase_flutter.dart
- package:http/http.dart
- package:cached_network_image/cached_network_image.dart
- package:image_picker/image_picker.dart
- dj_tilbud_app/core/config/env_config.dart
- dj_tilbud_app/core/error/app_exception.dart
- dj_tilbud_app/core/supabase/supabase_client.dart
- dj_tilbud_app/core/supabase/supabase_provider.dart
- dj_tilbud_app/core/utils/event_type_labels.dart
- dj_tilbud_app/core/design_system/components.dart
- dj_tilbud_app/shared/widgets/conversation_avatar.dart
- package:go_router/go_router.dart
- package:lucide_icons/lucide_icons.dart
- lib/core/design_system/components.dart
- lib/core/notifications/in_app_notification_provider.dart
- lib/core/router/app_routes.dart
- lib/core/supabase/supabase_client.dart
- lib/core/error/app_exception.dart
- lib/features/chat/domain/entities/chat_message.dart
- lib/features/chat/domain/entities/conversation.dart
- lib/features/chat/domain/entities/job_link.dart
- lib/features/chat/presentation/providers/chat_provider.dart
- lib/features/chat/presentation/providers/typing_provider.dart
- lib/features/chat/presentation/providers/reactions_provider.dart
- lib/features/chat/presentation/providers/job_links_provider.dart
- lib/features/chat/presentation/providers/admin_support_provider.dart
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
