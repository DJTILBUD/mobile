# Module: lib/features/first_win

Manages first-win celebratory and onboarding walkthrough popups for DJs and Saxophonists after winning their first job or service offer, tracking walkthrough completion per role and variant in Supabase.

## Key files
- `lib/features/first_win/data/datasources/first_win_remote_datasource.dart`: Queries Supabase for DJ quotes and musician service offers/ext-jobs win state and executes mark_first_win_shown RPC.
- `lib/features/first_win/data/repositories/first_win_repository_impl.dart`: Implements repository logic to decide whether to trigger first-win onboarding and passes dismiss calls to the datasource.
- `lib/features/first_win/domain/entities/first_win_decision.dart`: Defines MusicianVariant enum, pending variant resolution logic, and FirstWinDecision value object.
- `lib/features/first_win/domain/repositories/first_win_repository.dart`: Defines contract for determining walkthrough eligibility and recording shown state.
- `lib/features/first_win/presentation/providers/first_win_provider.dart`: Provides Riverpod providers for repository access, decision calculations, and marking walkthrough completion.
- `lib/features/first_win/presentation/widgets/first_win_dialog.dart`: Renders multi-step interactive checklist dialog guiding musicians/DJs through customer contact, invoicing, and readiness confirmation.

## Public interface
- MusicianVariant
- MusicianVariant.withDj
- MusicianVariant.solo
- FirstWinDecision
- FirstWinDecision.hidden()
- FirstWinRepository
- FirstWinRepository.decide
- FirstWinRepository.markShown
- firstWinRepositoryProvider
- firstWinDecisionProvider
- markFirstWinShown(WidgetRef ref, MusicianRole role, {MusicianVariant? variant})
- showFirstWinDialog(BuildContext context, WidgetRef ref, MusicianRole role, {required MusicianVariant? musicianVariant})

## Dependencies
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:supabase_flutter/supabase_flutter.dart
- package:lucide_icons/lucide_icons.dart
- package:dj_tilbud_app/core/design_system/components.dart
- package:dj_tilbud_app/core/supabase/supabase_client.dart
- package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart

## Open questions
- _none_
