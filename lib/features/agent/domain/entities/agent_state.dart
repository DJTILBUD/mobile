sealed class AgentState {
  const AgentState();
}

class AgentIdle extends AgentState {
  const AgentIdle();
}

class AgentStreaming extends AgentState {
  const AgentStreaming({required this.text});
  final String text;
}

class AgentDone extends AgentState {
  const AgentDone({required this.text});
  final String text;
}

class AgentError extends AgentState {
  const AgentError({required this.message});
  final String message;
}
