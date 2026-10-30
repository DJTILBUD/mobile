# Module: lib/features/chat

(part 1 of 2) Implements in-app chat for the mobile app: real-time conversations tied to jobs (between the two sides of a job thread, labeled 'dj' and 'musician' in the data model) plus a separate admin-staffed support channel where a user can message the DJTILBUD team. Also resolves inline '@job:' / '@extjob:' references pasted into messages so a chat bubble can link back to the job being discussed, and handles reactions, read receipts, typing indicators, and image attachments. (part 2 of 2) Implements the in-app messaging experience: a musician's conversation list, individual conversation threads (image attachments, replies, reactions, in-chat search, and an '@job'/'@extjob' mention picker), and an admin-only 'Support' tab/inbox for staff to message musicians or customers. Conversation threads can reference jobs via an '@job:id' token, tying chat to job/quote entities from the jobs feature.

_This module does not fit in one model call, so it was read in 2 parts and their summaries were combined without a further model call._

## Key files
- `lib/features/chat/domain/entities/conversation.dart`: Core Conversation entity: job vs support type, partner name/avatar, last message preview, unread count, reaction preview
- `lib/features/chat/domain/entities/chat_message.dart`: ChatMessage and MessageReaction entities, including admin/system message and edited-message flags
- `lib/features/chat/domain/entities/job_link.dart`: Defines the @job:/@extjob: inline reference format, JobLinkResolution/JobLinkTarget, and LinkableJob for the '@' picker
- `lib/features/chat/domain/repositories/chat_repository.dart`: Abstract contract for fetching/sending messages, reactions, read receipts, and image upload
- `lib/features/chat/data/repositories/chat_repository_impl.dart`: Concrete repository wiring the remote datasource to domain entities
- `lib/features/chat/data/datasources/chat_remote_datasource.dart`: Supabase-backed data access for conversations/messages, including feature-flagged support-conversation bootstrap and avatar/unread enrichment
- `lib/features/chat/data/datasources/admin_support_datasource.dart`: HTTP client to the web-app's admin support API (threads, recipients, reactions) since admins aren't RLS participants in conversations
- `lib/features/chat/data/datasources/job_link_remote_datasource.dart`: Calls the web-app's job-link search/resolve endpoints that are the source of truth for job visibility
- `lib/features/chat/data/models/conversation_model.dart`: JSON mapping and chat-eligibility/display logic for a conversation row
- `lib/features/chat/data/models/chat_message_model.dart`: JSON mapping for a chat message row
- `lib/features/chat/domain/chat_message_preview.dart`: Shared one-line preview text builder (handles image-only messages) mirrored with the web app
- `lib/features/chat/domain/chat_errors.dart`: Detects the server-enforced per-user chat rate limit and maps it to a friendly message
- `lib/features/chat/presentation/providers/chat_provider.dart`: Riverpod state for the conversation list and a single conversation's messages, with Supabase Realtime subscriptions
- `lib/features/chat/presentation/providers/admin_support_provider.dart`: Riverpod state for the admin support inbox, thread messages, search, and recipient picker
- `lib/features/chat/presentation/providers/job_links_provider.dart`: Riverpod providers for resolving/searching job links in the composer
- `lib/features/chat/presentation/providers/reactions_provider.dart`: Live emoji reactions per conversation via Realtime
- `lib/features/chat/presentation/providers/typing_provider.dart`: Ephemeral broadcast-based typing indicator for the support channel
- `lib/features/chat/presentation/screens/admin_support_thread_screen.dart`: Admin-facing single support thread UI (send/edit/react/search/jump-to-message, image attach)
- `lib/features/chat/presentation/screens/chat_screen.dart`: Top-level chat screen; shows musicians a single conversation list (_MyConversationsTab), and gives admins an extra 'Support' tab with unread badge, debounced thread search, and a way to start new support threads
- `lib/features/chat/presentation/screens/conversation_detail_screen.dart`: Single conversation thread screen: message list with realtime refresh/mark-as-read, image attach/preview, reply/edit, quick reactions, in-conversation search, typing indicator for support chats, and the '@' job-link mention picker
- `lib/features/chat/presentation/widgets/chat_message_input.dart`: Shared composer bar (image-attach button + text input + send button) reused identically by both the musician conversation screen and the admin support thread
- `lib/features/chat/presentation/widgets/new_support_message_sheet.dart`: Admin-only bottom sheet to pick a recipient and start a new support conversation, including the same '@job' mention autocomplete used in-thread

## Public interface
- ChatRepository
- ChatRepositoryImpl
- ChatMessage
- MessageReaction
- Conversation
- JobLinkResolution
- JobLinkTarget
- LinkableJob
- extractJobRefs
- chatMessagePreview
- isChatRateLimitError
- chatRepositoryProvider
- conversationsProvider
- adminSupportDatasourceProvider
- isAdminProvider
- adminSupportThreadsProvider
- adminSupportSearchProvider
- adminSupportRecipientsProvider
- adminSupportUnreadCountProvider
- adminLinkableJobsProvider
- adminJobLinkResolutionsProvider
- adminThreadMessagesProvider
- jobLinkResolutionsProvider
- linkableJobsProvider
- conversationReactionsProvider
- supportTypingProvider
- AdminSupportThreadScreen
- AdminSupportThread
- AdminRecipient
- AdminReaction
- AdminThreadData
- ChatScreen
- ConversationDetailScreen
- ChatMessageInput
- NewSupportMessageSheet

## Dependencies
- http
- supabase_flutter
- flutter_riverpod
- flutter/widgets.dart
- flutter/material.dart
- flutter/services.dart
- image_picker
- cached_network_image
- lib/core/config/env_config.dart
- lib/core/error/app_exception.dart
- lib/core/supabase/supabase_client.dart
- lib/core/supabase/supabase_provider.dart
- lib/core/design_system/components.dart
- lib/core/utils/event_type_labels.dart
- lib/shared/widgets/conversation_avatar.dart
- lib/core/router/app_routes.dart
- lib/core/notifications/in_app_notification_provider.dart
- lib/features/chat/domain/entities/conversation.dart
- lib/features/chat/domain/entities/chat_message.dart
- lib/features/chat/domain/entities/job_link.dart
- lib/features/chat/data/datasources/admin_support_datasource.dart
- lib/features/chat/presentation/providers/chat_provider.dart
- lib/features/chat/presentation/providers/admin_support_provider.dart
- lib/features/chat/presentation/providers/typing_provider.dart
- lib/features/chat/presentation/providers/reactions_provider.dart
- lib/features/chat/presentation/providers/job_links_provider.dart
- lib/features/jobs/presentation/providers/jobs_provider.dart
- lib/features/jobs/data/models/dj_quote_model.dart
- lib/features/jobs/data/models/ext_job_model.dart
- lib/features/jobs/data/models/job_model.dart
- lib/features/jobs/data/models/service_offer_model.dart
- go_router
- lucide_icons

## Open questions
- The file set shown only covers lib/features/chat; is the broader lib/features module (jobs, quoting, profile) out of scope for this summary or just truncated out of the provided listing?
- What exactly do the 'dj' and 'musician' sides of a Conversation represent in this product (e.g. is 'dj' the customer/event-organizer role or another musician-facing role), since the files only show these two generic labels without further context?
- Where does the chat message rate-limit trigger (check_message_rate_limit) live — it's referenced in lib/features/chat/domain/chat_errors.dart but its implementation isn't in this file set.
- The admin_support_datasource.dart file is truncated — its full set of endpoints (fetchThreads, fetchRecipients, markRead/Unread, setHandled, etc.) isn't fully visible.
- Only four chat-feature files were provided and some are truncated, so the full scope of lib/features (other modules besides chat) and even the rest of lib/features/chat (providers, datasources, other screens) is not visible.
- admin_support_thread_screen.dart is imported by chat_screen.dart but its contents aren't shown, so the admin Support tab's full behavior can't be verified.
- No AI/LLM prompt files or model API calls appear in these chat files; whether the product's advertised 'AI agent for profiles and sales pitches' lives in a different, unseen part of lib/features cannot be determined from this module alone.
