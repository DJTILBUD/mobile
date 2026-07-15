import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dj_tilbud_app/core/config/env_config.dart';
import 'package:dj_tilbud_app/core/error/app_exception.dart';
import 'package:dj_tilbud_app/features/chat/data/models/chat_message_model.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/chat_message.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/job_link.dart';

/// One matching message inside a thread, returned when searching (`?q=`). Lets the list show a
/// snippet under the name and jump straight to that message.
class SupportMatch {
  const SupportMatch({
    required this.id,
    required this.message,
    this.senderType,
  });

  final int id;
  final String message;
  final String? senderType; // 'dj' | 'musician' | 'admin'

  factory SupportMatch.fromJson(Map<String, dynamic> json) => SupportMatch(
    id: (json['id'] as num).toInt(),
    message: (json['message'] as String?) ?? '',
    senderType: json['sender_type'] as String?,
  );
}

/// A support thread in the admin inbox (mobile Support tab). Maps the shape returned by the web-app's
/// `GET /api/chat/support/admin/threads`.
class AdminSupportThread {
  const AdminSupportThread({
    required this.id,
    required this.userName,
    this.userId,
    this.userRole,
    this.userAvatarUrl,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageIsSystem = false,
    this.unreadCount = 0,
    this.handled = true,
    this.matches = const [],
    this.matchCount = 0,
  });

  final int id;
  final String userName;
  final String? userId;
  final String? userRole; // 'dj' | 'musician' | null
  final String? userAvatarUrl;
  final String? lastMessage;
  final String? lastMessageAt;
  final bool lastMessageIsSystem;
  final int unreadCount;

  /// Team-wide "does this still need an answer?". Separate from [unreadCount], which only says
  /// whether anyone has LOOKED and is cleared for the whole team by the first admin who opens it.
  /// Set by an admin reply (DB trigger) or the manual toggle; cleared by any new user message.
  /// Defaults to true so an older API response (no field) never shows a false "needs handling".
  final bool handled;

  /// Search hits in this thread's messages (only populated when searching). Capped server-side;
  /// [matchCount] is the full number.
  final List<SupportMatch> matches;
  final int matchCount;

  bool get hasUnread => unreadCount > 0;

  /// What the Support tab badge counts, mirroring the admin tool's sidebar.
  bool get needsHandling => !handled;

  AdminSupportThread copyWith({int? unreadCount, bool? handled}) =>
      AdminSupportThread(
        id: id,
        userName: userName,
        userId: userId,
        userRole: userRole,
        userAvatarUrl: userAvatarUrl,
        lastMessage: lastMessage,
        lastMessageAt: lastMessageAt,
        lastMessageIsSystem: lastMessageIsSystem,
        unreadCount: unreadCount ?? this.unreadCount,
        handled: handled ?? this.handled,
        matches: matches,
        matchCount: matchCount,
      );

  factory AdminSupportThread.fromJson(Map<String, dynamic> json) {
    return AdminSupportThread(
      id: (json['id'] as num).toInt(),
      userName: (json['user_name'] as String?) ?? 'Ukendt bruger',
      userId: json['user_id'] as String?,
      userRole: json['user_role'] as String?,
      userAvatarUrl: json['user_avatar_url'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] as String?,
      lastMessageIsSystem: json['last_message_is_system'] as bool? ?? false,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      handled: json['handled'] as bool? ?? true,
      matches:
          ((json['matches'] as List?) ?? const [])
              .map((m) => SupportMatch.fromJson(m as Map<String, dynamic>))
              .toList(),
      matchCount: (json['match_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A DJ/musician an admin can start a NEW support conversation with (recipient picker). Maps the
/// shape returned by the web-app's `GET /api/chat/support/admin/recipients`.
class AdminRecipient {
  const AdminRecipient({
    required this.userId,
    required this.name,
    required this.role,
    this.avatarUrl,
  });

  final String userId;
  final String name;
  final String role; // 'dj' | 'musician'
  final String? avatarUrl;

  factory AdminRecipient.fromJson(Map<String, dynamic> json) => AdminRecipient(
    userId: json['user_id'] as String,
    name: (json['name'] as String?) ?? 'Ukendt',
    role: (json['role'] as String?) ?? 'musician',
    avatarUrl: json['avatar_url'] as String?,
  );
}

/// One emoji reaction on a message.
class AdminReaction {
  const AdminReaction({
    required this.messageId,
    required this.userId,
    required this.emoji,
  });
  final int messageId;
  final String userId;
  final String emoji;
}

/// The messages + reactions of one support thread.
class AdminThreadData {
  const AdminThreadData({
    required this.messages,
    required this.reactionsByMessage,
  });
  final List<ChatMessage> messages;
  final Map<int, List<AdminReaction>> reactionsByMessage;
}

/// Talks to the web-app's admin support endpoints. All admin reads/writes go through the web API
/// (bearer-authed, server-side admin + feature-flag check) — never direct Supabase, because an admin
/// isn't a conversation participant under RLS. See documentation/admin-in-app-support-tab.md.
class AdminSupportDatasource {
  AdminSupportDatasource(this._client);

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

  Future<Map<String, dynamic>> _get(String path) async {
    final response = await http.get(
      Uri.parse('$_webAppBaseUrl$path'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DatabaseException(_extractMessage(response.body));
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _post(
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
      throw DatabaseException(_extractMessage(response.body));
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.patch(
      Uri.parse('$_webAppBaseUrl$path'),
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

  String _extractMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is String)
        return decoded['error'] as String;
    } catch (_) {}
    return 'Noget gik galt. Prøv igen.';
  }

  /// Whether the current user has the admin role. Returns false on any failure (feature stays hidden).
  Future<bool> fetchIsAdmin() async {
    try {
      final body = await _get('/api/me/is-admin');
      return body['isAdmin'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<List<AdminSupportThread>> fetchThreads({String? q}) async {
    final query = (q ?? '').trim();
    final path =
        query.isEmpty
            ? '/api/chat/support/admin/threads'
            : '/api/chat/support/admin/threads?q=${Uri.encodeQueryComponent(query)}';
    final body = await _get(path);
    final list = (body['conversations'] as List?) ?? [];
    return list
        .map((j) => AdminSupportThread.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Search DJs + musicians by name for the "new message" recipient picker.
  Future<List<AdminRecipient>> fetchRecipients({String? q}) async {
    final query = (q ?? '').trim();
    final path =
        query.isEmpty
            ? '/api/chat/support/admin/recipients'
            : '/api/chat/support/admin/recipients?q=${Uri.encodeQueryComponent(query)}';
    final body = await _get(path);
    final list = (body['recipients'] as List?) ?? [];
    return list
        .map((j) => AdminRecipient.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Start (or reuse) a support conversation with [userId] and post the first admin message.
  /// Returns the conversation id on success; throws [DatabaseException] on failure.
  Future<int> startConversation({
    required String userId,
    required String message,
  }) async {
    final body = await _post('/api/chat/support/admin/start', {
      'userId': userId,
      'message': message,
    });
    return (body['conversationId'] as num).toInt();
  }

  Future<AdminThreadData> fetchMessages(int conversationId) async {
    final body = await _get('/api/chat/support/admin/$conversationId/messages');
    final msgs =
        ((body['messages'] as List?) ?? [])
            .map(
              (j) =>
                  ChatMessageModel.fromJson(
                    j as Map<String, dynamic>,
                  ).toEntity(),
            )
            .toList();
    final reactionsByMessage = <int, List<AdminReaction>>{};
    for (final r in (body['reactions'] as List?) ?? []) {
      final map = r as Map<String, dynamic>;
      final mid = (map['message_id'] as num).toInt();
      (reactionsByMessage[mid] ??= []).add(
        AdminReaction(
          messageId: mid,
          userId: map['user_id'] as String,
          emoji: map['emoji'] as String,
        ),
      );
    }
    return AdminThreadData(
      messages: msgs,
      reactionsByMessage: reactionsByMessage,
    );
  }

  /// Send an admin reply. Returns null on success, a Danish error string on failure.
  Future<String?> sendMessage(
    int conversationId,
    String message, {
    int? replyToId,
    String? attachmentUrl,
  }) async {
    try {
      await _post('/api/chat/support/admin/$conversationId/messages', {
        'message': message,
        if (replyToId != null) 'reply_to_id': replyToId,
        if (attachmentUrl != null) 'attachment_url': attachmentUrl,
      });
      return null;
    } on DatabaseException catch (e) {
      return e.message;
    } catch (_) {
      return 'Noget gik galt. Prøv igen.';
    }
  }

  /// Marks a support thread handled / unhandled. Returns null on success, or a Danish error.
  ///
  /// Handled is TEAM-WIDE ("does this still need an answer?"), separate from read state (which only
  /// says whether anyone has looked, and clears for everyone the moment one admin opens the thread).
  /// Replying already marks a thread handled via a DB trigger, and any new musician message re-opens
  /// it — this is only the manual override. Mirrors the admin tool's toggle.
  Future<String?> setHandled(int conversationId, bool handled) async {
    try {
      await _post('/api/chat/support/admin/$conversationId/handled', {
        'handled': handled,
      });
      return null;
    } on DatabaseException catch (e) {
      return e.message;
    } catch (_) {
      return 'Kunne ikke opdatere status. Prøv igen.';
    }
  }

  /// Edits an ADMIN message in a support thread. Returns null on success, or a Danish error.
  ///
  /// Routes through the web-app API (the mobile app talks to the web-app, not the admin tool), which
  /// scopes the update to `sender_type='admin'` — an admin can never rewrite the musician's own
  /// words, even though that route runs on the service role. `edited_at` is stamped by the DB.
  Future<String?> editMessage(
    int conversationId,
    int messageId,
    String message,
  ) async {
    try {
      await _patch(
        '/api/chat/support/admin/$conversationId/messages/$messageId',
        {'message': message},
      );
      return null;
    } on DatabaseException catch (e) {
      return e.message;
    } catch (_) {
      return 'Beskeden kunne ikke redigeres. Prøv igen.';
    }
  }

  /// Uploads a chat image to S3 (presigned PUT) and returns its public URL.
  /// Mirrors the musician chat's uploadChatImage — the admin uploads under their
  /// own userId; the message then carries the returned url as `attachment_url`.
  Future<String> uploadImage({
    required String userId,
    required String filePath,
  }) async {
    final file = File(filePath);
    final fileName = filePath.split('/').last;
    final contentType = _imageMimeType(filePath);

    final signedUrlUri = Uri.parse(
      '$_webAppBaseUrl/api/files/signed-url'
      '?fileName=${Uri.encodeComponent(fileName)}'
      '&contentType=${Uri.encodeComponent(contentType)}'
      '&type=chat_attachment'
      '&userId=${Uri.encodeComponent(userId)}',
    );
    final signedUrlRes = await http.get(signedUrlUri);
    if (signedUrlRes.statusCode < 200 || signedUrlRes.statusCode >= 300) {
      throw Exception('Could not get signed URL (${signedUrlRes.statusCode})');
    }
    final signedUrl =
        (jsonDecode(signedUrlRes.body) as Map<String, dynamic>)['url']
            as String;
    final fileUrl =
        signedUrl.split('?').first; // public URL = signed URL minus query

    final uploadRes = await http.put(
      Uri.parse(signedUrl),
      headers: {'Content-Type': contentType},
      body: await file.readAsBytes(),
    );
    if (uploadRes.statusCode < 200 || uploadRes.statusCode >= 300) {
      throw Exception('S3 upload failed (${uploadRes.statusCode})');
    }
    return fileUrl;
  }

  String _imageMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> toggleReaction(
    int conversationId,
    int messageId,
    String emoji,
  ) async {
    await _post('/api/chat/support/admin/$conversationId/reactions', {
      'messageId': messageId,
      'emoji': emoji,
    });
  }

  Future<void> markRead(int conversationId) async {
    await _post('/api/chat/support/admin/$conversationId/read', {});
  }

  /// Mark a thread UNREAD again (team-wide) — re-bolds it in the inbox + returns the badge.
  Future<void> markUnread(int conversationId) async {
    await _post('/api/chat/support/admin/$conversationId/unread', {});
  }

  /// Composer "@" picker: search every job/ext-job (admins see all). When
  /// [recipientUserId] is set, each result carries `visibleToRecipient` so the
  /// composer can warn about jobs the DJ/musician can't see.
  Future<List<LinkableJob>> searchLinkableJobs(
    String query, {
    String? recipientUserId,
  }) async {
    final params = <String, String>{'q': query};
    if (recipientUserId != null && recipientUserId.isNotEmpty) {
      params['recipientUserId'] = recipientUserId;
    }
    final qs = Uri(queryParameters: params).query;
    final body = await _get('/api/chat/support/admin/linkable-jobs?$qs');
    final list = (body['data'] as List?) ?? [];
    return list
        .map((j) => LinkableJob.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Resolve `@job:`/`@extjob:` tokens to labels for chip rendering in the admin
  /// thread. Admins can open any existing job (accessible = the row exists).
  Future<Map<String, JobLinkResolution>> resolveJobLinks(
    List<String> refs,
  ) async {
    if (refs.isEmpty) return {};
    final body = await _get(
      '/api/chat/support/admin/job-links/resolve?refs=${refs.join(',')}',
    );
    final map = (body['resolutions'] as Map?) ?? {};
    return map.map(
      (k, v) => MapEntry(
        k as String,
        JobLinkResolution.fromJson(Map<String, dynamic>.from(v as Map)),
      ),
    );
  }
}
