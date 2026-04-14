import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:dj_tilbud_app/core/error/app_exception.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/dj_job_filters.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/dj_profile.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/musician_profile.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/payment_info.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/review.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/user_file.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/admin_message.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/standard_message.dart';
import 'package:dj_tilbud_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:dj_tilbud_app/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:dj_tilbud_app/features/profile/data/models/dj_profile_model.dart';
import 'package:dj_tilbud_app/features/profile/data/models/musician_profile_model.dart';
import 'package:dj_tilbud_app/features/profile/data/models/payment_info_model.dart';
import 'package:dj_tilbud_app/features/profile/data/models/review_model.dart';
import 'package:dj_tilbud_app/features/profile/data/models/user_file_model.dart';
import 'package:dj_tilbud_app/features/profile/data/models/dj_job_filters_model.dart';
import 'package:dj_tilbud_app/features/profile/data/models/standard_message_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._datasource);

  final ProfileRemoteDatasource _datasource;

  // ── DJ Profile ──

  @override
  Future<DjProfile> fetchDjProfile(String userId) async {
    try {
      final data = await _datasource.fetchDjProfile(userId);
      return DjProfileModel.fromJson(data).toEntity();
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<void> createDjProfile(DjProfile profile) async {
    try {
      final model = DjProfileModel(
        id: profile.id,
        fullName: profile.fullName,
        companyOrDjName: profile.companyOrDjName,
        phone: profile.phone,
        aboutYou: profile.aboutYou,
        pricePerExtraHour: profile.pricePerExtraHour,
        regions: profile.regions,
        genres: profile.genres,
        canPlayWithSax: profile.canPlayWithSax,
        allowPublicDjProfile: profile.allowPublicDjProfile,
        soundcloudUrl: profile.soundcloudUrl,
        venuesAndEvents: profile.venuesAndEvents,
      );
      await _datasource.createDjProfile(model.toJson());
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<void> updateDjProfile(DjProfile profile) async {
    try {
      final model = DjProfileModel(
        id: profile.id,
        fullName: profile.fullName,
        companyOrDjName: profile.companyOrDjName,
        phone: profile.phone,
        aboutYou: profile.aboutYou,
        pricePerExtraHour: profile.pricePerExtraHour,
        regions: profile.regions,
        genres: profile.genres,
        canPlayWithSax: profile.canPlayWithSax,
        allowPublicDjProfile: profile.allowPublicDjProfile,
        soundcloudUrl: profile.soundcloudUrl,
        venuesAndEvents: profile.venuesAndEvents,
      );
      await _datasource.updateDjProfile(model.toJson());
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  // ── Musician Profile ──

  @override
  Future<MusicianProfile> fetchMusicianProfile(String userId) async {
    try {
      final data = await _datasource.fetchMusicianProfile(userId);
      return MusicianProfileModel.fromJson(data).toEntity();
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<void> createMusicianProfile({
    required MusicianProfile profile,
    required String email,
  }) async {
    try {
      final model = MusicianProfileModel(
        id: profile.id,
        fullName: profile.fullName,
        phone: profile.phone,
        instrument: profile.instrument,
        hourlyRate: profile.hourlyRate,
        minimumBookingRate: profile.minimumBookingRate,
        regions: profile.regions,
        aboutText: profile.aboutText,
        experienceYears: profile.experienceYears,
        genres: profile.genres,
        djSaxCollaboration: profile.djSaxCollaboration,
        venuesAndEvents: profile.venuesAndEvents,
      );
      final data = {...model.toJson(), 'email': email};
      await _datasource.createMusicianProfile(data);
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<void> updateMusicianProfile(MusicianProfile profile) async {
    try {
      final model = MusicianProfileModel(
        id: profile.id,
        fullName: profile.fullName,
        phone: profile.phone,
        instrument: profile.instrument,
        hourlyRate: profile.hourlyRate,
        minimumBookingRate: profile.minimumBookingRate,
        regions: profile.regions,
        aboutText: profile.aboutText,
        experienceYears: profile.experienceYears,
        genres: profile.genres,
        djSaxCollaboration: profile.djSaxCollaboration,
        venuesAndEvents: profile.venuesAndEvents,
      );
      await _datasource.updateMusicianProfile(model.toJson());
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  // ── Payment ──

  @override
  Future<PaymentInfo?> fetchPaymentInfo({
    required String userId,
    required bool isDj,
  }) async {
    try {
      final data = await _datasource.fetchPaymentInfo(userId: userId, isDj: isDj);
      if (data == null) return null;
      return PaymentInfoModel.fromJson(data).toEntity();
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<void> upsertPaymentInfo({
    required String userId,
    required bool isDj,
    required PaymentInfo info,
  }) async {
    try {
      await _datasource.upsertPaymentInfo(
        userId: userId,
        isDj: isDj,
        data: {
          'payment': info.payment.toDbString(),
          'cpr': info.cpr,
          'registration_number': info.registrationNumber,
          'account_number': info.accountNumber,
          'street': info.street,
          'city_postal_code': info.cityPostalCode,
        },
      );
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  // ── DJ Job Filters ──

  @override
  Future<DjJobFilters?> fetchDjJobFilters(String userId) async {
    try {
      final data = await _datasource.fetchDjJobFilters(userId);
      if (data == null) return null;
      return DjJobFiltersModel.fromJson(data).toEntity();
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<void> saveDjJobFilters(DjJobFilters filters) async {
    try {
      await _datasource.saveDjJobFilters(DjJobFiltersModel.fromEntity(filters).toJson());
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  // ── Reviews ──

  @override
  Future<List<Review>> fetchReviews({
    required String userId,
    required bool isDj,
  }) async {
    try {
      final data = await _datasource.fetchReviews(userId: userId, isDj: isDj);
      return data.map((r) => ReviewModel.fromJson(r).toEntity()).toList();
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<Review> createReview({
    required String userId,
    required bool isDj,
    required String customerName,
    required int rating,
    required String review,
    required String eventType,
    required String eventDate,
  }) async {
    try {
      final data = await _datasource.createReview(
        userId: userId,
        isDj: isDj,
        data: {
          'customer_name': customerName,
          'rating': rating,
          'review': review,
          'event_type': eventType,
          'event_date': eventDate,
        },
      );
      return ReviewModel.fromJson(data).toEntity();
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<void> updateReview({
    required String reviewId,
    required String customerName,
    required int rating,
    required String review,
    required String eventType,
    required String eventDate,
  }) async {
    try {
      await _datasource.updateReview(
        reviewId: reviewId,
        data: {
          'customer_name': customerName,
          'rating': rating,
          'review': review,
          'event_type': eventType,
          'event_date': eventDate,
        },
      );
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    try {
      await _datasource.deleteReview(reviewId);
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  // ── User Files ──

  @override
  Future<List<UserFile>> fetchUserFiles(String userId) async {
    try {
      final data = await _datasource.fetchUserFiles(userId);
      return data.map((f) => UserFileModel.fromJson(f).toEntity()).toList();
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<UserFile> uploadFile({
    required String userId,
    required String filePath,
    required UserFileType type,
  }) async {
    try {
      final data = await _datasource.uploadFile(
        userId: userId,
        filePath: filePath,
        type: type,
      );
      return UserFileModel.fromJson(data).toEntity();
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<void> deleteFile(int fileId) async {
    try {
      await _datasource.deleteFile(fileId);
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  // ── Standard Messages ──

  @override
  Future<List<StandardMessage>> fetchStandardMessages(String userId) async {
    try {
      final data = await _datasource.fetchStandardMessages(userId);
      return data
          .map((m) => StandardMessageModel.fromJson(m).toEntity())
          .toList();
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<StandardMessage> createStandardMessage({
    required String userId,
    required String messageText,
    required String eventType,
  }) async {
    try {
      final data = await _datasource.createStandardMessage(
        userId: userId,
        data: {
          'message_text': messageText,
          'event_type': eventType,
        },
      );
      return StandardMessageModel.fromJson(data).toEntity();
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<void> updateStandardMessage({
    required int messageId,
    required String messageText,
    required String eventType,
  }) async {
    try {
      await _datasource.updateStandardMessage(
        messageId: messageId,
        data: {
          'message_text': messageText,
          'event_type': eventType,
        },
      );
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<void> deleteStandardMessage(int messageId) async {
    try {
      await _datasource.deleteStandardMessage(messageId);
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<List<AdminMessage>> fetchAdminMessages({
    required String userId,
    required bool isDj,
  }) async {
    try {
      final data = await _datasource.fetchAdminMessages(
        userId: userId,
        isDj: isDj,
      );
      return data.map((row) {
        final reads = row['AdminMessageReads'] as List<dynamic>? ?? [];
        final isRead = isDj
            ? reads.any((r) => r['djId'] == userId)
            : reads.any((r) => r['musicianId'] == userId);
        return AdminMessage(
          id: (row['id'] as num).toInt(),
          header: row['header'] as String,
          content: row['content'] as String,
          createdAt: DateTime.parse(row['createdAt'] as String),
          isRead: isRead,
        );
      }).toList();
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<void> markAdminMessageRead({
    required int messageId,
    required String userId,
    required bool isDj,
  }) async {
    try {
      await _datasource.markAdminMessageRead(
        messageId: messageId,
        userId: userId,
        isDj: isDj,
      );
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<String?> fetchIcalToken({
    required String userId,
    required bool isDj,
  }) async {
    try {
      return await _datasource.fetchIcalToken(userId: userId, isDj: isDj);
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<String> generateIcalToken({
    required String userId,
    required bool isDj,
  }) async {
    try {
      return await _datasource.generateIcalToken(userId: userId, isDj: isDj);
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }
}
