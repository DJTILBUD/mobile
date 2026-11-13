# Module: lib/features/first_win

Manages first-win celebration and onboarding walkthrough dialogs for DJs and musicians after their first won job, determining which role-specific flow to present (DJ, musician with DJ, or solo musician) and tracking completion via Supabase.

## Key files
- `lib/features/first_win/data/datasources/first_win_remote_datasource.dart`: Queries Supabase tables (DjInfos, Quotes, Musicians, ServiceOffers, ExtJobs) to determine if a user has won and whether a popup variant is pending, and invokes the mark_first_win_shown RPC.
- `lib/features/first_win/data/repositories/first_win_repository_impl.dart`: Implements FirstWinRepository to decide if a walkthrough should be shown and execute dismissal marking.
- `lib/features/first_win/domain/entities/first_win_decision.dart`: Defines the MusicianVariant enum, pending variant resolution logic (pendingMusicianVariant), and the FirstWinDecision entity.
- `lib/features/first_win/domain/repositories/first_win_repository.dart`: Defines the repository interface for evaluating first-win decisions and marking walkthroughs as shown.
- `lib/features/first_win/presentation/providers/first_win_provider.dart`: Provides Riverpod providers (firstWinRepositoryProvider, firstWinDecisionProvider) and the markFirstWinShown helper function.
- `lib/features/first_win/presentation/widgets/first_win_dialog.dart`: Renders the multi-step guided walkthrough modal dialog with role-specific checklists and instructions.

## Public interface
- enum MusicianVariant { withDj, solo }
- String MusicianVariant.rpcValue
- MusicianVariant? pendingMusicianVariant({required bool withDjPending, required bool soloPending, required bool hasWithDjWin, required bool hasSoloWin})
- class FirstWinDecision
- abstract class FirstWinRepository
- class FirstWinRepositoryImpl
- class FirstWinRemoteDatasource
- Provider<FirstWinRepository> firstWinRepositoryProvider
- FutureProvider.family<FirstWinDecision, MusicianRole> firstWinDecisionProvider
- Future<void> markFirstWinShown(WidgetRef ref, MusicianRole role, {MusicianVariant? variant})
- Future<void> showFirstWinDialog(BuildContext context, WidgetRef ref, MusicianRole role, {required MusicianVariant? musicianVariant})

## Dependencies
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:supabase_flutter/supabase_flutter.dart
- package:lucide_icons/lucide_icons.dart
- package:dj_tilbud_app/core/supabase/supabase_client.dart
- package:dj_tilbud_app/core/design_system/components.dart
- package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart

## Open questions
- lib/features/first_win/presentation/widgets/first_win_dialog.dart was truncated during file reading; exact implementation details of dialog completion, error handling, and dismissal remain uninspected.
