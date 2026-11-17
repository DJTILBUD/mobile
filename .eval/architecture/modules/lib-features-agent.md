# Module: lib/features/agent

Provides the musician-facing AI assistant client module, enabling DJs and saxophonists to stream and refine sales pitch drafts for job quotes, generate job summaries, analyze profile completeness via the profile-coach, and generate bio descriptions using Supabase Edge Functions.

## Key files
- `lib/features/agent/data/datasources/agent_remote_datasource.dart`: Calls the backend agent-assist Edge Function over SSE streaming and interacts with the AgentInteractions Supabase table for usage tracking and final submission logging.
- `lib/features/agent/data/repositories/agent_repository_impl.dart`: Implements the domain repository interface to expose streaming AI assist responses and save submitted texts.
- `lib/features/agent/domain/entities/agent_state.dart`: Defines the state hierarchy (AgentIdle, AgentStreaming, AgentDone, AgentError) for AI interactions.
- `lib/features/agent/domain/repositories/agent_repository.dart`: Abstract contract defining streamAssist and updateFinalSubmittedText operations.
- `lib/features/agent/presentation/providers/agent_provider.dart`: Riverpod state management coordinating AI usage limits, conversation session history, refinement turns, and generators for sales pitches, summaries, and profile coaching.
- `lib/features/agent/presentation/widgets/agent_ai_button.dart`: Trigger button displaying AI usage count badges and launching the sales pitch generation sheet.
- `lib/features/agent/presentation/widgets/agent_bottom_sheet.dart`: Modal bottom sheet facilitating real-time streamed quote drafts, iterative refinement prompts, and draft acceptance.
- `lib/features/agent/presentation/widgets/job_summary_bottom_sheet.dart`: Modal bottom sheet displaying streamed AI job summaries for quick job evaluations.
- `lib/features/agent/presentation/widgets/profile_bio_bottom_sheet.dart`: Guided Q&A workflow for generating personalized musician profile bios using AI.
- `lib/features/agent/presentation/widgets/profile_coach_bottom_sheet.dart`: Interactive profile-coach surface diagnosing missing profile attributes and triggering AI recommendations.

## Public interface
- AgentState (AgentIdle, AgentStreaming, AgentDone, AgentError)
- AgentRepository (streamAssist, updateFinalSubmittedText)
- AgentRemoteDatasource (streamAssist, fetchUsageCounts, updateFinalSubmittedText)
- AgentUsage (dailyUsed, monthlyUsed, dailyRemaining, monthlyRemaining, isLimitReached)
- agentRepositoryProvider
- AgentSessionNotifier (generateDraft, refineWith, generateSummary, generateProfileCoach)
- AgentAiButton
- AgentBottomSheet
- JobSummaryBottomSheet
- ProfileBioBottomSheet
- ProfileCoachBottomSheet

## Dependencies
- lib/core/config/env_config.dart
- lib/core/error/app_exception.dart
- lib/core/error/error_messages.dart
- lib/core/supabase/supabase_provider.dart
- lib/core/analytics/analytics_service.dart
- lib/core/design_system/components.dart
- lib/core/utils/event_type_labels.dart
- lib/features/jobs/domain/entities/job.dart
- lib/features/profile/domain/entities/dj_profile.dart
- lib/features/profile/domain/entities/musician_profile.dart
- lib/features/profile/presentation/providers/profile_provider.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:supabase_flutter/supabase_flutter.dart
- package:http/http.dart
- package:lucide_icons/lucide_icons.dart

## AI touchpoints [AI]
- `lib/features/agent/data/datasources/agent_remote_datasource.dart`
- `lib/features/agent/presentation/providers/agent_provider.dart`
- `lib/features/agent/presentation/widgets/agent_bottom_sheet.dart`
- `lib/features/agent/presentation/widgets/job_summary_bottom_sheet.dart`
- `lib/features/agent/presentation/widgets/profile_bio_bottom_sheet.dart`
- `lib/features/agent/presentation/widgets/profile_coach_bottom_sheet.dart`

## Open questions
- Are the hardcoded daily and monthly limits in AgentUsage (10 and 100) intentionally in sync with the error copy mentioning 5 daily and 20 monthly limits in AgentSessionNotifier?
