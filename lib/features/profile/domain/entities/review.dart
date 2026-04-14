class Review {
  const Review({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.review,
    required this.eventType,
    required this.eventDate,
    required this.createdAt,
  });

  final String id;
  final String customerName;
  final int rating;
  final String review;
  final String eventType;
  final String eventDate;
  final DateTime createdAt;
}
