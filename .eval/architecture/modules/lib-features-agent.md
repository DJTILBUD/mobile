# Module: lib/features/agent

Provides the client-side AI integration ('Skriv med AI' sales pitch generator, job summaries, profile bio generation, and Profile Coach analysis) by streaming prompts and responses to and from the Supabase edge function 'agent-assist' and tracking AI usage limits.

## Key files
- `lib/features/agent/data/datasources/agent_remote_datasource.dart`: Calls the backend Edge Function endpoint /agent-assist via HTTP/SSE streaming and manages usage count queries and final text updates in Supabase.
- `lib/features/agent/data/repositories/agent_repository_impl.dart`: Implements AgentRepository to bridge domain requests to the remote datasource and handle error wrapping.
- `lib/features/agent/domain/entities/agent_state.dart`: Defines the sealed AgentState hierarchy (AgentIdle, AgentStreaming, AgentDone, AgentError).
- `lib/features/agent/domain/repositories/agent_repository.dart`: Defines the contract for streaming AI completions and persisting submitted texts.
- `lib/features/agent/presentation/providers/agent_provider.dart`: Provides Riverpod state management and notifiers for handling AI drafting, refining, job summaries, and profile coach/bio generation.
- `lib/features/agent/presentation/widgets/agent_ai_button.dart`: Action button displaying AI usage status and triggering the sales pitch bottom sheet.
- `lib/features/agent/presentation/widgets/agent_bottom_sheet.dart`: Bottom sheet UI managing the interactive streaming, preview, and refinement of the 'Skriv med AI' sales pitch.
- `lib/features/agent/presentation/widgets/job_summary_bottom_sheet.dart`: Bottom sheet displaying AI-generated job summaries.
- `lib/features/agent/presentation/widgets/profile_bio_bottom_sheet.dart`: Multi-phase bottom sheet for prompting musicians with profile questions and generating an AI bio.
- `lib/features/agent/presentation/widgets/profile_coach_bottom_sheet.dart`: Profile coach UI identifying profile gaps and providing AI-assisted guidance and bio writing.

## Public interface
- AgentRemoteDatasource
- AgentRepository
- AgentRepositoryImpl
- AgentState (AgentIdle, AgentStreaming, AgentDone, AgentError)
- AgentUsage
- agentRepositoryProvider
- AgentSessionNotifier
- agentSessionProvider
- profileCoachSessionProvider
- agentUsageProvider
- AgentAiButton
- AgentBottomSheet
- JobSummaryBottomSheet
- ProfileBioBottomSheet
- ProfileCoachBottomSheet

## Dependencies
- package:http/http.dart
- package:supabase_flutter/supabase_flutter.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:lucide_icons/lucide_icons.dart
- dj_tilbud_app/core/config/env_config.dart
- dj_tilbud_app/core/error/app_exception.dart
- dj_tilbud_app/core/error/error_messages.dart
- dj_tilbud_app/core/supabase/supabase_provider.dart
- dj_tilbud_app/core/analytics/analytics_service.dart
- dj_tilbud_app/core/design_system/components.dart
- dj_tilbud_app/core/utils/event_type_labels.dart
- dj_tilbud_app/features/jobs/domain/entities/job.dart
- dj_tilbud_app/features/profile/domain/entities/dj_profile.dart
- dj_tilbud_app/features/profile/domain/entities/musician_profile.dart
- dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart

## AI touchpoints [AI]
- `lib/features/agent/data/datasources/agent_remote_datasource.dart`
- `lib/features/agent/presentation/providers/agent_provider.dart`

## Open questions
- _none_
