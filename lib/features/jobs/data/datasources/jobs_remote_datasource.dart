import 'package:supabase_flutter/supabase_flutter.dart';

class JobsRemoteDatasource {
  JobsRemoteDatasource(this._client);

  final SupabaseClient _client;

  /// Fetches open jobs for a DJ.
  /// Region filtering is NOT applied here — it is handled client-side via
  /// DjJobFilters (excluded_regions) to match the web app's filtering logic.
  Future<List<Map<String, dynamic>>> fetchNewDjJobs(String userId) async {
    final quotedRows = await _client
        .from('Quotes')
        .select('job_id')
        .eq('dj_id', userId);
    final quotedJobIds =
        quotedRows.map((r) => (r['job_id'] as num).toInt()).toSet();

    final rejectedRows = await _client
        .from('DjJobRejections')
        .select('job_id')
        .eq('dj_id', userId);
    final rejectedJobIds = rejectedRows
        .where((r) => r['job_id'] != null)
        .map((r) => (r['job_id'] as num).toInt())
        .toSet();

    final excludedIds = quotedJobIds.union(rejectedJobIds);

    final jobs = await _client
        .from('Jobs')
        .select()
        .inFilter('status', ['open', 'another_round'])
        .order('created_at', ascending: false);

    return jobs
        .where((j) => !excludedIds.contains((j['id'] as num).toInt()))
        .toList();
  }

  /// Fetches all quotes by this DJ, with joined Job data.
  Future<List<Map<String, dynamic>>> fetchDjQuotes(String userId) async {
    return _client
        .from('Quotes')
        .select('*, job:Jobs(*)')
        .eq('dj_id', userId)
        .order('created_at', ascending: false);
  }

  /// Fetches ext jobs (Udvalgte jobs) directly assigned to this DJ.
  /// Matches web app: statuses closed/customer_contacted/ready_for_billing,
  /// sorted most recent date first.
  Future<List<Map<String, dynamic>>> fetchDjExtJobs(String userId) async {
    return _client
        .from('ExtJobs')
        .select()
        .eq('assigned_dj_id', userId)
        .inFilter('status', ['closed', 'customer_contacted', 'ready_for_billing'])
        .order('date', ascending: false);
  }

  /// Fetches open jobs available for an instrumentalist.
  Future<List<Map<String, dynamic>>> fetchNewInstrumentalistJobs(
      String userId) async {
    final musicianInfo = await _client
        .from('Musicians')
        .select('regions')
        .eq('id', userId)
        .single();
    final regions = (musicianInfo['regions'] as List<dynamic>).cast<String>();

    if (regions.isEmpty) return [];

    final offeredRows = await _client
        .from('ServiceOffers')
        .select('job_id')
        .eq('musician_id', userId)
        .not('job_id', 'is', null);
    final offeredJobIds = offeredRows
        .where((r) => r['job_id'] != null)
        .map((r) => (r['job_id'] as num).toInt())
        .toSet();

    final jobs = await _client
        .from('Jobs')
        .select()
        .inFilter('status', ['open', 'another_round', 'sent'])
        .inFilter('region', regions)
        .eq('requested_saxophonist', true)
        .order('date', ascending: true);

    return jobs
        .where((j) => !offeredJobIds.contains((j['id'] as num).toInt()))
        .toList();
  }

  /// Fetches ext jobs available for this instrumentalist to bid on.
  /// Matches web app useExtJobsForMusicians:
  /// - Unassigned (assigned_musician_id IS NULL)
  /// - Role type requires a musician (musician_only or dj_and_musician)
  /// - Statuses open/sent/closed/customer_contacted
  /// - Excludes jobs this musician already offered on
  /// - Excludes jobs already won by another musician
  Future<List<Map<String, dynamic>>> fetchInstrumentalistExtJobs(
      String userId) async {
    // Jobs this musician already has an offer on (will appear in their offers lane)
    final myOffersRows = await _client
        .from('ServiceOffers')
        .select('ext_job_id')
        .eq('musician_id', userId)
        .not('ext_job_id', 'is', null);
    final offeredExtJobIds = myOffersRows
        .where((r) => r['ext_job_id'] != null)
        .map((r) => (r['ext_job_id'] as num).toInt())
        .toSet();

    // Jobs already won by any musician (hide from new-jobs feed)
    final wonRows = await _client
        .from('ServiceOffers')
        .select('ext_job_id')
        .not('ext_job_id', 'is', null)
        .eq('status', 'won');
    final wonExtJobIds = wonRows
        .where((r) => r['ext_job_id'] != null)
        .map((r) => (r['ext_job_id'] as num).toInt())
        .toSet();

    final extJobs = await _client
        .from('ExtJobs')
        .select()
        .isFilter('assigned_musician_id', null)
        .inFilter('role_type', ['musician_only', 'dj_and_musician'])
        .inFilter('status', ['open', 'sent', 'closed', 'customer_contacted'])
        .order('created_at', ascending: false);

    return extJobs.where((j) {
      final id = (j['id'] as num).toInt();
      return !offeredExtJobIds.contains(id) && !wonExtJobIds.contains(id);
    }).toList();
  }

  /// Fetches all service offers by this musician (both regular and ext jobs).
  Future<List<Map<String, dynamic>>> fetchServiceOffers(
      String userId) async {
    return _client
        .from('ServiceOffers')
        .select(
            '*, job:Jobs!ServiceOffers_job_id_fkey(*), ext_job:ExtJobs!ServiceOffers_ext_job_id_fkey(*)')
        .eq('musician_id', userId)
        .order('created_at', ascending: false);
  }

  /// Creates a DJ quote.
  Future<Map<String, dynamic>> createDjQuote({
    required String djId,
    required int jobId,
    required int priceDkk,
    required String equipmentDescription,
    required String salesPitch,
    String? earlySetupStatus,
    int? earlySetupPrice,
  }) async {
    final payload = <String, dynamic>{
      'dj_id': djId,
      'job_id': jobId,
      'price_dkk': priceDkk,
      'equipment_description': equipmentDescription,
      'sales_pitch': salesPitch,
      'status': 'pending',
    };
    if (earlySetupStatus != null) {
      payload['early_setup_status'] = earlySetupStatus;
    }
    if (earlySetupPrice != null) {
      payload['early_setup_price'] = earlySetupPrice;
    }
    return _client
        .from('Quotes')
        .insert(payload)
        .select('*, job:Jobs(*)')
        .single();
  }

  /// Rejects a job for the DJ, optionally recording the reasons.
  Future<void> rejectDjJob({
    required String djId,
    required int jobId,
    List<String> reasons = const [],
  }) async {
    await _client.from('DjJobRejections').insert({
      'dj_id': djId,
      'job_id': jobId,
      'reason': reasons,
    });
  }

  /// Creates an instrumentalist service offer.
  Future<Map<String, dynamic>> createServiceOffer({
    required String musicianId,
    int? jobId,
    int? extJobId,
    required int priceDkk,
    required int musicianPayoutDkk,
    required String salesPitch,
    required String instrument,
  }) async {
    final payload = {
      'musician_id': musicianId,
      'price_dkk': priceDkk,
      'musician_payout_dkk': musicianPayoutDkk,
      'sales_pitch': salesPitch,
      'instrument': instrument,
      'status': 'sent',
    };
    if (jobId != null) payload['job_id'] = jobId;
    if (extJobId != null) payload['ext_job_id'] = extJobId;

    // Select with both possible joins so ServiceOfferModel can parse correctly.
    return _client
        .from('ServiceOffers')
        .insert(payload)
        .select(
            '*, job:Jobs!ServiceOffers_job_id_fkey(*), ext_job:ExtJobs!ServiceOffers_ext_job_id_fkey(*)')
        .single();
  }

  /// Fetches a single job with full details.
  Future<Map<String, dynamic>> fetchJobDetail(int jobId) async {
    return _client.from('Jobs').select().eq('id', jobId).single();
  }

  /// Updates Jobs.status = 'customer_contacted'.
  Future<void> markJobCustomerContacted(int jobId) async {
    await _client
        .from('Jobs')
        .update({'status': 'customer_contacted'})
        .eq('id', jobId);
  }

  /// Updates ExtJobs.status = 'customer_contacted'.
  Future<void> markExtJobCustomerContacted(int extJobId) async {
    await _client
        .from('ExtJobs')
        .update({'status': 'customer_contacted'})
        .eq('id', extJobId);
  }

  /// Updates ServiceOffers.customer_contacted = true.
  Future<void> markServiceOfferCustomerContacted(int offerId) async {
    await _client
        .from('ServiceOffers')
        .update({'customer_contacted': true})
        .eq('id', offerId);
  }

  /// Marks a regular job as ready for billing.
  Future<void> markJobReadyForBilling(int jobId) async {
    await _client
        .from('Jobs')
        .update({'status': 'ready_for_billing'})
        .eq('id', jobId);
  }

  /// Marks an ext job as ready for billing.
  Future<void> markExtJobReadyForBilling(int extJobId) async {
    await _client
        .from('ExtJobs')
        .update({'status': 'ready_for_billing'})
        .eq('id', extJobId);
  }

  /// Resolves the early setup status on a quote ('accepted' or 'rejected').
  Future<void> resolveEarlySetup(int quoteId, {required bool accepted}) async {
    await _client
        .from('Quotes')
        .update({'early_setup_status': accepted ? 'accepted' : 'rejected'})
        .eq('id', quoteId);
  }

  /// Confirms the DJ is ready for an internal job quote.
  Future<void> confirmDjReady(int quoteId) async {
    await _client
        .from('Quotes')
        .update({'dj_ready_confirmed_at': DateTime.now().toIso8601String()})
        .eq('id', quoteId);
  }

  /// Confirms the DJ is ready for an ext job.
  Future<void> confirmExtJobDjReady(int extJobId) async {
    await _client
        .from('ExtJobs')
        .update({'dj_ready_confirmed_at': DateTime.now().toIso8601String()})
        .eq('id', extJobId);
  }

  /// Confirms the musician is ready for their service offer.
  Future<void> confirmMusicianReady(int offerId) async {
    await _client
        .from('ServiceOffers')
        .update({'musician_ready_confirmed_at': DateTime.now().toIso8601String()})
        .eq('id', offerId);
  }

  /// Adds / updates extra hours on a won DJ quote.
  Future<void> addExtraHours(int quoteId, {required double extraHours, required int pricePerHour}) async {
    await _client.from('Quotes').update({
      'extra_hours': extraHours,
      'extra_hours_price_per_hour': pricePerHour,
    }).eq('id', quoteId);
  }

  /// Clears extra hours from a won DJ quote.
  Future<void> deleteExtraHours(int quoteId) async {
    await _client.from('Quotes').update({
      'extra_hours': null,
      'extra_hours_price_per_hour': null,
    }).eq('id', quoteId);
  }

  /// Saves private DJ notes on a quote.
  Future<void> saveDjNotes(int quoteId, String notes) async {
    final userId = _client.auth.currentUser!.id;
    await _client
        .from('Quotes')
        .update({'dj_notes': notes})
        .eq('id', quoteId)
        .eq('dj_id', userId);
  }

  /// Edits a pending DJ quote within the 10-minute edit window.
  Future<Map<String, dynamic>> editDjQuote({
    required int quoteId,
    required int priceDkk,
    required String equipmentDescription,
    required String salesPitch,
    String? earlySetupStatus,
    int? earlySetupPrice,
  }) async {
    final payload = <String, dynamic>{
      'price_dkk': priceDkk,
      'equipment_description': equipmentDescription,
      'sales_pitch': salesPitch,
    };
    // Passing null clears the early setup — only include if explicitly set
    if (earlySetupStatus != null) {
      payload['early_setup_status'] = earlySetupStatus;
      payload['early_setup_price'] = earlySetupPrice;
    }
    return _client
        .from('Quotes')
        .update(payload)
        .eq('id', quoteId)
        .select('*, job:Jobs(*)')
        .single();
  }

  /// Returns true if the musician already has an active (sent or won) offer
  /// on the same calendar date as [date].
  Future<bool> hasDateConflict(String userId, DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10);

    // Check internal jobs
    final internalRows = await _client
        .from('ServiceOffers')
        .select('id, job:Jobs(date)')
        .eq('musician_id', userId)
        .inFilter('status', ['sent', 'won']);

    for (final row in internalRows) {
      final job = row['job'] as Map<String, dynamic>?;
      if (job == null) continue;
      final jobDate = (job['date'] as String?)?.substring(0, 10);
      if (jobDate == dateStr) return true;
    }

    // Check external jobs
    final extRows = await _client
        .from('ServiceOffers')
        .select('id, ext_job:ExtJobs(date)')
        .eq('musician_id', userId)
        .inFilter('status', ['sent', 'won'])
        .not('ext_job_id', 'is', null);

    for (final row in extRows) {
      final extJob = row['ext_job'] as Map<String, dynamic>?;
      if (extJob == null) continue;
      final jobDate = (extJob['date'] as String?)?.substring(0, 10);
      if (jobDate == dateStr) return true;
    }

    return false;
  }

  /// Fetches service offers for a given internal job (for DJ view).
  /// Joins Musicians so the DJ can see contact info for won offers.
  Future<List<Map<String, dynamic>>> fetchServiceOffersForJob(int jobId) async {
    return _client
        .from('ServiceOffers')
        .select('id, musician_id, price_dkk, musician_payout_dkk, instrument, status, sales_pitch, created_at, musician:Musicians(full_name, phone, email)')
        .eq('job_id', jobId)
        .inFilter('status', ['sent', 'won', 'lost'])
        .order('created_at', ascending: false);
  }

  /// Fetches the won DJ quote (with DJ contact info) for an internal job.
  /// Used by musicians to see who the DJ is on a job they won.
  Future<Map<String, dynamic>?> fetchWonDjInfoForJob(int jobId) async {
    final rows = await _client
        .from('Quotes')
        .select('dj_id, dj:DjInfos(full_name, phone)')
        .eq('job_id', jobId)
        .eq('status', 'won')
        .limit(1);
    return rows.isNotEmpty ? rows.first : null;
  }

  /// Fetches the profile image URL for any user from UserFiles (type = 'profile').
  Future<String?> fetchProfileImageUrl(String userId) async {
    final rows = await _client
        .from('UserFiles')
        .select('url')
        .eq('user_id', userId)
        .eq('type', 'profile')
        .limit(1);
    if (rows.isEmpty) return null;
    return rows.first['url'] as String?;
  }

  /// Adds / updates extra hours on a won musician service offer.
  Future<void> addMusicianExtraHours(int offerId, {required double extraHours}) async {
    final userId = _client.auth.currentUser!.id;
    await _client
        .from('ServiceOffers')
        .update({'extra_hours': extraHours})
        .eq('id', offerId)
        .eq('musician_id', userId);
  }

  /// Saves private musician notes on a service offer.
  Future<void> saveMusicianNotes(int offerId, String notes) async {
    final userId = _client.auth.currentUser!.id;
    await _client
        .from('ServiceOffers')
        .update({'musician_notes': notes})
        .eq('id', offerId)
        .eq('musician_id', userId);
  }

  /// Fetches first_invoice_paid from the Invoicing table via Edge Function.
  /// The Edge Function uses service role to bypass admin-only RLS.
  /// Pass exactly one of [jobId] or [extJobId].
  Future<bool?> fetchInvoiceStatus({int? jobId, int? extJobId}) async {
    final body = <String, dynamic>{};
    if (jobId != null) body['jobId'] = jobId;
    if (extJobId != null) body['extJobId'] = extJobId;

    final response = await _client.functions.invoke(
      'invoice-status',
      body: body,
    );

    if (response.data == null) return null;
    final map = response.data as Map<String, dynamic>;
    return map['first_invoice_paid'] as bool?;
  }
}
