# Module: lib/features/agent

Implements the marketplace's AI agent capability: drafting sales pitches for job quotes, summarizing jobs, and coaching/drafting musician profile bios, by streaming responses from a Supabase edge function and tracking per-user usage limits.

## Key files
- `lib/features/agent/data/datasources/agent_remote_datasource.dart`: Calls the 'agent-assist' Supabase edge function over HTTP, parses an SSE stream of delta/done/error events into a text stream, and reads/writes AgentInteractions rows for usage counts and final submitted text
- `lib/features/agent/data/repositories/agent_repository_impl.dart`: Wraps the datasource, normalizing errors into AppException/AgentException for the UI layer
- `lib/features/agent/domain/entities/agent_state.dart`: Defines the sealed AgentState (Idle/Streaming/Done/Error) used to drive UI during generation
- `lib/features/agent/domain/repositories/agent_repository.dart`: Abstract contract for streaming agent assistance and updating final submitted text
- `lib/features/agent/presentation/providers/agent_provider.dart`: Riverpod providers: agentRepositoryProvider, AgentUsage model with daily/monthly limits, and AgentSessionNotifier that drives draft generation, refinement, job summaries, and profile coaching via streamAssist
- `lib/features/agent/presentation/widgets/agent_ai_button.dart`: Entry-point button shown on a job that opens the sales-pitch draft sheet, showing remaining AI usage or a limit-reached dialog
- `lib/features/agent/presentation/widgets/agent_bottom_sheet.dart`: Bottom sheet that kicks off sales-pitch draft generation using the job and the musician/DJ profile as context, and lets the user refine the draft
- `lib/features/agent/presentation/widgets/job_summary_bottom_sheet.dart`: Bottom sheet that streams an AI-generated job summary ('Joboversigt') for quick job assessment
- `lib/features/agent/presentation/widgets/profile_bio_bottom_sheet.dart`: Collects two profile questions (strengths, preferred events) then streams an AI-generated profile bio draft
- `lib/features/agent/presentation/widgets/profile_coach_bottom_sheet.dart`: Runs AI profile-coach analysis and also surfaces rule-based profile gap suggestions (photo, reviews, video, bio length, genres, venues), linking into the bio-draft sheet

## Public interface
- AgentRemoteDatasource
- AgentRepositoryImpl
- AgentRepository
- AgentState, AgentIdle, AgentStreaming, AgentDone, AgentError
- AgentUsage
- agentRepositoryProvider
- AgentSessionNotifier
- AgentAiButton
- AgentBottomSheet
- JobSummaryBottomSheet
- ProfileBioBottomSheet
- ProfileCoachBottomSheet

## Dependencies
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
- supabase_flutter
- http
- flutter_riverpod
- lucide_icons

## AI touchpoints [AI]
- `lib/features/agent/data/datasources/agent_remote_datasource.dart`
- `lib/features/agent/presentation/providers/agent_provider.dart`
- `lib/features/agent/presentation/widgets/agent_bottom_sheet.dart`
- `lib/features/agent/presentation/widgets/job_summary_bottom_sheet.dart`
- `lib/features/agent/presentation/widgets/profile_bio_bottom_sheet.dart`
- `lib/features/agent/presentation/widgets/profile_coach_bottom_sheet.dart`

## Open questions
- The agent_provider.dart file is truncated — the generateProfileBio method body, reset(), and the agentSessionProvider/profileCoachSessionProvider/agentUsageProvider declarations are not fully visible.
- jobToContext, djToUserContext, and musicianToUserContext helper functions are referenced but their defining file is not included in this module's listing.
- job_summary_bottom_sheet.dart and profile_bio_bottom_sheet.dart are truncated, so full widget behavior (e.g. _BottomBar, _GeneratingPhase) is not fully confirmed.
