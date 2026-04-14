abstract class AgentRepository {
  Stream<String> streamAssist({
    required Map<String, dynamic> jobContext,
    required Map<String, dynamic> userContext,
    required String userRole,
    required String sessionId,
    List<Map<String, dynamic>> messageHistory,
    String purpose,
    Map<String, String>? profileAnswers,
  });

  Future<void> updateFinalSubmittedText({
    required String sessionId,
    required String finalText,
  });
}
