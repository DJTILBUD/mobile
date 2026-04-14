import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/error/app_exception.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_provider.dart';
import 'package:dj_tilbud_app/features/agent/data/datasources/agent_remote_datasource.dart';
import 'package:dj_tilbud_app/features/agent/data/repositories/agent_repository_impl.dart';
import 'package:dj_tilbud_app/features/agent/domain/entities/agent_state.dart';
import 'package:dj_tilbud_app/features/agent/domain/repositories/agent_repository.dart';
import 'package:dj_tilbud_app/core/utils/event_type_labels.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/dj_profile.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/musician_profile.dart';

// ── Repository provider ──────────────────────────────────────────────────────

final agentRepositoryProvider = Provider<AgentRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AgentRepositoryImpl(AgentRemoteDatasource(client));
});

// ── Session notifier (autoDispose — lives only while bottom sheet is open) ───

class AgentSessionNotifier extends StateNotifier<AgentState> {
  AgentSessionNotifier(this._repository) : super(const AgentIdle());

  final AgentRepository _repository;

  /// Unique ID for this session — used for logging and final text tracking.
  final String sessionId = _generateSessionId();

  String _accumulatedText = '';

  static String _generateSessionId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rng = Random.secure();
    return List.generate(32, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<void> generateDraft({
    required Map<String, dynamic> jobContext,
    required Map<String, dynamic> userContext,
    required String userRole,
  }) async {
    state = const AgentStreaming(text: '');
    _accumulatedText = '';

    try {
      final stream = _repository.streamAssist(
        jobContext: jobContext,
        userContext: userContext,
        userRole: userRole,
        sessionId: sessionId,
        messageHistory: const [],
      );

      await for (final token in stream) {
        _accumulatedText += token;
        state = AgentStreaming(text: _accumulatedText);
      }

      state = AgentDone(text: _accumulatedText);
    } catch (e) {
      final message = e is AppException ? e.message : e.toString();
      state = AgentError(message: message);
    }
  }

  Future<void> generateSummary({
    required Map<String, dynamic> jobContext,
  }) async {
    state = const AgentStreaming(text: '');
    _accumulatedText = '';

    try {
      final stream = _repository.streamAssist(
        jobContext: jobContext,
        userContext: const {},
        userRole: 'dj',
        sessionId: sessionId,
        messageHistory: const [],
        purpose: 'summary',
      );

      await for (final token in stream) {
        _accumulatedText += token;
        state = AgentStreaming(text: _accumulatedText);
      }

      state = AgentDone(text: _accumulatedText);
    } catch (e) {
      final message = e is AppException ? e.message : e.toString();
      state = AgentError(message: message);
    }
  }

  Future<void> generateProfileCoach({
    required Map<String, dynamic> userContext,
    required String userRole,
  }) async {
    state = const AgentStreaming(text: '');
    _accumulatedText = '';

    try {
      final stream = _repository.streamAssist(
        jobContext: {'type': 'profile_coach'},
        userContext: userContext,
        userRole: userRole,
        sessionId: sessionId,
        messageHistory: const [],
        purpose: 'profile_coach',
      );

      await for (final token in stream) {
        _accumulatedText += token;
        state = AgentStreaming(text: _accumulatedText);
      }

      state = AgentDone(text: _accumulatedText);
    } catch (e) {
      final message = e is AppException ? e.message : e.toString();
      state = AgentError(message: message);
    }
  }

  Future<void> generateProfileBio({
    required Map<String, dynamic> userContext,
    required String userRole,
    required String strengths,
    required String preferredEvents,
  }) async {
    state = const AgentStreaming(text: '');
    _accumulatedText = '';

    try {
      final stream = _repository.streamAssist(
        jobContext: {'type': 'profile_bio'},
        userContext: userContext,
        userRole: userRole,
        sessionId: sessionId,
        messageHistory: const [],
        purpose: 'profile_bio',
        profileAnswers: {
          'strengths': strengths,
          'preferredEvents': preferredEvents,
        },
      );

      await for (final token in stream) {
        _accumulatedText += token;
        state = AgentStreaming(text: _accumulatedText);
      }

      state = AgentDone(text: _accumulatedText);
    } catch (e) {
      final message = e is AppException ? e.message : e.toString();
      state = AgentError(message: message);
    }
  }

  void reset() {
    state = const AgentIdle();
    _accumulatedText = '';
  }

  /// Call after the musician submits the offer to track how much they edited.
  Future<void> trackFinalText(String submittedText) async {
    await _repository.updateFinalSubmittedText(
      sessionId: sessionId,
      finalText: submittedText,
    );
  }
}

final agentSessionProvider = StateNotifierProvider.autoDispose<
    AgentSessionNotifier, AgentState>(
  (ref) => AgentSessionNotifier(ref.watch(agentRepositoryProvider)),
);

// ── Context builders (pure functions, no providers needed) ────────────────────

Map<String, dynamic> jobToContext(Job job) => {
      'id': job.id,
      'eventType': job.eventType,
      'eventTypeLabel': eventTypeLabel(job.eventType),
      'date': job.date.toIso8601String(),
      'city': job.city,
      'region': job.region,
      'guestsAmount': job.guestsAmount,
      'budgetStart': job.budgetStart,
      'budgetEnd': job.budgetEnd,
      'genres': job.genres,
      'leadRequest': job.leadRequest,
      'additionalInformation': job.additionalInformation,
      'requestedMusicianHours': job.requestedMusicianHours,
      'birthdayPersonAge': job.birthdayPersonAge,
      'customerNote': job.customerNote,
    };

Map<String, dynamic> djToUserContext(DjProfile profile) => {
      'fullName': profile.fullName,
      'instrument': 'dj',
      'aboutYou': profile.aboutYou,
      'genres': profile.genres,
      'regions': profile.regions,
      'venuesAndEvents': profile.venuesAndEvents ?? [],
      'canPlayWithSax': profile.canPlayWithSax,
    };

Map<String, dynamic> musicianToUserContext(MusicianProfile profile) => {
      'fullName': profile.fullName,
      'instrument': profile.instrument,
      'aboutText': profile.aboutText ?? '',
      'genres': profile.genres ?? [],
      'regions': profile.regions,
      'experienceYears': profile.experienceYears,
      'venuesAndEvents': profile.venuesAndEvents ?? [],
    };
