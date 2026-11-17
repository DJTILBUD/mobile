# Module: lib/features/first_win

Manages onboarding walkthroughs and first-win celebration popups shown to DJs and musicians (saxophonists) when they win their first event booking or job, distinguishing between solo jobs and jobs paired with a DJ.

## Key files
- `lib/features/first_win/domain/entities/first_win_decision.dart`: Defines the MusicianVariant enum, FirstWinDecision entity, and helper logic to determine pending first-win tutorial variants.
- `lib/features/first_win/domain/repositories/first_win_repository.dart`: Defines the abstract interface for determining whether to trigger first-win walkthroughs and marking them as shown.
- `lib/features/first_win/data/datasources/first_win_remote_datasource.dart`: Queries Supabase tables (DjInfos, Musicians, Quotes, ServiceOffers, ExtJobs) and executes the mark_first_win_shown RPC.
- `lib/features/first_win/data/repositories/first_win_repository_impl.dart`: Implements FirstWinRepository using FirstWinRemoteDatasource.
- `lib/features/first_win/presentation/providers/first_win_provider.dart`: Provides Riverpod providers (firstWinDecisionProvider, firstWinRepositoryProvider) and the markFirstWinShown helper function.
- `lib/features/first_win/presentation/widgets/first_win_dialog.dart`: Renders the multi-step guidance checklist modal (DJ, Musician with DJ, Musician Solo) and exports showFirstWinDialog.

## Public interface
- enum MusicianVariant
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
- package:lucide_icons/lucide_icons.dart
- package:supabase_flutter/supabase_flutter.dart
- lib/core/supabase/supabase_client.dart
- lib/core/design_system/components.dart
- lib/features/auth/domain/entities/musician_role.dart

## Open questions
- _none_
