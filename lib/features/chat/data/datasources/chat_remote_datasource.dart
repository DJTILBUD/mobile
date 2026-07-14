import 'dart:convert';
import 'dart:io' show Platform, File;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dj_tilbud_app/core/config/env_config.dart';
import 'package:dj_tilbud_app/features/chat/data/models/conversation_model.dart';
import 'package:dj_tilbud_app/features/chat/data/models/chat_message_model.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/chat_message.dart';
import 'package:dj_tilbud_app/features/chat/domain/chat_message_preview.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';

class ChatRemoteDatasource {
  const ChatRemoteDatasource(this._client);

  final SupabaseClient _client;

  String get _webAppBaseUrl {
    String url = EnvConfig.webAppUrl;
    if (EnvConfig.isLocal && Platform.isAndroid) {
      url = url.replaceFirst('localhost', '10.0.2.2');
    }
    return url;
  }

  /// Idempotently ensures the pinned DJTILBUD support conversation exists. Routed through the
  /// web API (it writes a row + a welcome message — business logic, not a plain insert).
  /// Best-effort: a failure must not block the chat list from loading.
  Future<void> _ensureSupportConversation() async {
    try {
      final token = _client.auth.currentSession?.accessToken;
      if (token == null) return;
      await http.post(
        Uri.parse('$_webAppBaseUrl/api/chat/support/ensure'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    } catch (_) {
      // Ignore — the support row will be ensured on the next load.
    }
  }

  /// Reads a feature flag (defaults off when missing/unreadable so a gated feature stays dark).
  Future<bool> _isFeatureEnabled(String key) async {
    try {
      final row =
          await _client
              .from('FeatureFlags')
              .select('enabled')
              .eq('key', key)
              .maybeSingle();
      return (row?['enabled'] as bool?) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<List<ConversationModel>> fetchConversations(
    String currentUserId,
  ) async {
    // Feature-flag gate for the DJTILBUD support chat: while off, don't ensure or show it.
    final supportChatEnabled = await _isFeatureEnabled('support-chat-system');
    if (supportChatEnabled) {
      await _ensureSupportConversation();
    }

    final response = await _client
        .from('Conversations')
        .select('''
          *,
          job:Jobs!Conversations_job_id_fkey(id, event_type, date),
          ext_job:ExtJobs!Conversations_ext_job_id_fkey(id, event_type, date, assigned_dj_name),
          dj:DjInfos!Conversations_dj_id_fkey(id, full_name),
          musician:Musicians!Conversations_musician_id_fkey(id, full_name, instrument)
        ''')
        // Scope to THIS user explicitly — do not rely on RLS. An admin user (who may also use the
        // musician app) has a broad SELECT policy and would otherwise see everyone's chats.
        .or(
          'dj_id.eq.$currentUserId,musician_id.eq.$currentUserId,user_id.eq.$currentUserId',
        )
        .order('last_message_at', ascending: false);

    final rawList = (response as List<dynamic>).cast<Map<String, dynamic>>();

    // Filter to only chat-enabled conversations; also hide support rows while the flag is off.
    final filtered =
        rawList.where((json) {
          if (!supportChatEnabled && json['type'] == 'support') return false;
          final model = ConversationModel.fromJson(json);
          return model.isChatEnabled(currentUserId);
        }).toList();

    // Collect all partner IDs for batch profile image fetch
    final partnerIds = <String>{};
    for (final json in filtered) {
      final djId = json['dj_id'] as String?;
      final musicianId = json['musician_id'] as String?;
      if (djId != null) partnerIds.add(djId);
      if (musicianId != null) partnerIds.add(musicianId);
    }

    // Batch fetch: last messages + unread counts + profile images in parallel
    final imagesFuture =
        partnerIds.isNotEmpty
            ? _client
                .from('UserFiles')
                .select('user_id, url')
                .inFilter('user_id', partnerIds.toList())
                .eq('type', 'profile')
                .order('created_at', ascending: false)
            : Future.value(<Map<String, dynamic>>[]);

    final enrichedAndImages = await Future.wait([
      Future.wait(
        filtered.map((json) async {
          final id = (json['id'] as num).toInt();
          final results = await Future.wait([
            _fetchLastMessage(id),
            _fetchUnreadCount(id, currentUserId),
            _fetchLatestReaction(id),
          ]);
          return (
            json: json,
            lastMsg: results[0] as Map<String, dynamic>?,
            unread: results[1] as int,
            reaction: results[2] as Map<String, dynamic>?,
          );
        }),
      ),
      imagesFuture,
    ]);

    final msgResults =
        enrichedAndImages[0]
            as List<
              ({
                Map<String, dynamic> json,
                Map<String, dynamic>? lastMsg,
                int unread,
                Map<String, dynamic>? reaction,
              })
            >;
    final imageRows =
        (enrichedAndImages[1] as List<dynamic>).cast<Map<String, dynamic>>();

    // Build userId → first profile image URL map
    final imageMap = <String, String>{};
    for (final row in imageRows) {
      final uid = row['user_id'] as String;
      if (!imageMap.containsKey(uid)) {
        imageMap[uid] = row['url'] as String;
      }
    }

    final enriched =
        msgResults.map((r) {
          final djId = r.json['dj_id'] as String?;
          final musicianId = r.json['musician_id'] as String?;
          return ConversationModel.fromJson(
            r.json,
            // Image-only messages have empty text — show "sent an image" instead of a blank preview.
            // Keep null when there's no message at all (the "Ingen beskeder endnu" case).
            lastMessageText:
                r.lastMsg == null
                    ? null
                    : chatMessagePreview(
                      r.lastMsg?['message'] as String?,
                      r.lastMsg?['attachment_url'] as String?,
                    ),
            lastMessageSenderId: r.lastMsg?['sender_id'] as String?,
            lastMessageIsSystem:
                r.lastMsg?['is_system_message'] as bool? ?? false,
            unreadCount: r.unread,
            djAvatarUrl: djId != null ? imageMap[djId] : null,
            musicianAvatarUrl: musicianId != null ? imageMap[musicianId] : null,
            lastReactionEmoji: r.reaction?['emoji'] as String?,
            lastReactionUserId: r.reaction?['user_id'] as String?,
            lastReactionAt: r.reaction?['created_at'] as String?,
          );
        }).toList();

    // Pin the DJTILBUD support conversation to the top, then keep recency order for the rest.
    enriched.sort((a, b) {
      final aSupport = a.type == 'support' ? 1 : 0;
      final bSupport = b.type == 'support' ? 1 : 0;
      if (aSupport != bSupport) return bSupport - aSupport;
      return (b.lastMessageAt ?? '').compareTo(a.lastMessageAt ?? '');
    });

    return enriched;
  }

  Future<Map<String, dynamic>?> _fetchLastMessage(int conversationId) async {
    final response =
        await _client
            .from('ChatMessages')
            .select('message, sender_id, is_system_message, attachment_url')
            .eq('conversation_id', conversationId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
    return response;
  }

  /// The most recent reaction on a conversation (emoji + who + when), for the list preview
  /// ("<name> reagerede med <emoji>" when it's newer than the last message).
  Future<Map<String, dynamic>?> _fetchLatestReaction(int conversationId) async {
    return await _client
        .from('ChatMessageReactions')
        .select('emoji, user_id, created_at')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  Future<int> _fetchUnreadCount(
    int conversationId,
    String currentUserId,
  ) async {
    // A message is "incoming" (unread-eligible) when it's not from me OR it's an admin reply on the
    // support channel. The admin clause is what makes unread work when the same person is both an
    // admin and the musician (a shared account: admin replies carry sender_id == my uid). System
    // messages (the welcome) are never counted.
    final response = await _client
        .from('ChatMessages')
        .select('id')
        .eq('conversation_id', conversationId)
        .eq('is_system_message', false)
        .isFilter('read_at', null)
        .or('sender_id.neq.$currentUserId,sender_type.eq.admin');
    return (response as List).length;
  }

  Future<List<ChatMessageModel>> fetchMessages(int conversationId) async {
    final response = await _client
        .from('ChatMessages')
        .select('*')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
    return (response as List<dynamic>)
        .map((j) => ChatMessageModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Uploads a chat image to S3 (same presigned-PUT flow as profile media) and returns the
  /// public URL to store in `ChatMessages.attachment_url`. Unlike profile/job media, chat
  /// attachments are NOT recorded in `UserFiles` — the URL lives only on the message row.
  Future<String> uploadChatImage({
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
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  Future<ChatMessageModel> sendMessage({
    required int conversationId,
    required String senderId,
    required String senderType,
    required String message,
    int? replyToId,
    String? attachmentUrl,
  }) async {
    final response =
        await _client
            .from('ChatMessages')
            .insert({
              'conversation_id': conversationId,
              'sender_id': senderId,
              'sender_type': senderType,
              'message': message.trim(),
              'reply_to_id': replyToId,
              'attachment_url': attachmentUrl,
            })
            .select()
            .single();
    final msg = ChatMessageModel.fromJson(response);

    // Fire push notification fire-and-forget
    supabase.functions
        .invoke(
          'notify-chat-message',
          body: {
            'new': {
              'conversation_id': conversationId,
              'sender_id': senderId,
              'sender_type': senderType,
              'message': message.trim(),
              'reply_to_id': replyToId,
              'attachment_url': attachmentUrl,
              'is_system_message': false,
            },
          },
        )
        .then((_) {})
        .catchError((_) {});

    return msg;
  }

  Future<void> markMessagesAsRead({
    required int conversationId,
    required String currentUserId,
  }) async {
    // Mark incoming messages read: not from me, OR an admin reply (support shared-account case —
    // see _fetchUnreadCount). The support RLS policy (migration 20260623000003) permits updating
    // admin messages whose sender_id == my uid.
    await _client
        .from('ChatMessages')
        // MUST be UTC: read_at is a timestamptz. DateTime.now().toIso8601String() emits local
        // wall-clock with NO offset, so Postgres stores it as UTC → the "Set kl" the admin sees is
        // shifted by the reader's UTC offset (e.g. +2h in Denmark). .toUtc() writes a real instant.
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('conversation_id', conversationId)
        .isFilter('read_at', null)
        .or('sender_id.neq.$currentUserId,sender_type.eq.admin');
  }

  Future<List<MessageReaction>> fetchReactions(int conversationId) async {
    final response = await _client
        .from('ChatMessageReactions')
        .select('message_id, user_id, emoji')
        .eq('conversation_id', conversationId);
    return (response as List<dynamic>).map((j) {
      final m = j as Map<String, dynamic>;
      return MessageReaction(
        messageId: (m['message_id'] as num).toInt(),
        userId: m['user_id'] as String,
        emoji: m['emoji'] as String,
      );
    }).toList();
  }

  /// Toggle the current user's emoji reaction on a message (one per user): same emoji removes,
  /// different/none sets. Direct Supabase write — RLS permits a participant to write their own.
  Future<void> toggleReaction({
    required int messageId,
    required int conversationId,
    required String userId,
    required String emoji,
  }) async {
    final existing =
        await _client
            .from('ChatMessageReactions')
            .select('id, emoji')
            .eq('message_id', messageId)
            .eq('user_id', userId)
            .maybeSingle();

    if (existing != null && existing['emoji'] == emoji) {
      await _client
          .from('ChatMessageReactions')
          .delete()
          .eq('id', existing['id'] as int);
    } else {
      await _client.from('ChatMessageReactions').upsert({
        'message_id': messageId,
        'conversation_id': conversationId,
        'user_id': userId,
        'emoji': emoji,
      }, onConflict: 'message_id,user_id');
      // Notify the message author (fire-and-forget; never on un-react).
      supabase.functions
          .invoke(
            'notify-chat-reaction',
            body: {
              'message_id': messageId,
              'conversation_id': conversationId,
              'reactor_id': userId,
              'emoji': emoji,
            },
          )
          .then((_) {})
          .catchError((_) {});
    }
  }
}
