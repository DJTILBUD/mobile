import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dj_tilbud_app/core/config/env_config.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/job_link.dart';

/// Calls the web-app's job-link endpoints (the single source of truth for job
/// visibility). Business logic stays server-side; the app just renders the
/// resolved access + target.
class JobLinkRemoteDatasource {
  JobLinkRemoteDatasource(this._client);

  final SupabaseClient _client;

  String get _baseUrl {
    String url = EnvConfig.webAppUrl;
    if (EnvConfig.isLocal && Platform.isAndroid) {
      url = url.replaceFirst('localhost', '10.0.2.2');
    }
    return url;
  }

  String get _token {
    final token = _client.auth.currentSession?.accessToken;
    if (token == null) throw Exception('Not authenticated');
    return token;
  }

  /// Jobs the current user may link, for the composer "@" picker.
  Future<List<LinkableJob>> searchLinkableJobs(String query) async {
    final uri = Uri.parse(
      '$_baseUrl/api/chat/linkable-jobs?q=${Uri.encodeQueryComponent(query)}',
    );
    final res = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $_token'},
    );
    if (res.statusCode < 200 || res.statusCode >= 300) return const [];
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final data = (json['data'] as List?) ?? const [];
    return data
        .map((e) => LinkableJob.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Batch-resolves the job-ref tokens in a conversation for the current viewer.
  Future<Map<String, JobLinkResolution>> resolveJobLinks(
    List<String> refs,
  ) async {
    if (refs.isEmpty) return const {};
    final uri = Uri.parse('$_baseUrl/api/chat/job-links/resolve');
    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'refs': refs}),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) return const {};
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final resolutions = (json['resolutions'] as Map?) ?? const {};
    final out = <String, JobLinkResolution>{};
    resolutions.forEach((key, value) {
      out[key as String] = JobLinkResolution.fromJson(
        Map<String, dynamic>.from(value as Map),
      );
    });
    return out;
  }
}
