# Module: lib/features/first_win

Decides whether to show a one-time celebratory walkthrough popup when a DJ or musician wins their first job, picks the correct variant (DJ, musician-with-DJ, or musician-solo) based on actual win records, renders the step-by-step dialog content, and marks the popup as seen via a Supabase RPC so it does not reappear.

## Key files
- `lib/features/first_win/data/datasources/first_win_remote_datasource.dart`: Supabase queries/RPC calls that read DJ/Musician 'shown_at' columns and Quotes/ServiceOffers/ExtJobs win status, and call the mark_first_win_shown RPC to persist that the popup was shown
- `lib/features/first_win/data/repositories/first_win_repository_impl.dart`: Implements FirstWinRepository by combining 'shown' state and 'has won' state into a FirstWinDecision
- `lib/features/first_win/domain/entities/first_win_decision.dart`: Domain model: MusicianVariant enum (withDj/solo), pendingMusicianVariant() pure decision logic, and FirstWinDecision value object
- `lib/features/first_win/domain/repositories/first_win_repository.dart`: Abstract repository contract: decide() and markShown()
- `lib/features/first_win/presentation/providers/first_win_provider.dart`: Riverpod providers wiring the repository/datasource to Supabase client, exposing firstWinDecisionProvider and markFirstWinShown() for UI use
- `lib/features/first_win/presentation/widgets/first_win_dialog.dart`: Flutter dialog UI rendering role/variant-specific onboarding steps (DJ, musician-with-DJ, musician-solo) and calling markFirstWinShown on completion

## Public interface
- FirstWinRemoteDatasource
- FirstWinRepositoryImpl
- FirstWinRepository
- FirstWinDecision
- FirstWinDecision.hidden
- MusicianVariant
- MusicianVariant.rpcValue
- pendingMusicianVariant
- firstWinRepositoryProvider
- firstWinDecisionProvider
- markFirstWinShown
- showFirstWinDialog

## Dependencies
- supabase_flutter
- flutter_riverpod
- flutter/material.dart
- lucide_icons
- dj_tilbud_app/core/supabase/supabase_client.dart
- dj_tilbud_app/features/auth/domain/entities/musician_role.dart
- dj_tilbud_app/core/design_system/components.dart

## Open questions
- first_win_dialog.dart is truncated in the provided excerpt — _handleNext()'s full finishing/markShown logic and dialog layout are not fully visible.
- The legacy Musicians.first_win_shown_at column still exists in the DB but is explicitly called out as dead/unwritten — unclear if any other code still reads it.
- The RPC mark_first_win_shown's exact signature/behavior lives in a DB migration not included here, so its validation logic (e.g. the 'Invalid variant for musician' error) is only documented via comments, not verifiable in these files.
