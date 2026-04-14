import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:dj_tilbud_app/core/error/app_exception.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/dj_quote.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/service_offer.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/ext_job.dart';
import 'package:dj_tilbud_app/features/jobs/domain/repositories/jobs_repository.dart';
import 'package:dj_tilbud_app/features/jobs/data/datasources/jobs_remote_datasource.dart';
import 'package:dj_tilbud_app/features/jobs/data/models/job_model.dart';
import 'package:dj_tilbud_app/features/jobs/data/models/dj_quote_model.dart';
import 'package:dj_tilbud_app/features/jobs/data/models/service_offer_model.dart';
import 'package:dj_tilbud_app/features/jobs/data/models/ext_job_model.dart';

class JobsRepositoryImpl implements JobsRepository {
  JobsRepositoryImpl(this._datasource);

  final JobsRemoteDatasource _datasource;

  @override
  Future<List<Job>> fetchNewDjJobs(String userId) async {
    try {
      final data = await _datasource.fetchNewDjJobs(userId);
      final jobs = <Job>[];
      for (final j in data) {
        try {
          jobs.add(JobModel.fromJson(j).toEntity());
        } catch (e) {
          debugPrint('JobModel.fromJson failed for row: $j\nError: $e');
          rethrow;
        }
      }
      return jobs;
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<List<DjQuote>> fetchDjQuotes(String userId) async {
    try {
      final data = await _datasource.fetchDjQuotes(userId);
      return data.map((j) => DjQuoteModel.fromJson(j).toEntity()).toList();
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<List<ExtJob>> fetchDjExtJobs(String userId) async {
    try {
      final data = await _datasource.fetchDjExtJobs(userId);
      return data.map((j) => ExtJobModel.fromJson(j).toEntity()).toList();
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<List<Job>> fetchNewInstrumentalistJobs(String userId) async {
    try {
      final data = await _datasource.fetchNewInstrumentalistJobs(userId);
      return data.map((j) => JobModel.fromJson(j).toEntity()).toList();
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<List<Job>> fetchInstrumentalistExtJobs(String userId) async {
    try {
      final data = await _datasource.fetchInstrumentalistExtJobs(userId);
      return data.map((j) => ExtJobModel.fromJson(j).toJobEntity()).toList();
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<List<ServiceOffer>> fetchServiceOffers(String userId) async {
    try {
      final data = await _datasource.fetchServiceOffers(userId);
      return data
          .map((j) => ServiceOfferModel.fromJson(j).toEntity())
          .toList();
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<DjQuote> createDjQuote({
    required String userId,
    required int jobId,
    required int priceDkk,
    required String equipmentDescription,
    required String salesPitch,
    String? earlySetupStatus,
    int? earlySetupPrice,
  }) async {
    try {
      final data = await _datasource.createDjQuote(
        djId: userId,
        jobId: jobId,
        priceDkk: priceDkk,
        equipmentDescription: equipmentDescription,
        salesPitch: salesPitch,
        earlySetupStatus: earlySetupStatus,
        earlySetupPrice: earlySetupPrice,
      );
      return DjQuoteModel.fromJson(data).toEntity();
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<void> rejectDjJob({
    required String userId,
    required int jobId,
    List<String> reasons = const [],
  }) async {
    try {
      await _datasource.rejectDjJob(djId: userId, jobId: jobId, reasons: reasons);
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<ServiceOffer> createServiceOffer({
    required String userId,
    int? jobId,
    int? extJobId,
    required int priceDkk,
    required int musicianPayoutDkk,
    required String salesPitch,
    required String instrument,
  }) async {
    try {
      final data = await _datasource.createServiceOffer(
        musicianId: userId,
        jobId: jobId,
        extJobId: extJobId,
        priceDkk: priceDkk,
        musicianPayoutDkk: musicianPayoutDkk,
        salesPitch: salesPitch,
        instrument: instrument,
      );
      return ServiceOfferModel.fromJson(data).toEntity();
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<Job> fetchJobDetail(int jobId) async {
    try {
      final data = await _datasource.fetchJobDetail(jobId);
      return JobModel.fromJson(data).toEntity();
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<void> markJobCustomerContacted(int jobId) async {
    try {
      await _datasource.markJobCustomerContacted(jobId);
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<void> markExtJobCustomerContacted(int extJobId) async {
    try {
      await _datasource.markExtJobCustomerContacted(extJobId);
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<void> markServiceOfferCustomerContacted(int offerId) async {
    try {
      await _datasource.markServiceOfferCustomerContacted(offerId);
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<bool?> fetchInvoiceStatus({int? jobId, int? extJobId}) async {
    try {
      return await _datasource.fetchInvoiceStatus(jobId: jobId, extJobId: extJobId);
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<void> markJobReadyForBilling(int jobId) async {
    try {
      await _datasource.markJobReadyForBilling(jobId);
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<void> markExtJobReadyForBilling(int extJobId) async {
    try {
      await _datasource.markExtJobReadyForBilling(extJobId);
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<void> resolveEarlySetup(int quoteId, {required bool accepted}) async {
    try {
      await _datasource.resolveEarlySetup(quoteId, accepted: accepted);
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<void> confirmDjReady(int quoteId) async {
    try {
      await _datasource.confirmDjReady(quoteId);
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<void> confirmExtJobDjReady(int extJobId) async {
    try {
      await _datasource.confirmExtJobDjReady(extJobId);
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<void> confirmMusicianReady(int offerId) async {
    try {
      await _datasource.confirmMusicianReady(offerId);
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<void> addExtraHours(int quoteId, {required double extraHours, required int pricePerHour}) async {
    try {
      await _datasource.addExtraHours(quoteId, extraHours: extraHours, pricePerHour: pricePerHour);
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<void> deleteExtraHours(int quoteId) async {
    try {
      await _datasource.deleteExtraHours(quoteId);
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  @override
  Future<void> saveDjNotes(int quoteId, String notes) async {
    try {
      await _datasource.saveDjNotes(quoteId, notes);
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<bool> hasDateConflict(String userId, DateTime date) async {
    try {
      return await _datasource.hasDateConflict(userId, date);
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<List<ServiceOffer>> fetchServiceOffersForJob(int jobId) async {
    try {
      final data = await _datasource.fetchServiceOffersForJob(jobId);
      // These rows have no joined job data — build a minimal ServiceOffer
      return data.map((row) {
        return ServiceOffer(
          id: (row['id'] as num).toInt(),
          musicianId: row['musician_id'] as String,
          priceDkk: (row['price_dkk'] as num?)?.toInt() ?? 0,
          instrument: row['instrument'] as String? ?? '',
          status: ServiceOfferStatus.fromString(row['status'] as String),
          createdAt: DateTime.parse(row['created_at'] as String),
          job: Job(
            id: 0,
            eventType: '',
            date: DateTime.now(),
            timeStart: '00:00',
            timeEnd: '00:00',
            city: '',
            region: '',
            guestsAmount: 0,
            status: JobStatus.open,
            createdAt: DateTime.now(),
          ),
          musicianPayoutDkk: (row['musician_payout_dkk'] as num?)?.toInt(),
          salesPitch: row['sales_pitch'] as String?,
          musicianFullName: (row['musician'] as Map<String, dynamic>?)?['full_name'] as String?,
          musicianPhone: (row['musician'] as Map<String, dynamic>?)?['phone'] as String?,
          musicianEmail: (row['musician'] as Map<String, dynamic>?)?['email'] as String?,
        );
      }).toList();
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<({String djId, String fullName, String? phone})?> fetchWonDjInfoForJob(int jobId) async {
    try {
      final row = await _datasource.fetchWonDjInfoForJob(jobId);
      if (row == null) return null;
      final dj = row['dj'] as Map<String, dynamic>?;
      if (dj == null) return null;
      return (
        djId: row['dj_id'] as String? ?? '',
        fullName: dj['full_name'] as String? ?? '',
        phone: dj['phone'] as String?,
      );
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<String?> fetchProfileImageUrl(String userId) async {
    try {
      return await _datasource.fetchProfileImageUrl(userId);
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<void> addMusicianExtraHours(int offerId, {required double extraHours}) async {
    try {
      await _datasource.addMusicianExtraHours(offerId, extraHours: extraHours);
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<void> saveMusicianNotes(int offerId, String notes) async {
    try {
      await _datasource.saveMusicianNotes(offerId, notes);
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<DjQuote> editDjQuote({
    required int quoteId,
    required int priceDkk,
    required String equipmentDescription,
    required String salesPitch,
    String? earlySetupStatus,
    int? earlySetupPrice,
  }) async {
    try {
      final data = await _datasource.editDjQuote(
        quoteId: quoteId,
        priceDkk: priceDkk,
        equipmentDescription: equipmentDescription,
        salesPitch: salesPitch,
        earlySetupStatus: earlySetupStatus,
        earlySetupPrice: earlySetupPrice,
      );
      return DjQuoteModel.fromJson(data).toEntity();
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }
}
