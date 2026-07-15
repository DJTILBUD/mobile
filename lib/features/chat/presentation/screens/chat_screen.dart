import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/router/app_routes.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/conversation.dart';
import 'package:dj_tilbud_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:dj_tilbud_app/features/chat/presentation/providers/admin_support_provider.dart';
import 'package:dj_tilbud_app/features/chat/data/datasources/admin_support_datasource.dart';
import 'package:dj_tilbud_app/features/chat/presentation/screens/admin_support_thread_screen.dart';
import 'package:dj_tilbud_app/features/chat/presentation/widgets/new_support_message_sheet.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/shared/widgets/conversation_avatar.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _c = DSTheme.of(context);
    // Admin users get a second "Support" tab (the in-app admin inbox). Non-admins never see it.
    final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: _c.bg.surface,
        appBar: AppBar(
          title: const Text('Beskeder'),
          backgroundColor: _c.bg.surface,
          surfaceTintColor: _c.bg.surface,
        ),
        body: const _MyConversationsTab(),
      );
    }

    final unread = ref.watch(adminSupportUnreadCountProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _c.bg.surface,
        appBar: AppBar(
          title: const Text('Beskeder'),
          backgroundColor: _c.bg.surface,
          surfaceTintColor: _c.bg.surface,
          bottom: TabBar(
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Support'),
                    if (unread > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _c.brand.primaryActive,
                          borderRadius: BorderRadius.circular(DSRadius.pill),
                        ),
                        child: Text(
                          '$unread',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(text: 'Beskeder'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_AdminSupportTab(), _MyConversationsTab()],
        ),
      ),
    );
  }
}

class _MyConversationsTab extends ConsumerWidget {
  const _MyConversationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _c = DSTheme.of(context);
    final conversationsAsync = ref.watch(conversationsProvider);

    return conversationsAsync.when(
      loading: () => const _ConversationListSkeleton(),
      error:
          (e, _) => _ErrorView(
            onRetry: () => ref.read(conversationsProvider.notifier).refresh(),
          ),
      data:
          (conversations) =>
              conversations.isEmpty
                  ? const _EmptyConversationsView()
                  : RefreshIndicator(
                    onRefresh:
                        () =>
                            ref.read(conversationsProvider.notifier).refresh(),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: conversations.length,
                      separatorBuilder:
                          (_, __) => Divider(
                            height: 1,
                            color: _c.border.subtle,
                            indent: 72,
                          ),
                      itemBuilder:
                          (context, i) =>
                              _ConversationTile(conversation: conversations[i]),
                    ),
                  ),
    );
  }
}

class _AdminSupportTab extends ConsumerStatefulWidget {
  const _AdminSupportTab();

  @override
  ConsumerState<_AdminSupportTab> createState() => _AdminSupportTabState();
}

class _AdminSupportTabState extends ConsumerState<_AdminSupportTab> {
  final _searchController = TextEditingController();
  String _query = '';
  Timer? _debounce;
  // Last successfully-loaded threads, so typing another search char (a new provider key) keeps the
  // current results on screen instead of flashing the skeleton between keystrokes.
  List<AdminSupportThread>? _lastThreads;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _retry() {
    if (_query.isNotEmpty) {
      ref.invalidate(adminSupportSearchProvider(_query));
    } else {
      ref.read(adminSupportThreadsProvider.notifier).refresh();
    }
  }

  Widget _buildBody(
    BuildContext context,
    AsyncValue<List<AdminSupportThread>> async,
    bool searching,
  ) {
    final data = async.valueOrNull;
    if (data != null) _lastThreads = data;
    // While a new query loads, keep the previous results visible (no skeleton flash).
    if (async.isLoading && _lastThreads != null) {
      return _threadListView(context, _lastThreads!, searching);
    }
    return async.when(
      loading: () => const _ConversationListSkeleton(),
      error: (e, _) => _ErrorView(onRetry: _retry),
      data:
          (threads) =>
              threads.isEmpty
                  ? _emptyState(context, searching)
                  : _threadListView(context, threads, searching),
    );
  }

  Widget _emptyState(BuildContext context, bool searching) {
    final c = DSTheme.of(context);
    return Center(
      child: Text(
        searching ? 'Ingen resultater for "$_query"' : 'Ingen support-samtaler',
        style: DSTextStyle.bodyMd.copyWith(color: c.text.muted),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _threadListView(
    BuildContext context,
    List<AdminSupportThread> threads,
    bool searching,
  ) {
    final c = DSTheme.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        if (searching) {
          ref.invalidate(adminSupportSearchProvider(_query));
        } else {
          await ref.read(adminSupportThreadsProvider.notifier).refresh();
        }
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: threads.length,
        separatorBuilder:
            (_, __) => Divider(height: 1, color: c.border.subtle, indent: 72),
        itemBuilder:
            (context, i) => _AdminThreadTile(
              thread: threads[i],
              searchTerm: searching ? _query : null,
            ),
      ),
    );
  }

  void _onChanged(String v) {
    // Match the admin tool's 180ms debounce before hitting the server search.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _query = v.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final searching = _query.isNotEmpty;
    // Empty query = the live (realtime) list; a query = server-side name+message search.
    final threadsAsync =
        searching
            ? ref.watch(adminSupportSearchProvider(_query))
            : ref.watch(adminSupportThreadsProvider);

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DSSpacing.s3,
                DSSpacing.s2,
                DSSpacing.s3,
                DSSpacing.s2,
              ),
              child: DSInput(
                controller: _searchController,
                hint: 'Søg i support (navn eller besked)',
                iconLeft: LucideIcons.search,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
              ),
            ),
            Expanded(child: _buildBody(context, threadsAsync, searching)),
          ],
        ),
        Positioned(
          right: DSSpacing.s4,
          bottom: DSSpacing.s4,
          child: FloatingActionButton(
            onPressed: _openComposer,
            backgroundColor: _c.brand.primary,
            foregroundColor: _c.brand.onPrimary,
            child: const Icon(LucideIcons.messageSquarePlus),
          ),
        ),
      ],
    );
  }

  Future<void> _openComposer() async {
    final thread = await showModalBottomSheet<AdminSupportThread>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DSTheme.of(context).bg.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DSRadius.lg)),
      ),
      builder: (_) => const NewSupportMessageSheet(),
    );
    if (thread == null || !mounted) return;
    // Refresh the inbox so the new thread appears, then open it.
    ref.read(adminSupportThreadsProvider.notifier).refresh();
    if (!context.mounted) return;
    context.pushNamed(
      AppRoutes.adminSupportThread,
      extra: AdminSupportThreadArgs(thread: thread),
    );
  }
}

class _AdminThreadTile extends ConsumerWidget {
  const _AdminThreadTile({required this.thread, this.searchTerm});

  final AdminSupportThread thread;

  /// When set (searching), the name is highlighted and the matching messages are listed below.
  final String? searchTerm;

  void _open(BuildContext context, {int? messageId}) {
    context.pushNamed(
      AppRoutes.adminSupportThread,
      extra: AdminSupportThreadArgs(
        thread: thread,
        initialMessageId: messageId,
      ),
    );
  }

  /// Long-press menu: mark the thread read/unread (team-wide). Optimistic — the list updates
  /// instantly and the badge follows; the web endpoint + Realtime reconcile in the background.
  Future<void> _showThreadMenu(BuildContext context, WidgetRef ref) async {
    final c = DSTheme.of(context);
    final notifier = ref.read(adminSupportThreadsProvider.notifier);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.bg.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DSRadius.lg)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DSSpacing.s4,
                  DSSpacing.s4,
                  DSSpacing.s4,
                  DSSpacing.s2,
                ),
                child: Row(
                  children: [
                    ConversationAvatar(
                      name: thread.userName,
                      imageUrl: thread.userAvatarUrl,
                    ),
                    const SizedBox(width: DSSpacing.s3),
                    Expanded(
                      child: Text(
                        thread.userName,
                        style: DSTextStyle.headingSm.copyWith(
                          color: c.text.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: c.border.subtle),
              // Handled sits ABOVE read/unread on purpose: it is the one that means "does this
              // still need an answer", and it is what the Support badge counts. Read only says
              // whether anyone has looked, and clears for the whole team the moment one admin opens
              // the thread. Coloured so the actionable state (needs handling) reads at a glance.
              ListTile(
                leading: Icon(
                  thread.handled
                      ? LucideIcons.rotateCcw
                      : LucideIcons.checkCircle2,
                  color: thread.handled ? c.text.secondary : c.state.success,
                ),
                title: Text(
                  thread.handled
                      ? 'Markér som ikke håndteret'
                      : 'Markér som håndteret',
                ),
                subtitle: Text(
                  thread.handled
                      ? 'Sætter den tilbage i køen'
                      : 'Fjerner den fra køen. Et svar gør det automatisk.',
                  style: DSTextStyle.bodySm.copyWith(color: c.text.muted),
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final err = await notifier.setThreadHandled(
                    thread.id,
                    !thread.handled,
                  );
                  if (err != null && context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(err)));
                  }
                },
              ),
              Divider(height: 1, color: c.border.subtle),
              if (thread.hasUnread)
                ListTile(
                  leading: Icon(
                    LucideIcons.checkCheck,
                    color: c.text.secondary,
                  ),
                  title: const Text('Marker som læst'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    notifier.markThreadRead(thread.id);
                  },
                )
              else
                ListTile(
                  leading: Icon(
                    LucideIcons.mailWarning,
                    color: c.text.secondary,
                  ),
                  title: const Text('Marker som ulæst'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    notifier.markThreadUnread(thread.id);
                  },
                ),
              ListTile(
                leading: Icon(
                  LucideIcons.messageSquare,
                  color: c.text.secondary,
                ),
                title: const Text('Åbn samtale'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _open(context);
                },
              ),
              const SizedBox(height: DSSpacing.s2),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _c = DSTheme.of(context);
    final hasUnread = thread.hasUnread;
    // Needs-handling wins the row tint over unread: unread clears for the whole team the
    // moment anyone opens the thread, so it stops marking work. Mirrors the admin tool's inbox.
    final needsHandling = thread.needsHandling;
    final term = searchTerm;
    final matches = thread.matches;

    return InkWell(
      onTap: () => _open(context),
      onLongPress: () => _showThreadMenu(context, ref),
      child: Container(
        color:
            needsHandling
                ? _c.state.warning.withValues(alpha: 0.10)
                : hasUnread
                ? _c.brand.primary.withValues(alpha: 0.06)
                : null,
        padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s4,
          vertical: DSSpacing.s3,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConversationAvatar(
              name: thread.userName,
              imageUrl: thread.userAvatarUrl,
            ),
            const SizedBox(width: DSSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: _HighlightedText(
                          text: thread.userName,
                          term: term,
                          style: DSTextStyle.headingSm.copyWith(
                            fontSize: 15,
                            color: _c.text.primary,
                            fontWeight:
                                hasUnread ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                      ),
                      // Mirrors the admin tool's inbox: says WHAT is wrong rather than relying
                      // on the amber tint alone. Survives being read, unlike the unread bolding.
                      if (needsHandling) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: _c.state.warning.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(DSRadius.pill),
                          ),
                          child: Text(
                            'Mangler svar',
                            style: DSTextStyle.labelSm.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _c.state.warning,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  // When searching, show the matching messages instead of the last-message preview.
                  if (term != null && matches.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    ...matches.map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: InkWell(
                          onTap: () => _open(context, messageId: m.id),
                          child: _HighlightedText(
                            text: _snippet(m.message, term),
                            term: term,
                            style: DSTextStyle.labelMd.copyWith(
                              color: _c.text.secondary,
                            ),
                            maxLines: 2,
                          ),
                        ),
                      ),
                    ),
                    if (thread.matchCount > matches.length)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          '+${thread.matchCount - matches.length} flere',
                          style: DSTextStyle.labelSm.copyWith(
                            color: _c.text.muted,
                          ),
                        ),
                      ),
                  ] else if (thread.lastMessage != null)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.lastMessage!,
                            style: DSTextStyle.labelMd.copyWith(
                              color:
                                  hasUnread ? _c.text.primary : _c.text.muted,
                              fontWeight:
                                  hasUnread ? FontWeight.w700 : FontWeight.w400,
                              fontStyle:
                                  thread.lastMessageIsSystem
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: DSSpacing.s2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _c.brand.primaryActive,
                              borderRadius: BorderRadius.circular(
                                DSRadius.pill,
                              ),
                            ),
                            child: Text(
                              '${thread.unreadCount}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Windows a long message to ~45 chars around the first case-insensitive hit, with ellipses.
  String _snippet(String message, String term) {
    final lower = message.toLowerCase();
    final idx = lower.indexOf(term.toLowerCase());
    if (idx < 0)
      return message.length > 90 ? '${message.substring(0, 90)}…' : message;
    final start = (idx - 45).clamp(0, message.length);
    final end = (idx + term.length + 45).clamp(0, message.length);
    final core = message.substring(start, end);
    return '${start > 0 ? '…' : ''}$core${end < message.length ? '…' : ''}';
  }
}

/// Text that highlights every case-insensitive occurrence of [term] with an amber background.
/// [term] null/empty renders plain text.
class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.style,
    this.term,
    this.maxLines = 1,
  });

  final String text;
  final TextStyle style;
  final String? term;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final t = term?.trim() ?? '';
    if (t.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }
    final lower = text.toLowerCase();
    final needle = t.toLowerCase();
    final spans = <TextSpan>[];
    int i = 0;
    while (i < text.length) {
      final hit = lower.indexOf(needle, i);
      if (hit < 0) {
        spans.add(TextSpan(text: text.substring(i)));
        break;
      }
      if (hit > i) spans.add(TextSpan(text: text.substring(i, hit)));
      spans.add(
        TextSpan(
          text: text.substring(hit, hit + t.length),
          style: const TextStyle(
            backgroundColor: Color(0xFFFFE082),
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      i = hit + t.length;
    }
    return Text.rich(
      TextSpan(style: style, children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final lastMsgTime = conversation.lastMessageAt;
    final timeLabel = lastMsgTime != null ? _formatTime(lastMsgTime) : '';

    final hasUnread = conversation.hasUnread;
    final unreadCount = conversation.unreadCount;

    return InkWell(
      onTap:
          () => context.pushNamed(
            AppRoutes.conversationDetail,
            extra: conversation,
          ),
      child: Container(
        color: hasUnread ? _c.brand.primary.withValues(alpha: 0.06) : null,
        padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s4,
          vertical: DSSpacing.s3,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            ConversationAvatar(
              name: conversation.partnerName,
              imageUrl: conversation.partnerAvatarUrl,
              isSupport: conversation.isSupport,
            ),
            const SizedBox(width: DSSpacing.s3),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.partnerName,
                          style: DSTextStyle.headingSm.copyWith(
                            fontSize: 15,
                            color: _c.text.primary,
                            fontWeight:
                                hasUnread ? FontWeight.w800 : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timeLabel.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          timeLabel,
                          style: DSTextStyle.bodySm.copyWith(
                            color:
                                hasUnread
                                    ? _c.brand.primaryActive
                                    : _c.text.muted,
                            fontWeight:
                                hasUnread ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    conversation.jobInfo,
                    style: DSTextStyle.bodySm.copyWith(
                      color: hasUnread ? _c.text.secondary : _c.text.muted,
                      fontWeight:
                          hasUnread ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (conversation.lastMessageText != null ||
                      conversation.reactionPreview != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            _buildPreview(conversation),
                            style: DSTextStyle.labelMd.copyWith(
                              color:
                                  hasUnread ? _c.text.primary : _c.text.muted,
                              fontWeight:
                                  hasUnread ? FontWeight.w700 : FontWeight.w400,
                              fontStyle:
                                  conversation.reactionPreview == null &&
                                          conversation.lastMessageIsSystem
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: DSSpacing.s2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _c.brand.primaryActive,
                              borderRadius: BorderRadius.circular(
                                DSRadius.pill,
                              ),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildPreview(Conversation c) {
    // A reaction newer than the last message wins ("DJTILBUD reagerede med 👍").
    if (c.reactionPreview != null) return c.reactionPreview!;
    final text = c.lastMessageText ?? '';
    if (c.lastMessageIsSystem) return text;
    final prefix = c.isLastMessageFromMe ? 'Du: ' : '';
    return '$prefix$text';
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(local.year, local.month, local.day);

    if (msgDay == today) {
      final h = local.hour.toString().padLeft(2, '0');
      final m = local.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    const months = [
      'januar',
      'februar',
      'marts',
      'april',
      'maj',
      'juni',
      'juli',
      'august',
      'september',
      'oktober',
      'november',
      'december',
    ];
    return '${local.day}. ${months[local.month - 1]}';
  }
}

// ─── Conversation Avatar ──────────────────────────────────────────────────────

class _ConversationListSkeleton extends StatelessWidget {
  const _ConversationListSkeleton();

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      separatorBuilder:
          (_, __) => Divider(height: 1, color: _c.border.subtle, indent: 72),
      itemBuilder:
          (_, __) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DSSpacing.s4,
              vertical: DSSpacing.s3,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _c.border.subtle,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: DSSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 140,
                        decoration: BoxDecoration(
                          color: _c.border.subtle,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 11,
                        width: 100,
                        decoration: BoxDecoration(
                          color: _c.border.subtle,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 12,
                        width: 200,
                        decoration: BoxDecoration(
                          color: _c.border.subtle,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _EmptyConversationsView extends StatelessWidget {
  const _EmptyConversationsView();

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.messageCircle, size: 64, color: _c.border.strong),
          const SizedBox(height: DSSpacing.s4),
          Text(
            'Ingen beskeder endnu',
            style: DSTextStyle.headingMd.copyWith(color: _c.text.primary),
          ),
          const SizedBox(height: DSSpacing.s2),
          Text(
            'Dine samtaler med kunder vises her.',
            style: DSTextStyle.bodyMd.copyWith(color: _c.text.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.alertCircle, size: 48, color: _c.state.danger),
          const SizedBox(height: DSSpacing.s3),
          Text(
            'Kunne ikke hente beskeder',
            style: DSTextStyle.headingSm.copyWith(color: _c.text.primary),
          ),
          const SizedBox(height: DSSpacing.s4),
          DSButton(
            label: 'Prøv igen',
            variant: DSButtonVariant.secondary,
            onTap: onRetry,
          ),
        ],
      ),
    );
  }
}
