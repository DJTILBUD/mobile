import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/dj_quote.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/service_offer.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/ext_job.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/song_request.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/venue_photo.dart';
import 'package:dj_tilbud_app/features/jobs/domain/dj_bid_status.dart';

abstract class JobsRepository {
  /// Fetches all open jobs for a DJ (not filtered by region — only job filters apply).
  Future<List<Job>> fetchNewDjJobs(String userId);

  /// Fetches all quotes submitted by this DJ.
  Future<List<DjQuote>> fetchDjQuotes(String userId);

  /// Fetches ext jobs (Udvalgte jobs) assigned to this DJ.
  Future<List<ExtJob>> fetchDjExtJobs(String userId);

  /// Recurring-customer (venue) names for the DJ's assigned ext jobs, keyed by
  /// ext job id (resolved server-side; a miss means "not a fixed customer").
  Future<Map<int, String>> fetchDjExtJobRecurringNames(String userId);

  /// Venue photos (with the team's comment each) for the DJ's assigned ext
  /// jobs, keyed by ext job id. Only partner (recurring) venues have any.
  Future<Map<int, List<VenuePhoto>>> fetchDjExtJobVenuePhotos(String userId);

  /// Recurring-customer (venue) names for the current MUSICIAN's won/assigned
  /// ext jobs, keyed by ext job id (the sax counterpart, resolved server-side).
  Future<Map<int, String>> fetchMusicianExtJobRecurringNames();

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

  /// Sets a planned contact date on a regular job (YYYY-MM-DD).
  Future<void> setJobPlannedContact(int jobId, String date);

  /// Marks an ext job as customer-contacted (DJ ext job flow).
  Future<void> markExtJobCustomerContacted(int extJobId);

  /// Sets a planned contact date on an ext job (YYYY-MM-DD).
  Future<void> setExtJobPlannedContact(int extJobId, String date);

  /// Marks a service offer as customer-contacted (instrumentalist flow).
  Future<void> markServiceOfferCustomerContacted(int offerId);

  /// Sets a planned contact date on a service offer (YYYY-MM-DD).
  Future<void> setServiceOfferPlannedContact(int offerId, String date);

  /// Fetches first_invoice_paid for a job or ext job invoice.
  /// Pass exactly one of [jobId] or [extJobId].
  Future<bool?> fetchInvoiceStatus({int? jobId, int? extJobId});

  /// The customer's precise event address (provided after booking), readable
  /// only by the winning DJ/musician. Returns null when none/unauthorized.
  /// Pass exactly one of [jobId] or [extJobId].
  Future<String?> fetchEventAddress({int? jobId, int? extJobId});

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
  /// [newTotalPrice] is the expected base + extra-hours total; the server re-validates it.
  Future<void> addExtraHours(
    int quoteId, {
    required double extraHours,
    required num pricePerHour,
    required int newTotalPrice,
  });

  /// Removes extra hours from a won DJ quote.
  Future<void> deleteExtraHours(int quoteId);

  /// Adds or updates extra hours on an ext job the DJ is assigned to.
  /// [newTotalPrice] is the expected new full_amount; the server re-validates it.
  Future<void> addExtJobExtraHours(
    int extJobId, {
    required double extraHours,
    required num pricePerHour,
    required int newTotalPrice,
  });

  /// Removes extra hours from an ext job.
  Future<void> deleteExtJobExtraHours(int extJobId);

  /// "Jeg spillede ikke ekstra timer" — records that the performer had no extra
  /// hours on this job, which hides the extra-hours card and stops the daily
  /// `extra_hours_reminder` push for them. Pass `declined: false` to undo.
  /// One method per payee row: quote (DJ internal), ext job (DJ external),
  /// service offer (musician).
  Future<void> setQuoteExtraHoursDeclined(
    int quoteId, {
    required bool declined,
  });
  Future<void> setExtJobExtraHoursDeclined(
    int extJobId, {
    required bool declined,
  });
  Future<void> setServiceOfferExtraHoursDeclined(
    int offerId, {
    required bool declined,
  });

  /// Sets the agreed early-setup fee (+ optional HH:MM time) on an ext job.
  /// The fee is folded into full_amount + honorar server-side.
  Future<void> setExtJobEarlySetup(
    int extJobId, {
    required num price,
    String? time,
  });

  /// Removes early setup from an ext job.
  Future<void> deleteExtJobEarlySetup(int extJobId);

  /// Saves private DJ notes on a won quote.
  Future<void> saveDjNotes(int quoteId, String notes);

  /// Returns true if the musician already has a WON offer that time-conflicts with the target
  /// booking (same date, gap < 3h). Open offers do not block; see [saxBookingsConflict].
  Future<bool> hasDateConflict(
    String userId, {
    required DateTime date,
    String? startTime,
    String? endTime,
  });

  /// Every ServiceOffers row on one job, for the musician availability rule. Returns an empty
  /// list on failure (the server rejection stays the real gate).
  Future<List<({String? musicianId, String? status})>> fetchOffersForJob({
    int? jobId,
    int? extJobId,
  });

  /// The ext job ids currently visible to this musician whose account is a TRUE
  /// partner-portal account (`is_partner = true`). Used to hide those jobs from
  /// the self-serve feed and to block them on the offer-form deep-link path (see
  /// [MusicianJobAvailability]). Fails OPEN to an empty set.
  Future<Set<int>> fetchPartnerExtJobIds();

  /// Has this job's supply/matching wave opened for the current DJ?
  ///
  /// Display aid for the quote form only (the feed is already gated server-side, and the real
  /// gate is the 403 from the quote route). Fails OPEN on any error.
  Future<bool> fetchJobWaveOpen(int jobId);

  /// Can the current DJ still place a quote on this job (status, cap, tier quota, own quote)?
  ///
  /// Server-resolved; display aid for the quote form only. Fails OPEN on any error.
  Future<DjBidStatus> fetchDjBidStatus(int jobId);

  /// Fetches service offers for a given internal job (for DJ view).
  Future<List<ServiceOffer>> fetchServiceOffersForJob(int jobId);

  /// Ext-job counterpart of [fetchServiceOffersForJob] (assigned-DJ view).
  Future<List<ServiceOffer>> fetchServiceOffersForExtJob(int extJobId);

  /// Fetches song requests submitted by guests for a given job.
  Future<List<SongRequest>> fetchSongRequestsForJob(int jobId);

  /// Fetches song requests submitted by guests for a given ext job.
  Future<List<SongRequest>> fetchSongRequestsForExtJob(int extJobId);

  /// Fetches the won DJ's name, phone, and user ID for an internal job (for musician view).
  /// Returns null if no won quote exists yet.
  Future<({String djId, String fullName, String? phone})?> fetchWonDjInfoForJob(
    int jobId,
  );

  /// Fetches the profile image URL for any user from UserFiles.
  /// Returns null if no profile image has been uploaded.
  Future<String?> fetchProfileImageUrl(String userId);

  /// Adds or updates extra hours on a won musician service offer.
  Future<void> addMusicianExtraHours(int offerId, {required double extraHours});

  Future<void> setSpecialRequestFee(
    int offerId, {
    required int feeDkk,
    required String reason,
  });

  Future<void> removeSpecialRequestFee(int offerId);

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
