import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dj_tilbud_app/features/chat/data/models/conversation_model.dart';
import 'package:dj_tilbud_app/features/chat/data/models/chat_message_model.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';

class ChatRemoteDatasource {
  const ChatRemoteDatasource(this._client);

  final SupabaseClient _client;

  Future<List<ConversationModel>> fetchConversations(String currentUserId) async {
    final response = await _client
        .from('Conversations')
        .select('''
          *,
          job:Jobs!Conversations_job_id_fkey(id, event_type, date),
          ext_job:ExtJobs!Conversations_ext_job_id_fkey(id, event_type, date, assigned_dj_name),
          dj:DjInfos!Conversations_dj_id_fkey(id, full_name),
          musician:Musicians!Conversations_musician_id_fkey(id, full_name, instrument)
        ''')
        .order('last_message_at', ascending: false);

    final rawList = (response as List<dynamic>).cast<Map<String, dynamic>>();

    // Filter to only chat-enabled conversations
    final filtered = rawList.where((json) {
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
    final imagesFuture = partnerIds.isNotEmpty
        ? _client
            .from('UserFiles')
            .select('user_id, url')
            .inFilter('user_id', partnerIds.toList())
            .eq('type', 'profile')
            .order('created_at', ascending: false)
        : Future.value(<Map<String, dynamic>>[]);

    final enrichedAndImages = await Future.wait([
      Future.wait(filtered.map((json) async {
        final id = (json['id'] as num).toInt();
        final results = await Future.wait([
          _fetchLastMessage(id),
          _fetchUnreadCount(id, currentUserId),
        ]);
        return (json: json, lastMsg: results[0] as Map<String, dynamic>?, unread: results[1] as int);
      })),
      imagesFuture,
    ]);

    final msgResults = enrichedAndImages[0] as List<({Map<String, dynamic> json, Map<String, dynamic>? lastMsg, int unread})>;
    final imageRows = (enrichedAndImages[1] as List<dynamic>).cast<Map<String, dynamic>>();

    // Build userId → first profile image URL map
    final imageMap = <String, String>{};
    for (final row in imageRows) {
      final uid = row['user_id'] as String;
      if (!imageMap.containsKey(uid)) {
        imageMap[uid] = row['url'] as String;
      }
    }

    final enriched = msgResults.map((r) {
      final djId = r.json['dj_id'] as String?;
      final musicianId = r.json['musician_id'] as String?;
      return ConversationModel.fromJson(
        r.json,
        lastMessageText: r.lastMsg?['message'] as String?,
        lastMessageSenderId: r.lastMsg?['sender_id'] as String?,
        lastMessageIsSystem: r.lastMsg?['is_system_message'] as bool? ?? false,
        unreadCount: r.unread,
        djAvatarUrl: djId != null ? imageMap[djId] : null,
        musicianAvatarUrl: musicianId != null ? imageMap[musicianId] : null,
      );
    }).toList();

    return enriched;
  }

  Future<Map<String, dynamic>?> _fetchLastMessage(int conversationId) async {
    final response = await _client
        .from('ChatMessages')
        .select('message, sender_id, is_system_message')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return response;
  }

  Future<int> _fetchUnreadCount(int conversationId, String currentUserId) async {
    final response = await _client
        .from('ChatMessages')
        .select('id')
        .eq('conversation_id', conversationId)
        .neq('sender_id', currentUserId)
        .isFilter('read_at', null);
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

  Future<ChatMessageModel> sendMessage({
    required int conversationId,
    required String senderId,
    required String senderType,
    required String message,
  }) async {
    final response = await _client
        .from('ChatMessages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': senderId,
          'sender_type': senderType,
          'message': message.trim(),
        })
        .select()
        .single();
    final msg = ChatMessageModel.fromJson(response);

    // Fire push notification fire-and-forget
    supabase.functions.invoke(
      'notify-chat-message',
      body: {
        'new': {
          'conversation_id': conversationId,
          'sender_id': senderId,
          'sender_type': senderType,
          'message': message.trim(),
          'is_system_message': false,
        },
      },
    ).catchError((_) {});

    return msg;
  }

  Future<void> markMessagesAsRead({
    required int conversationId,
    required String currentUserId,
  }) async {
    await _client
        .from('ChatMessages')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('conversation_id', conversationId)
        .neq('sender_id', currentUserId)
        .isFilter('read_at', null);
  }
}
