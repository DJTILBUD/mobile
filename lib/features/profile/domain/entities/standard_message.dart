class StandardMessage {
  const StandardMessage({
    required this.id,
    required this.messageText,
    required this.eventType,
    required this.createdAt,
  });

  final int id;
  final String messageText;
  final String eventType;
  final DateTime createdAt;
}
