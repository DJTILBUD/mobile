import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/error/app_exception.dart';
import 'package:dj_tilbud_app/core/error/error_messages.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_provider.dart';
import 'package:dj_tilbud_app/features/agent/data/datasources/agent_remote_datasource.dart';
import 'package:dj_tilbud_app/features/agent/data/repositories/agent_repository_impl.dart';
import 'package:dj_tilbud_app/features/agent/domain/entities/agent_state.dart';
import 'package:dj_tilbud_app/features/agent/domain/repositories/agent_repository.dart';
import 'package:dj_tilbud_app/core/utils/event_type_labels.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/dj_profile.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/musician_profile.dart';

// ── Usage model ───────────────────────────────────────────────────────────────

class AgentUsage {
  const AgentUsage({
    required this.dailyUsed,
    required this.monthlyUsed,
    this.dailyLimit = 5,
    this.monthlyLimit = 20,
  });

  final int dailyUsed;
  final int monthlyUsed;
  final int dailyLimit;
  final int monthlyLimit;

  int get dailyRemaining => (dailyLimit - dailyUsed).clamp(0, dailyLimit);
  int get monthlyRemaining => (monthlyLimit - monthlyUsed).clamp(0, monthlyLimit);
  bool get isDailyLimitReached => dailyUsed >= dailyLimit;
  bool get isMonthlyLimitReached => monthlyUsed >= monthlyLimit;
  bool get isLimitReached => isDailyLimitReached || isMonthlyLimitReached;

  static const empty = AgentUsage(dailyUsed: 0, monthlyUsed: 0);
}

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

  // Accumulated conversation history for refinement turns.
  List<Map<String, String>> _messageHistory = [];

  // Cached context so refineWith() can re-use them without re-passing from UI.
  Map<String, dynamic> _lastJobContext = {};
  Map<String, dynamic> _lastUserContext = {};
  String _lastUserRole = 'dj';

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
    _messageHistory = [];
    _lastJobContext = jobContext;
    _lastUserContext = userContext;
    _lastUserRole = userRole;

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

      // Store the completed exchange so refinements have full context.
      _messageHistory = [
        {'role': 'user', 'content': 'Skriv en salgstale til dette job.'},
        {'role': 'assistant', 'content': _accumulatedText},
      ];

      state = AgentDone(text: _accumulatedText);
    } catch (e) {
      if (e is AgentLimitException) {
        final msg = e.limitType == 'daily'
            ? 'Du har brugt dine 5 AI-udkast for i dag. Prøv igen i morgen.'
            : 'Du har brugt dine 20 AI-udkast for denne måned.';
        state = AgentError(message: msg);
        return;
      }
      final message = friendlyErrorMessage(e, fallback: 'AI-assistenten er ikke tilgængelig lige nu. Prøv igen senere.');
      state = AgentError(message: message);
    }
  }

  /// Sends a follow-up refinement request using the accumulated session history.
  Future<void> refineWith(String refinementMessage) async {
    if (state is! AgentDone) return;
    state = const AgentStreaming(text: '');
    _accumulatedText = '';

    try {
      final stream = _repository.streamAssist(
        jobContext: _lastJobContext,
        userContext: _lastUserContext,
        userRole: _lastUserRole,
        sessionId: sessionId,
        messageHistory: _messageHistory
            .map((m) => Map<String, dynamic>.from(m))
            .toList(),
        followUpMessage: refinementMessage,
      );

      await for (final token in stream) {
        _accumulatedText += token;
        state = AgentStreaming(text: _accumulatedText);
      }

      // Extend history with this exchange.
      _messageHistory = [
        ..._messageHistory,
        {'role': 'user', 'content': refinementMessage},
        {'role': 'assistant', 'content': _accumulatedText},
      ];

      state = AgentDone(text: _accumulatedText);
    } catch (e) {
      if (e is AgentLimitException) {
        final msg = e.limitType == 'daily'
            ? 'Du har brugt dine 5 AI-udkast for i dag. Prøv igen i morgen.'
            : 'Du har brugt dine 20 AI-udkast for denne måned.';
        state = AgentError(message: msg);
        return;
      }
      final message = friendlyErrorMessage(e, fallback: 'AI-assistenten er ikke tilgængelig lige nu. Prøv igen senere.');
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
      final message = friendlyErrorMessage(e, fallback: 'AI-assistenten er ikke tilgængelig lige nu. Prøv igen senere.');
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
      if (e is AgentLimitException) {
        final msg = e.limitType == 'daily'
            ? 'Du har brugt dine 5 AI-udkast for i dag. Prøv igen i morgen.'
            : 'Du har brugt dine 20 AI-udkast for denne måned.';
        state = AgentError(message: msg);
        return;
      }
      final message = friendlyErrorMessage(e, fallback: 'AI-assistenten er ikke tilgængelig lige nu. Prøv igen senere.');
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
      if (e is AgentLimitException) {
        final msg = e.limitType == 'daily'
            ? 'Du har brugt dine 5 AI-udkast for i dag. Prøv igen i morgen.'
            : 'Du har brugt dine 20 AI-udkast for denne måned.';
        state = AgentError(message: msg);
        return;
      }
      final message = friendlyErrorMessage(e, fallback: 'AI-assistenten er ikke tilgængelig lige nu. Prøv igen senere.');
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

// Non-autoDispose — persists between sheet openings so the analysis is not
// regenerated every time the musician navigates away and comes back.
final profileCoachSessionProvider =
    StateNotifierProvider<AgentSessionNotifier, AgentState>(
  (ref) => AgentSessionNotifier(ref.watch(agentRepositoryProvider)),
);

// ── Usage provider ────────────────────────────────────────────────────────────

final agentUsageProvider = FutureProvider.autoDispose<AgentUsage>((ref) async {
  final datasource = AgentRemoteDatasource(ref.watch(supabaseClientProvider));
  final counts = await datasource.fetchUsageCounts();
  return AgentUsage(
    dailyUsed: counts.dailyUsed,
    monthlyUsed: counts.monthlyUsed,
  );
});

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
