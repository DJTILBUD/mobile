import 'package:dj_tilbud_app/features/profile/domain/entities/review.dart';

class ReviewModel {
  const ReviewModel({
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
  final String createdAt;

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      customerName: json['customer_name'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 3,
      review: json['review'] as String? ?? '',
      eventType: json['event_type'] as String? ?? '',
      eventDate: json['event_date'] as String? ?? '',
      createdAt: json['created_at'] as String,
    );
  }

  Review toEntity() {
    return Review(
      id: id,
      customerName: customerName,
      rating: rating,
      review: review,
      eventType: eventType,
      eventDate: eventDate,
      createdAt: DateTime.parse(createdAt),
    );
  }
}
