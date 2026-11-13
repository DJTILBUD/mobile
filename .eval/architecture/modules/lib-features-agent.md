# Module: lib/features/agent

Provides AI-assisted features for musicians and DJs, including the 'Skriv med AI' sales pitch generator and refinement tool, AI job summarizer, profile bio writer, and profile coach feedback with profile gap analysis.

## Key files
- `lib/features/agent/data/datasources/agent_remote_datasource.dart`: Calls the Supabase Edge Function 'agent-assist' over SSE HTTP streaming, fetches user daily/monthly usage counts, and logs final accepted text in AgentInteractions.
- `lib/features/agent/data/repositories/agent_repository_impl.dart`: Implements the agent repository interface, routing generation streams and database updates while mapping exceptions.
- `lib/features/agent/domain/entities/agent_state.dart`: Defines the sealed AgentState hierarchy (AgentIdle, AgentStreaming, AgentDone, AgentError).
- `lib/features/agent/domain/repositories/agent_repository.dart`: Declares abstract interface for streaming agent responses and saving final submitted text.
- `lib/features/agent/presentation/providers/agent_provider.dart`: Riverpod providers and notifiers managing session streaming state, multi-turn refinement history, agent usage limits, and generation dispatchers.
- `lib/features/agent/presentation/widgets/agent_ai_button.dart`: Action button displaying remaining daily/monthly AI quota and opening the AI pitch generation sheet.
- `lib/features/agent/presentation/widgets/agent_bottom_sheet.dart`: Modal bottom sheet UI for streaming, reading, editing, refining, and accepting AI-generated sales pitches for open jobs.
- `lib/features/agent/presentation/widgets/job_summary_bottom_sheet.dart`: Modal bottom sheet displaying a streamed AI summary of a job's details.
- `lib/features/agent/presentation/widgets/profile_bio_bottom_sheet.dart`: Two-phase bottom sheet collecting musician strengths and preferences to stream an AI-generated profile bio.
- `lib/features/agent/presentation/widgets/profile_coach_bottom_sheet.dart`: AI profile coach bottom sheet displaying rule-based profile completeness gap cards and streamed AI coaching feedback.

## Public interface
- AgentRemoteDatasource.streamAssist
- AgentRemoteDatasource.fetchUsageCounts
- AgentRemoteDatasource.updateFinalSubmittedText
- AgentRepository.streamAssist
- AgentRepository.updateFinalSubmittedText
- AgentRepositoryImpl
- AgentState
- AgentIdle
- AgentStreaming
- AgentDone
- AgentError
- AgentUsage
- AgentSessionNotifier.generateDraft
- AgentSessionNotifier.refineWith
- AgentSessionNotifier.generateSummary
- AgentSessionNotifier.generateProfileCoach
- agentRepositoryProvider
- AgentAiButton
- AgentBottomSheet
- JobSummaryBottomSheet
- ProfileBioBottomSheet
- ProfileCoachBottomSheet

## Dependencies
- package:http/http.dart
- package:supabase_flutter/supabase_flutter.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:flutter/material.dart
- package:lucide_icons/lucide_icons.dart
- lib/core/config/env_config.dart
- lib/core/error/app_exception.dart
- lib/core/error/error_messages.dart
- lib/core/supabase/supabase_provider.dart
- lib/core/utils/event_type_labels.dart
- lib/core/analytics/analytics_service.dart
- lib/core/design_system/components.dart
- lib/features/jobs/domain/entities/job.dart
- lib/features/profile/domain/entities/dj_profile.dart
- lib/features/profile/domain/entities/musician_profile.dart
- lib/features/profile/presentation/providers/profile_provider.dart

## AI touchpoints [AI]
- `lib/features/agent/data/datasources/agent_remote_datasource.dart`
- `lib/features/agent/presentation/providers/agent_provider.dart`
- `lib/features/agent/presentation/widgets/agent_bottom_sheet.dart`
- `lib/features/agent/presentation/widgets/job_summary_bottom_sheet.dart`
- `lib/features/agent/presentation/widgets/profile_bio_bottom_sheet.dart`
- `lib/features/agent/presentation/widgets/profile_coach_bottom_sheet.dart`

## Open questions
- _none_
