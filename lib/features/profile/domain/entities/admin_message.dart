class AdminMessage {
  const AdminMessage({
    required this.id,
    required this.header,
    required this.content,
    required this.createdAt,
    required this.isRead,
  });

  final int id;
  final String header;
  final String content;
  final DateTime createdAt;
  final bool isRead;
}
