import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dj_tilbud_app/core/config/env_config.dart';
import 'package:dj_tilbud_app/core/error/app_exception.dart';
import 'package:dj_tilbud_app/features/referrals/data/models/referral_model.dart';
import 'package:dj_tilbud_app/features/referrals/domain/entities/referral.dart';
import 'package:dj_tilbud_app/features/referrals/domain/entities/referral_terms.dart';

/// Talks ONLY to the web-app (`/api/referrals`), never to Supabase tables: creating a referral
/// creates an ExtJob, a Referrals row, an admin Action and possibly a push, all of which live in
/// the web route. Same `_webApiGet`/`_webApiPost` shape as `JobsRemoteDatasource`.
class ReferralsRemoteDatasource {
  ReferralsRemoteDatasource(this._client);

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
    if (token == null) {
      throw Exception('Not authenticated');
    }
    return token;
  }

  Future<List<ReferralModel>> fetchMyReferrals() async {
    final body = await _webApiGet('/api/referrals');
    final rows = (body['referrals'] as List<dynamic>?) ?? const [];
    return rows
        .map((r) => ReferralModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<ReferralModel> createReferral(ReferralInput input) async {
    final result = await _webApiPost(
      '/api/referrals',
      ReferralModel.inputToJson(input),
    );
    final referral = result['referral'] as Map<String, dynamic>?;
    if (referral == null) {
      throw const DatabaseException('No referral returned from API');
    }
    return ReferralModel.fromCreateResponse(
      referral,
      result['extJob'] as Map<String, dynamic>?,
    );
  }

  /// Whether the performer accepted the referral terms (`GET /api/referrals/terms`).
  Future<ReferralTermsStatus> fetchReferralTerms() async {
    return ReferralTermsStatus.fromJson(
      await _webApiGet('/api/referrals/terms'),
    );
  }

  /// "Jeg har læst og accepterer vilkårene" (`POST /api/referrals/terms`). The web-app stamps the
  /// acceptance; the first time is kept.
  Future<ReferralTermsStatus> acceptReferralTerms() async {
    return ReferralTermsStatus.fromJson(
      await _webApiPost('/api/referrals/terms', const {}),
    );
  }

  Future<Map<String, dynamic>> _webApiGet(String path) async {
    final response = await http.get(
      Uri.parse('$_webAppBaseUrl$path'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _errorFor(response.body);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _webApiPost(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$_webAppBaseUrl$path'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _errorFor(response.body);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // The route answers a validation failure with `{message: "Bad request.", details: <Danish
  // reason>}` and everything else with a Danish `message`; prefer the specific text. Never the
  // raw body, so HTML or a stack trace can't reach a toast.
  AppException _errorFor(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final details = json['details'] as String?;
      final message = json['message'] as String?;
      return DatabaseException(
        (details != null && details.isNotEmpty) ? details : (message ?? ''),
      );
    } catch (_) {
      return const DatabaseException('');
    }
  }
}
