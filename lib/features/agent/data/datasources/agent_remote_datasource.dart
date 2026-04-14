import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:dj_tilbud_app/core/config/env_config.dart';
import 'package:dj_tilbud_app/core/error/app_exception.dart';

class AgentRemoteDatasource {
  AgentRemoteDatasource(this._supabase);

  final SupabaseClient _supabase;

  String get _functionsBaseUrl {
    String url = EnvConfig.supabaseUrl;
    if (EnvConfig.isLocal && Platform.isAndroid) {
      url = url.replaceFirst('127.0.0.1', '10.0.2.2');
    }
    return '$url/functions/v1';
  }

  String get _accessToken {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null) throw const AuthException('Not authenticated');
    return token;
  }

  Stream<String> streamAssist({
    required Map<String, dynamic> jobContext,
    required Map<String, dynamic> userContext,
    required String userRole,
    required String sessionId,
    List<Map<String, dynamic>> messageHistory = const [],
    String purpose = 'sales_pitch',
    Map<String, String>? profileAnswers,
  }) async* {
    final uri = Uri.parse('$_functionsBaseUrl/agent-assist');

    final bodyMap = <String, dynamic>{
      'job': jobContext,
      'userProfile': userContext,
      'userRole': userRole,
      'sessionId': sessionId,
      'messageHistory': messageHistory,
      'purpose': purpose,
    };
    if (profileAnswers != null) bodyMap['profileAnswers'] = profileAnswers;

    final request = http.Request('POST', uri)
      ..headers['Authorization'] = 'Bearer $_accessToken'
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(bodyMap);

    http.StreamedResponse response;
    try {
      response = await http.Client().send(request);
    } catch (e) {
      throw NetworkException('Could not reach agent service: $e');
    }

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw AgentException('Agent error ${response.statusCode}: $body');
    }

    // Parse SSE stream: each message is "data: {...}\n\n"
    String buffer = '';
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      buffer += chunk;

      while (buffer.contains('\n\n')) {
        final splitIndex = buffer.indexOf('\n\n');
        final message = buffer.substring(0, splitIndex);
        buffer = buffer.substring(splitIndex + 2);

        for (final line in message.split('\n')) {
          if (!line.startsWith('data: ')) continue;
          final jsonStr = line.substring(6).trim();
          if (jsonStr.isEmpty) continue;

          final Map<String, dynamic> data;
          try {
            data = jsonDecode(jsonStr) as Map<String, dynamic>;
          } catch (_) {
            continue;
          }

          if (data['type'] == 'delta') {
            final text = data['text'] as String? ?? '';
            if (text.isNotEmpty) yield text;
          } else if (data['type'] == 'done') {
            return;
          } else if (data['type'] == 'error') {
            throw AgentException(data['message'] as String? ?? 'Unknown agent error');
          }
        }
      }
    }
  }

  Future<void> updateFinalSubmittedText({
    required String sessionId,
    required String finalText,
  }) async {
    await _supabase
        .from('AgentInteractions')
        .update({'final_submitted_text': finalText})
        .eq('session_id', sessionId)
        .eq('user_id', _supabase.auth.currentUser!.id);
  }
}
