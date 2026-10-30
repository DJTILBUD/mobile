# Module: test/features/first_win

Unit tests pinning the decision logic for a musician's "first win" walkthrough/popup: verifying the exact RPC string values sent to the backend function that marks the popup as shown, and verifying which musician variant (with-DJ vs solo) should be shown pending a win, including priority and already-seen rules.

## Key files
- `test/features/first_win/first_win_decision_test.dart`: Test suite for MusicianVariant.rpcValue and the pendingMusicianVariant decision function used to decide which first-win popup variant to show a musician.

## Public interface
- _none_

## Dependencies
- flutter_test
- dj_tilbud_app/features/first_win/domain/entities/first_win_decision.dart

## Open questions
- Where is mark_first_win_shown called from the app, and how is its RPC error currently handled (the comment notes it was previously swallowed, causing the popup to reappear)?
- What triggers pendingMusicianVariant evaluation in the UI flow (e.g., after a musician views their won quotes)?
- Are there additional MusicianVariant values beyond withDj and solo, and how are they added to the rpcValue mapping?
