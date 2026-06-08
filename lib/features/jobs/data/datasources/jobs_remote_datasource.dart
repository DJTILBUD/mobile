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
    String path,
    Map<String, dynamic> body,
  ) async {
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

  Future<void> _webApiPatch(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_webAppBaseUrl$path');
    final response = await http.patch(
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

  Future<void> _webApiDelete(String path) async {
    final uri = Uri.parse('$_webAppBaseUrl$path');
    final response = await http.delete(
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

  Future<Map<String, dynamic>> _webApiGet(String path) async {
    final uri = Uri.parse('$_webAppBaseUrl$path');
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DatabaseException(_extractMessage(response.body));
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // Returns the server's intended `message` field, or an empty string when the
  // body isn't a clean JSON message. We never return the raw body, so technical
  // text (HTML, stack traces) can't leak into a user-facing error toast — call
  // sites fall back to a friendly Danish message when this is empty.
  String _extractMessage(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['message'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Fetches the jobs a DJ should see in "Nye jobs".
  ///
  /// All business/visibility rules — pending-quote cap (so 3-quote jobs drop out),
  /// tier quotas, paused jobs, sax capability, profile-excluded event types,
  /// already-quoted/rejected exclusion, unavailable dates and the collision sort —
  /// now live in the web app and are applied by the shared
  /// `GET /api/dj/biddable-jobs` route, the single source of truth shared with the
  /// web client (web-app `src/domain/biddableJobs.ts`). This replaced a partial
  /// Dart reimplementation that never counted quotes, which is why full jobs used
  /// to stay visible.
  ///
  /// We request `applyFilters=false` so the *optional* DjJobFilters preferences
  /// stay client-side, keeping the in-list "Filtre til/fra" toggle instant
  /// (no network round-trip).
  ///
  /// [userId] is unused (the route resolves the DJ from the auth token) but kept
  /// for interface symmetry with the other fetch methods.
  Future<List<Map<String, dynamic>>> fetchNewDjJobs(String userId) async {
    final body = await _webApiGet('/api/dj/biddable-jobs?applyFilters=false');
    final data = body['data'] as List<dynamic>? ?? const [];
    return data.cast<Map<String, dynamic>>();
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
  /// Matches web app `getConfirmedExtJobsByDjIdAndDate`: statuses
  /// sent/closed/customer_contacted/ready_for_billing, most recent date first.
  /// `sent` MUST be included so the date-collision warning fires pre-submit for
  /// a confirmed ext job (the server still 409s either way).
  Future<List<Map<String, dynamic>>> fetchDjExtJobs(String userId) async {
    return _client
        .from('ExtJobs')
        .select()
        .eq('assigned_dj_id', userId)
        .inFilter('status', [
          'sent',
          'closed',
          'customer_contacted',
          'ready_for_billing',
        ])
        .order('date', ascending: false);
  }

  /// Fetches jobs available for an instrumentalist to bid on.
  /// Mirrors web app useAvailableJobsForMusicians:
  /// - Wide status filter (open/sent/re_sent/reopened/another_round/closed/customer_contacted)
  /// - archived = false (a CRM-archived job keeps its status, so the status
  ///   filter alone does not hide it — archiving must "hide from all active
  ///   lists" per the admin archive route, and the canonical customer query
  ///   `useViewableCustomerJobs` likewise filters `.eq("archived", false)`).
  ///   Without this, archived saxophone jobs leaked into "Nye jobs".
  /// - requested_saxophonist = true, filtered to musician's regions
  /// - Excludes if this musician already has any offer (will be in their lanes)
  /// - Excludes if any musician has a WON offer
  /// - Excludes jobs within first 24 h where job region is not in musician's regions (regional window)
  /// - Marks has_active_offer when another musician has a non-lost offer
  Future<List<Map<String, dynamic>>> fetchNewInstrumentalistJobs(
    String userId,
  ) async {
    final musicianInfo =
        await _client
            .from('Musicians')
            .select('regions, instrument')
            .eq('id', userId)
            .single();
    final regions = (musicianInfo['regions'] as List<dynamic>).cast<String>();
    final instrument = musicianInfo['instrument'] as String? ?? 'saxophone';

    if (regions.isEmpty) return [];

    // Two queries: normal open statuses + ready_for_billing only when sax_round_active = true.
    final regularJobs = await _client
        .from('Jobs')
        .select()
        .eq('requested_saxophonist', true)
        .eq('is_paused', false)
        .eq('archived', false)
        .inFilter('status', [
          'open',
          'sent',
          're_sent',
          'reopened',
          'another_round',
          'closed',
          'customer_contacted',
        ])
        .order('created_at', ascending: false);

    List<Map<String, dynamic>> saxCampaignJobs = [];
    try {
      saxCampaignJobs = await _client
          .from('Jobs')
          .select()
          .eq('requested_saxophonist', true)
          .eq('is_paused', false)
          .eq('archived', false)
          .eq('status', 'ready_for_billing')
          .eq('sax_round_active', true)
          .order('created_at', ascending: false);
    } catch (_) {
      // sax_round_active column may not exist yet — skip gracefully
    }

    final jobs = [...regularJobs, ...saxCampaignJobs];

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

    return jobs
        .where((j) {
          final id = (j['id'] as num).toInt();
          final jobOffers = offersByJob[id] ?? [];

          // Regional window: within first 24 h only show sax jobs to musicians
          // whose regions include the job's region. After 24 h visible to all.
          if (instrument == 'saxophone') {
            final createdAt = DateTime.tryParse(
              j['created_at'] as String? ?? '',
            );
            if (createdAt != null && now.difference(createdAt) < first24h) {
              final jobRegion = j['region'] as String?;
              if (jobRegion != null && !regions.contains(jobRegion))
                return false;
            }
          }

          // Exclude if this musician already has any offer on this job
          final hasMine = jobOffers.any((o) => o['musician_id'] == userId);
          if (hasMine) return false;

          // Exclude if any musician has won this job
          final hasWon = jobOffers.any((o) => o['status'] == 'won');
          if (hasWon) return false;

          return true;
        })
        .map((j) {
          final id = (j['id'] as num).toInt();
          final jobOffers = offersByJob[id] ?? [];
          final hasActiveOffer = jobOffers.any((o) => o['status'] != 'lost');
          return {...j, 'has_active_offer': hasActiveOffer};
        })
        .toList();
  }

  /// Fetches ext jobs available for this instrumentalist to bid on.
  /// Mirrors web app useExtJobsForMusicians exactly.
  Future<List<Map<String, dynamic>>> fetchInstrumentalistExtJobs(
    String userId,
  ) async {
    final musicianInfo =
        await _client
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

    return extJobs
        .where((j) {
          final id = (j['id'] as num).toInt();
          final jobOffers = offersByExtJob[id] ?? [];

          // Regional window: within first 24 h, only show if job region is in musician's regions
          if (instrument == 'saxophone') {
            final createdAt = DateTime.tryParse(
              j['created_at'] as String? ?? '',
            );
            if (createdAt != null && now.difference(createdAt) < first24h) {
              final jobRegion = j['region'] as String?;
              if (jobRegion != null && !regions.contains(jobRegion))
                return false;
            }
          }

          // Exclude if this musician already has any offer on this job
          if (jobOffers.any((o) => o['musician_id'] == userId)) return false;

          // Exclude if any musician has won this job
          if (jobOffers.any((o) => o['status'] == 'won')) return false;

          return true;
        })
        .map((j) {
          final id = (j['id'] as num).toInt();
          final jobOffers = offersByExtJob[id] ?? [];
          final hasActiveOffer = jobOffers.any((o) => o['status'] != 'lost');
          return {...j, 'has_active_offer': hasActiveOffer};
        })
        .toList();
  }

  /// Fetches all service offers by this musician (both regular and ext jobs).
  Future<List<Map<String, dynamic>>> fetchServiceOffers(String userId) async {
    return _client
        .from('ServiceOffers')
        .select(
          '*, job:Jobs!ServiceOffers_job_id_fkey(*), ext_job:ExtJobs!ServiceOffers_ext_job_id_fkey(*)',
        )
        .eq('musician_id', userId)
        .order('created_at', ascending: false);
  }

  /// Creates a DJ quote.
  ///
  /// Routes through the web API (POST /api/jobs/{jobId}/quotes) rather than
  /// inserting into Quotes directly. The route is the single source of truth
  /// for the side-effect of flipping the job to "sent"/"re_sent" once it has
  /// its 3rd pending quote (and immediately in first_quote_only mode). A direct
  /// Supabase insert bypasses that transition, leaving jobs stuck in "open".
  /// Going through the route also applies its suppression / excluded-event-type
  /// / tier-quota checks consistently with the web app.
  ///
  /// The route returns the bare created quote row (no `job` join), so
  /// [DjQuoteModel.fromJson] tolerates a missing `job` key.
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
    return _webApiPost('/api/jobs/$jobId/quotes', payload);
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
    if (offer == null)
      throw const DatabaseException('No offer returned from API');

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

  /// Updates Jobs.status = 'customer_contacted' via web API (requires elevated
  /// access — RLS does not allow the DJ to update Jobs directly, so a direct
  /// update silently affects 0 rows and the change appears to "reset").
  Future<void> markJobCustomerContacted(int jobId) async {
    await _webApiPut(
      '/api/jobs/$jobId/customer-contact',
      body: {'contactStatus': 'contacted'},
    );
  }

  /// Sets Jobs.customer_contact_planned_for (YYYY-MM-DD) via web API
  /// (elevated — see [markJobCustomerContacted]).
  Future<void> setJobPlannedContact(int jobId, String date) async {
    await _webApiPut(
      '/api/jobs/$jobId/customer-contact',
      body: {'contactStatus': 'planned', 'plannedContactDate': date},
    );
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

  /// Marks a musician's service offer as customer-contacted via the web API.
  ///
  /// Routed through the web API (NOT a direct Supabase update) so the route's
  /// validation and side-effects run — notably the cascade that flips a
  /// `musician_only` ExtJob to `customer_contacted`. Mirrors
  /// [markExtJobCustomerContacted] / [markJobCustomerContacted].
  Future<void> markServiceOfferCustomerContacted(int offerId) async {
    await _webApiPost('/api/service-offer/$offerId/customer-contacted', {
      'contactStatus': 'contacted',
    });
  }

  /// Sets a planned customer-contact date on a service offer via the web API
  /// (the route validates the date is not in the past).
  Future<void> setServiceOfferPlannedContact(int offerId, String date) async {
    await _webApiPost('/api/service-offer/$offerId/customer-contacted', {
      'contactStatus': 'planned',
      'plannedContactDate': date,
    });
  }

  /// Marks a regular job as ready for billing via web API (requires elevated
  /// access — see [markJobCustomerContacted]). The route also enforces that the
  /// job is already customer_contacted before allowing the transition.
  Future<void> markJobReadyForBilling(int jobId) async {
    await _webApiPut('/api/jobs/$jobId/ready-for-billing');
  }

  /// Marks an ext job as ready for billing via web API (requires elevated access).
  Future<void> markExtJobReadyForBilling(int extJobId) async {
    await _webApiPut('/api/ext-jobs/$extJobId/ready-for-billing');
  }

  /// Resolves the early setup status on a won quote ('accepted' or 'rejected').
  ///
  /// Routed through the web API's early-setup branch (NOT a direct Supabase
  /// update) so the won-status guard and any price realignment run server-side.
  Future<void> resolveEarlySetup(int quoteId, {required bool accepted}) async {
    await _webApiPut(
      '/api/quotes/$quoteId',
      body: {'early_setup_status': accepted ? 'accepted' : 'rejected'},
    );
  }

  /// Confirms the DJ is ready for an internal job quote via the web API.
  ///
  /// Routed through the web API (NOT a direct Supabase update) so the route's
  /// guards run: quote must be `won`, not already confirmed, and within 5 days
  /// of the event. Mirrors [confirmExtJobDjReady] / [confirmMusicianReady].
  Future<void> confirmDjReady(int quoteId) async {
    await _webApiPatch('/api/quotes/$quoteId/ready');
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
  ///
  /// Routed through the web API (NOT a direct Supabase update) because adding
  /// extra hours must recompute `price_dkk` (= base + extra_hours × rate) and
  /// realign `dj_payout_override`. That pricing logic lives ONLY in the route
  /// handler — a direct update would leave `price_dkk` stale, so the DJ's
  /// displayed total would no longer match the invoice. [newTotalPrice] is the
  /// expected total (server re-validates it).
  Future<void> addExtraHours(
    int quoteId, {
    required double extraHours,
    required int pricePerHour,
    required int newTotalPrice,
  }) async {
    await _webApiPatch(
      '/api/quotes/$quoteId/extra-hours',
      body: {
        'extra_hours': extraHours,
        'extra_hours_price_per_hour': pricePerHour,
        'new_total_price': newTotalPrice,
      },
    );
  }

  /// Clears extra hours from a won DJ quote.
  ///
  /// Routed through the web API so `price_dkk` (and any `dj_payout_override`) is
  /// restored to the base amount server-side — a direct update would only null
  /// the extra-hours columns and leave an inflated price behind.
  Future<void> deleteExtraHours(int quoteId) async {
    await _webApiDelete('/api/quotes/$quoteId/extra-hours');
  }

  /// Adds / updates extra hours on an ext job the DJ is assigned to.
  ///
  /// Routed through the web API (NOT a direct Supabase update) because the route
  /// recomputes `full_amount` (= base + extra_hours × rate) and `honorar`
  /// (base + extra × DJ share) server-side. A direct update would leave both
  /// stale, so the DJ's "Dit honorar" would no longer match the invoice.
  /// [newTotalPrice] is the expected new full_amount; the server re-validates it.
  Future<void> addExtJobExtraHours(
    int extJobId, {
    required double extraHours,
    required int pricePerHour,
    required int newTotalPrice,
  }) async {
    await _webApiPatch(
      '/api/ext-jobs/$extJobId/extra-hours',
      body: {
        'extra_hours': extraHours,
        'extra_hours_price_per_hour': pricePerHour,
        'new_total_price': newTotalPrice,
      },
    );
  }

  /// Clears extra hours from an ext job (restores base full_amount + honorar).
  Future<void> deleteExtJobExtraHours(int extJobId) async {
    await _webApiDelete('/api/ext-jobs/$extJobId/extra-hours');
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
  ///
  /// Routed through the web API (NOT a direct Supabase update) so the route's
  /// guards run: the quote must still be `pending`, the edit must be inside the
  /// 10-minute window, and price/sales-pitch/equipment validation applies. That
  /// logic is the single source of truth in web-app
  /// `src/app/api/quotes/[id]/route.ts`; a direct update would bypass all of it.
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
    await _webApiPut('/api/quotes/$quoteId', body: payload);
    // The route returns only {success, message}, so re-read the updated row
    // (with its job) to satisfy the DjQuote shape callers expect.
    return _client
        .from('Quotes')
        .select('*, job:Jobs(*)')
        .eq('id', quoteId)
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
        .select(
          'id, musician_id, price_dkk, musician_payout_dkk, instrument, status, sales_pitch, created_at, musician:Musicians(full_name, phone, email)',
        )
        .eq('job_id', jobId)
        .inFilter('status', ['sent', 'won', 'lost'])
        .order('created_at', ascending: false);
  }

  /// Fetches song requests submitted by guests for a job (DJ view).
  Future<List<Map<String, dynamic>>> fetchSongRequestsForJob(int jobId) async {
    return _client
        .from('SongRequests')
        .select('id, job_id, guest_email, song_1, song_2, song_3, created_at')
        .eq('job_id', jobId)
        .order('created_at', ascending: false);
  }

  /// Fetches song requests submitted by guests for an ext job (DJ view).
  Future<List<Map<String, dynamic>>> fetchSongRequestsForExtJob(
    int extJobId,
  ) async {
    return _client
        .from('SongRequests')
        .select(
          'id, ext_job_id, guest_email, song_1, song_2, song_3, created_at',
        )
        .eq('ext_job_id', extJobId)
        .order('created_at', ascending: false);
  }

  /// Fetches the won DJ quote (with DJ contact info) for an internal job.
  /// Used by musicians to see who the DJ is on a job they won.
  Future<Map<String, dynamic>?> fetchWonDjInfoForJob(int jobId) async {
    // NOTE: Quotes.dj_id FKs to auth.users, NOT DjInfos, so PostgREST cannot
    // embed `dj:DjInfos(...)` directly from Quotes (it errors with PGRST200,
    // which previously surfaced as a silent empty section). Fetch the winning
    // internal-DJ id first, then look up DjInfos by id in a second query.
    // External-DJ wins (dj_id null, ext_dj_id set) have no in-app DJ profile
    // and never get a chat, so returning null hides the section as intended.
    final quotes = await _client
        .from('Quotes')
        .select('dj_id')
        .eq('job_id', jobId)
        .eq('status', 'won')
        .not('dj_id', 'is', null)
        .limit(1);
    if (quotes.isEmpty) return null;
    final djId = quotes.first['dj_id'] as String?;
    if (djId == null) return null;

    final dj =
        await _client
            .from('DjInfos')
            .select('full_name, phone')
            .eq('id', djId)
            .maybeSingle();
    if (dj == null) return null;
    return {'dj_id': djId, 'dj': dj};
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
  ///
  /// Routed through the web API (NOT a direct Supabase update) because the
  /// route recomputes `price_dkk` and `musician_payout_dkk` from the extra
  /// half-hours using the platform's per-half-hour constants. A direct update
  /// would only set `extra_hours` and leave the payout/price stale, so the
  /// musician's displayed amount would no longer match the invoice.
  Future<void> addMusicianExtraHours(
    int offerId, {
    required double extraHours,
  }) async {
    await _webApiPatch(
      '/api/service-offer/$offerId/extra-hours',
      body: {'extra_hours': extraHours},
    );
  }

  /// Submits a requested special-request fee on a service offer via the web API.
  ///
  /// Routed through the web API (NOT a direct Supabase update) so the route's
  /// guards run: offer must be `sent`/`won`, fee must be 1–50000, and an
  /// already-confirmed fee cannot be changed.
  Future<void> setSpecialRequestFee(int offerId, {required int feeDkk}) async {
    await _webApiPatch(
      '/api/service-offer/$offerId/special-request-fee',
      body: {'fee_dkk': feeDkk},
    );
  }

  /// Withdraws a pending special-request fee on a service offer via the web API.
  Future<void> removeSpecialRequestFee(int offerId) async {
    await _webApiDelete('/api/service-offer/$offerId/special-request-fee');
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
