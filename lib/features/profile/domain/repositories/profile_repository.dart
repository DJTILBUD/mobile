import 'package:dj_tilbud_app/features/profile/domain/entities/dj_job_filters.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/dj_profile.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/musician_profile.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/payment_info.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/review.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/user_file.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/admin_message.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/standard_message.dart';

abstract class ProfileRepository {
  // DJ profile
  Future<DjProfile> fetchDjProfile(String userId);
  Future<void> createDjProfile(DjProfile profile);
  Future<void> updateDjProfile(DjProfile profile);

  // Musician profile
  Future<MusicianProfile> fetchMusicianProfile(String userId);
  Future<void> createMusicianProfile({required MusicianProfile profile, required String email});
  Future<void> updateMusicianProfile(MusicianProfile profile);

  // Payment
  Future<PaymentInfo?> fetchPaymentInfo({required String userId, required bool isDj});
  Future<void> upsertPaymentInfo({required String userId, required bool isDj, required PaymentInfo info});

  // Reviews
  Future<List<Review>> fetchReviews({required String userId, required bool isDj});
  Future<Review> createReview({required String userId, required bool isDj, required String customerName, required int rating, required String review, required String eventType, required String eventDate});
  Future<void> updateReview({required String reviewId, required String customerName, required int rating, required String review, required String eventType, required String eventDate});
  Future<void> deleteReview(String reviewId);

  // User files
  Future<List<UserFile>> fetchUserFiles(String userId);
  Future<UserFile> uploadFile({required String userId, required String filePath, required UserFileType type});
  Future<void> deleteFile(int fileId);

  // DJ job filters
  Future<DjJobFilters?> fetchDjJobFilters(String userId);
  Future<void> saveDjJobFilters(DjJobFilters filters);

  // Admin messages
  Future<List<AdminMessage>> fetchAdminMessages({required String userId, required bool isDj});
  Future<void> markAdminMessageRead({required int messageId, required String userId, required bool isDj});

  // iCal token
  Future<String?> fetchIcalToken({required String userId, required bool isDj});
  Future<String> generateIcalToken({required String userId, required bool isDj});

  // Standard messages
  Future<List<StandardMessage>> fetchStandardMessages(String userId);
  Future<StandardMessage> createStandardMessage({required String userId, required String messageText, required String eventType});
  Future<void> updateStandardMessage({required int messageId, required String messageText, required String eventType});
  Future<void> deleteStandardMessage(int messageId);
}
