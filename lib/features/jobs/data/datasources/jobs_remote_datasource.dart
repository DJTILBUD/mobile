import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dj_tilbud_app/core/config/env_config.dart';
import 'package:dj_tilbud_app/core/error/app_exception.dart';

class JobsRemoteDatasource {
  JobsRemoteDatasource(this._client);

  final SupabaseClient _client;

  String get _webAppBaseUrl {
    String url = EnvConfig.webAppUrl;
    if (EnvConfig.isLocal && Platform.isAndroid) {
      url = url.replaceFirst('localhost', '10.0.2.2');
    }
    return url;
  }

  String get _accessToken {
    final token = _client.auth.currentSession?.accessToken;
    if (token == null) throw Exception('Not authenticated');
    return token;
  }

  Future<void> _webApiPut(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_webAppBaseUrl$path');
    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: body != null ? jsonEncode(body) : null,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DatabaseException(_extractMessage(response.body));
    }
  }

  Future<Map<String, dynamic>> _webApiPost(
      String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_webAppBaseUrl$path');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DatabaseException(_extractMessage(response.body));
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> _webApiPatch(String path) async {
    final uri = Uri.parse('$_webAppBaseUrl$path');
    final response = await http.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DatabaseException(_extractMessage(response.body));
    }
  }

  String _extractMessage(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['message'] as String? ?? body;
    } catch (_) {
      return body;
    }
  }

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

  /// Fetches jobs available for an instrumentalist to bid on.
  /// Mirrors web app useAvailableJobsForMusicians exactly:
  /// - Wide status filter (open/sent/re_sent/reopened/another_round/closed/customer_contacted)
  /// - requested_saxophonist = true, filtered to musician's regions
  /// - Excludes if this musician already has any offer (will be in their lanes)
  /// - Excludes if any musician has a WON offer
  /// - Excludes jobs within first 24 h where job region is not in musician's regions (regional window)
  /// - Marks has_active_offer when another musician has a non-lost offer
  Future<List<Map<String, dynamic>>> fetchNewInstrumentalistJobs(
      String userId) async {
    final musicianInfo = await _client
        .from('Musicians')
        .select('regions, instrument')
        .eq('id', userId)
        .single();
    final regions = (musicianInfo['regions'] as List<dynamic>).cast<String>();
    final instrument = musicianInfo['instrument'] as String? ?? 'saxophone';

    if (regions.isEmpty) return [];

    // Fetch all relevant jobs (wide status filter, matches web app)
    final jobs = await _client
        .from('Jobs')
        .select()
        .inFilter('status', [
          'open', 'sent', 're_sent', 'reopened',
          'another_round', 'closed', 'customer_contacted',
        ])
        .inFilter('region', regions)
        .eq('requested_saxophonist', true)
        .order('created_at', ascending: false);

    if (jobs.isEmpty) return [];

    // Fetch all service offers for these jobs in one query
    final allJobIds = jobs.map((j) => (j['id'] as num).toInt()).toList();
    final allOffers = await _client
        .from('ServiceOffers')
        .select('job_id, musician_id, status')
        .inFilter('job_id', allJobIds)
        .not('job_id', 'is', null);

    // Group by job_id
    final offersByJob = <int, List<Map<String, dynamic>>>{};
    for (final o in allOffers) {
      final jid = (o['job_id'] as num).toInt();
      (offersByJob[jid] ??= []).add(o);
    }

    final now = DateTime.now();
    const first24h = Duration(hours: 24);

    return jobs.where((j) {
      final id = (j['id'] as num).toInt();
      final jobOffers = offersByJob[id] ?? [];

      // Regional window: within first 24 h, only show to musicians in this region
      if (instrument == 'saxophone') {
        final createdAt = DateTime.tryParse(j['created_at'] as String? ?? '');
        if (createdAt != null && now.difference(createdAt) < first24h) {
          final jobRegion = j['region'] as String?;
          if (jobRegion != null && !regions.contains(jobRegion)) return false;
        }
      }

      // Exclude if this musician already has any offer on this job
      final hasMine = jobOffers.any((o) => o['musician_id'] == userId);
      if (hasMine) return false;

      // Exclude if any musician has won this job
      final hasWon = jobOffers.any((o) => o['status'] == 'won');
      if (hasWon) return false;

      return true;
    }).map((j) {
      final id = (j['id'] as num).toInt();
      final jobOffers = offersByJob[id] ?? [];
      final hasActiveOffer = jobOffers.any((o) => o['status'] != 'lost');
      return {...j, 'has_active_offer': hasActiveOffer};
    }).toList();
  }

  /// Fetches ext jobs available for this instrumentalist to bid on.
  /// Mirrors web app useExtJobsForMusicians exactly.
  Future<List<Map<String, dynamic>>> fetchInstrumentalistExtJobs(
      String userId) async {
    final musicianInfo = await _client
        .from('Musicians')
        .select('instrument, regions')
        .eq('id', userId)
        .single();
    final instrument = musicianInfo['instrument'] as String? ?? 'saxophone';
    final regions = (musicianInfo['regions'] as List<dynamic>).cast<String>();

    final extJobs = await _client
        .from('ExtJobs')
        .select()
        .isFilter('assigned_musician_id', null)
        .inFilter('role_type', ['musician_only', 'dj_and_musician'])
        .inFilter('status', ['open', 'sent', 'closed', 'customer_contacted'])
        .order('created_at', ascending: false);

    if (extJobs.isEmpty) return [];

    // Fetch all service offers for these ext jobs in one query
    final allExtJobIds = extJobs.map((j) => (j['id'] as num).toInt()).toList();
    final allOffers = await _client
        .from('ServiceOffers')
        .select('ext_job_id, musician_id, status')
        .inFilter('ext_job_id', allExtJobIds)
        .not('ext_job_id', 'is', null);

    // Group by ext_job_id
    final offersByExtJob = <int, List<Map<String, dynamic>>>{};
    for (final o in allOffers) {
      final eid = (o['ext_job_id'] as num).toInt();
      (offersByExtJob[eid] ??= []).add(o);
    }

    final now = DateTime.now();
    const first24h = Duration(hours: 24);

    return extJobs.where((j) {
      final id = (j['id'] as num).toInt();
      final jobOffers = offersByExtJob[id] ?? [];

      // Regional window: within first 24 h, only show if job region is in musician's regions
      if (instrument == 'saxophone') {
        final createdAt = DateTime.tryParse(j['created_at'] as String? ?? '');
        if (createdAt != null && now.difference(createdAt) < first24h) {
          final jobRegion = j['region'] as String?;
          if (jobRegion != null && !regions.contains(jobRegion)) return false;
        }
      }

      // Exclude if this musician already has any offer on this job
      if (jobOffers.any((o) => o['musician_id'] == userId)) return false;

      // Exclude if any musician has won this job
      if (jobOffers.any((o) => o['status'] == 'won')) return false;

      return true;
    }).map((j) {
      final id = (j['id'] as num).toInt();
      final jobOffers = offersByExtJob[id] ?? [];
      final hasActiveOffer = jobOffers.any((o) => o['status'] != 'lost');
      return {...j, 'has_active_offer': hasActiveOffer};
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
    // Route through the web API so the server handles side-effects:
    // specifically, updating ExtJob.status → "sent" when role_type = "musician_only".
    final body = <String, dynamic>{
      'price_dkk': priceDkk,
      'musician_payout_dkk': musicianPayoutDkk,
      'sales_pitch': salesPitch,
      'instrument': instrument,
      'status': 'sent',
    };
    if (jobId != null) body['job_id'] = jobId;
    if (extJobId != null) body['ext_job_id'] = extJobId;

    final result = await _webApiPost('/api/service-offers', body);
    // The web API returns { message, offer } — extract the offer object.
    final offer = result['offer'] as Map<String, dynamic>?;
    if (offer == null) throw const DatabaseException('No offer returned from API');

    // The web API offer join uses "extJob" (camelCase); normalise to the
    // snake_case key expected by ServiceOfferModel.fromJson.
    if (offer.containsKey('extJob') && !offer.containsKey('ext_job')) {
      offer['ext_job'] = offer['extJob'];
    }
    return offer;
  }

  /// Fetches a single job with full details.
  Future<Map<String, dynamic>> fetchJobDetail(int jobId) async {
    return _client.from('Jobs').select().eq('id', jobId).single();
  }

  /// Updates Jobs.status = 'customer_contacted'.
  Future<void> markJobCustomerContacted(int jobId) async {
    await _client
        .from('Jobs')
        .update({'status': 'customer_contacted', 'customer_contact_planned_for': null})
        .eq('id', jobId);
  }

  /// Sets Jobs.customer_contact_planned_for (YYYY-MM-DD) without changing status.
  Future<void> setJobPlannedContact(int jobId, String date) async {
    await _client
        .from('Jobs')
        .update({'customer_contact_planned_for': date})
        .eq('id', jobId);
  }

  /// Updates ExtJobs.status = 'customer_contacted' via web API (requires elevated access).
  Future<void> markExtJobCustomerContacted(int extJobId) async {
    await _webApiPut(
      '/api/ext-jobs/$extJobId/customer-contact',
      body: {'contactStatus': 'contacted'},
    );
  }

  /// Sets ExtJobs.customer_contact_planned_for via web API.
  Future<void> setExtJobPlannedContact(int extJobId, String date) async {
    await _webApiPut(
      '/api/ext-jobs/$extJobId/customer-contact',
      body: {'contactStatus': 'planned', 'plannedContactDate': date},
    );
  }

  /// Updates ServiceOffers.customer_contacted = true.
  Future<void> markServiceOfferCustomerContacted(int offerId) async {
    await _client
        .from('ServiceOffers')
        .update({'customer_contacted': true, 'customer_contact_planned_for': null})
        .eq('id', offerId);
  }

  /// Sets ServiceOffers.customer_contact_planned_for (YYYY-MM-DD).
  Future<void> setServiceOfferPlannedContact(int offerId, String date) async {
    await _client
        .from('ServiceOffers')
        .update({'customer_contact_planned_for': date})
        .eq('id', offerId);
  }

  /// Marks a regular job as ready for billing.
  Future<void> markJobReadyForBilling(int jobId) async {
    await _client
        .from('Jobs')
        .update({'status': 'ready_for_billing'})
        .eq('id', jobId);
  }

  /// Marks an ext job as ready for billing via web API (requires elevated access).
  Future<void> markExtJobReadyForBilling(int extJobId) async {
    await _webApiPut('/api/ext-jobs/$extJobId/ready-for-billing');
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

  /// Confirms the DJ is ready for an ext job via web API (requires elevated access).
  Future<void> confirmExtJobDjReady(int extJobId) async {
    await _webApiPatch('/api/ext-jobs/$extJobId/ready');
  }

  /// Confirms the musician is ready for their service offer.
  Future<void> confirmMusicianReady(int offerId) async {
    await _webApiPatch('/api/service-offer/$offerId/ready');
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

  Future<void> setSpecialRequestFee(int offerId, {required int feeDkk}) async {
    final userId = _client.auth.currentUser!.id;
    await _client
        .from('ServiceOffers')
        .update({
          'special_request_extra_fee_dkk': feeDkk,
          'special_request_extra_fee_confirmed': false,
        })
        .eq('id', offerId)
        .eq('musician_id', userId);
  }

  Future<void> removeSpecialRequestFee(int offerId) async {
    final userId = _client.auth.currentUser!.id;
    await _client
        .from('ServiceOffers')
        .update({
          'special_request_extra_fee_dkk': 0,
          'special_request_extra_fee_confirmed': false,
        })
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
