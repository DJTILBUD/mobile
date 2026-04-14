import 'package:dj_tilbud_app/core/error/app_exception.dart';
import 'package:dj_tilbud_app/features/agent/data/datasources/agent_remote_datasource.dart';
import 'package:dj_tilbud_app/features/agent/domain/repositories/agent_repository.dart';

class AgentRepositoryImpl implements AgentRepository {
  AgentRepositoryImpl(this._datasource);

  final AgentRemoteDatasource _datasource;

  @override
  Stream<String> streamAssist({
    required Map<String, dynamic> jobContext,
    required Map<String, dynamic> userContext,
    required String userRole,
    required String sessionId,
    List<Map<String, dynamic>> messageHistory = const [],
    String purpose = 'sales_pitch',
    Map<String, String>? profileAnswers,
  }) {
    try {
      return _datasource.streamAssist(
        jobContext: jobContext,
        userContext: userContext,
        userRole: userRole,
        sessionId: sessionId,
        messageHistory: messageHistory,
        purpose: purpose,
        profileAnswers: profileAnswers,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw AgentException('Unexpected error: $e');
    }
  }

  @override
  Future<void> updateFinalSubmittedText({
    required String sessionId,
    required String finalText,
  }) async {
    try {
      await _datasource.updateFinalSubmittedText(
        sessionId: sessionId,
        finalText: finalText,
      );
    } catch (e) {
      // Non-critical — don't surface to user
    }
  }
}
