import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/dj_quote.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/service_offer.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/ext_job.dart';

abstract class JobsRepository {
  /// Fetches all open jobs for a DJ (not filtered by region — only job filters apply).
  Future<List<Job>> fetchNewDjJobs(String userId);

  /// Fetches all quotes submitted by this DJ.
  Future<List<DjQuote>> fetchDjQuotes(String userId);

  /// Fetches ext jobs (Udvalgte jobs) assigned to this DJ.
  Future<List<ExtJob>> fetchDjExtJobs(String userId);

  /// Fetches open jobs available for an instrumentalist.
  Future<List<Job>> fetchNewInstrumentalistJobs(String userId);

  /// Fetches ext jobs assigned to this instrumentalist (mapped to Job for
  /// display in the same feed).
  Future<List<Job>> fetchInstrumentalistExtJobs(String userId);

  /// Fetches all service offers submitted by this instrumentalist.
  Future<List<ServiceOffer>> fetchServiceOffers(String userId);

  /// Creates a DJ quote for a job.
  Future<DjQuote> createDjQuote({
    required String userId,
    required int jobId,
    required int priceDkk,
    required String equipmentDescription,
    required String salesPitch,
    String? earlySetupStatus,
    int? earlySetupPrice,
  });

  /// Rejects a job for the current DJ, optionally recording the reasons.
  Future<void> rejectDjJob({
    required String userId,
    required int jobId,
    List<String> reasons = const [],
  });

  /// Creates an instrumentalist service offer.
  /// Exactly one of [jobId] or [extJobId] must be provided.
  Future<ServiceOffer> createServiceOffer({
    required String userId,
    int? jobId,
    int? extJobId,
    required int priceDkk,
    required int musicianPayoutDkk,
    required String salesPitch,
    required String instrument,
  });

  /// Fetches a single job with full details (including lead contact info).
  Future<Job> fetchJobDetail(int jobId);

  /// Marks a regular job as customer-contacted (DJ flow).
  Future<void> markJobCustomerContacted(int jobId);

  /// Marks an ext job as customer-contacted (DJ ext job flow).
  Future<void> markExtJobCustomerContacted(int extJobId);

  /// Marks a service offer as customer-contacted (instrumentalist flow).
  Future<void> markServiceOfferCustomerContacted(int offerId);

  /// Fetches first_invoice_paid for a job or ext job invoice.
  /// Pass exactly one of [jobId] or [extJobId].
  Future<bool?> fetchInvoiceStatus({int? jobId, int? extJobId});

  /// Marks a regular job as ready for billing (DJ flow, step 2).
  Future<void> markJobReadyForBilling(int jobId);

  /// Marks an ext job as ready for billing (DJ ext job flow, step 2).
  Future<void> markExtJobReadyForBilling(int extJobId);

  /// Resolves whether the customer accepted the early setup option.
  /// Updates Quotes.early_setup_status to 'accepted' or 'rejected'.
  Future<void> resolveEarlySetup(int quoteId, {required bool accepted});

  /// Confirms the DJ is ready (sets Quotes.dj_ready_confirmed_at).
  Future<void> confirmDjReady(int quoteId);

  /// Confirms the DJ is ready for an ext job (sets ExtJobs.dj_ready_confirmed_at).
  Future<void> confirmExtJobDjReady(int extJobId);

  /// Confirms the musician is ready (sets ServiceOffers.musician_ready_confirmed_at).
  Future<void> confirmMusicianReady(int offerId);

  /// Adds or updates extra hours on a won DJ quote (within 2-day post-event window).
  Future<void> addExtraHours(int quoteId, {required double extraHours, required int pricePerHour});

  /// Removes extra hours from a won DJ quote.
  Future<void> deleteExtraHours(int quoteId);

  /// Saves private DJ notes on a won quote.
  Future<void> saveDjNotes(int quoteId, String notes);

  /// Returns true if the musician already has an active service offer on [date].
  Future<bool> hasDateConflict(String userId, DateTime date);

  /// Fetches service offers for a given internal job (for DJ view).
  Future<List<ServiceOffer>> fetchServiceOffersForJob(int jobId);

  /// Fetches the won DJ's name, phone, and user ID for an internal job (for musician view).
  /// Returns null if no won quote exists yet.
  Future<({String djId, String fullName, String? phone})?> fetchWonDjInfoForJob(int jobId);

  /// Fetches the profile image URL for any user from UserFiles.
  /// Returns null if no profile image has been uploaded.
  Future<String?> fetchProfileImageUrl(String userId);

  /// Adds or updates extra hours on a won musician service offer.
  Future<void> addMusicianExtraHours(int offerId, {required double extraHours});

  /// Saves private musician notes on a won service offer.
  Future<void> saveMusicianNotes(int offerId, String notes);

  /// Edits a pending DJ quote within the 10-minute edit window.
  Future<DjQuote> editDjQuote({
    required int quoteId,
    required int priceDkk,
    required String equipmentDescription,
    required String salesPitch,
    String? earlySetupStatus,
    int? earlySetupPrice,
  });
}
