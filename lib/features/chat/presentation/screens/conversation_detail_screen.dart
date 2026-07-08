import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/notifications/in_app_notification_provider.dart';
import 'package:dj_tilbud_app/core/router/app_routes.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/chat_message.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/conversation.dart';
import 'package:dj_tilbud_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:dj_tilbud_app/features/chat/presentation/providers/typing_provider.dart';
import 'package:dj_tilbud_app/features/chat/presentation/providers/reactions_provider.dart';
import 'package:dj_tilbud_app/features/chat/presentation/providers/job_links_provider.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/job_link.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:dj_tilbud_app/features/jobs/data/models/dj_quote_model.dart';
import 'package:dj_tilbud_app/features/jobs/data/models/ext_job_model.dart';
import 'package:dj_tilbud_app/features/jobs/data/models/job_model.dart';
import 'package:dj_tilbud_app/features/jobs/data/models/service_offer_model.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _kQuickReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

/// Opens an attached chat image fullscreen (pinch-to-zoom, tap to dismiss).
void _showFullImage(BuildContext context, String url) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black,
    builder:
        (ctx) => GestureDetector(
          onTap: () => Navigator.of(ctx).pop(),
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: MediaQuery.of(ctx).padding.top + 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
        ),
  );
}

class ConversationDetailScreen extends ConsumerStatefulWidget {
  const ConversationDetailScreen({super.key, required this.conversation});

  final Conversation conversation;

  @override
  ConsumerState<ConversationDetailScreen> createState() =>
      _ConversationDetailScreenState();
}

class _ConversationDetailScreenState
    extends ConsumerState<ConversationDetailScreen>
    with WidgetsBindingObserver {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _searchController = TextEditingController();
  bool _isSending = false;
  String? _errorMsg;
  // Image staged in the composer — uploaded to S3 only when the message is sent.
  XFile? _pendingImage;
  ChatMessage? _replyTo;
  int? _highlightId; // message to flash after tapping a reply quote
  OverlayEntry? _reactionBar;
  // In-conversation search: filter this chat to messages containing the term.
  bool _searchOpen = false;
  String _searchTerm = '';
  // Composer "@" job picker: the active query + the index of its "@".
  String? _mentionQuery;
  int _mentionStart = -1;
  // Debounced query actually sent to the search API (avoids a request per keystroke).
  String _mentionSearchQuery = '';
  Timer? _mentionDebounce;

  // Captured in initState so they can be safely called from dispose()
  late final StateController<int?> _activeConvNotifier;
  late final StateController<bool> _suppressDismissBarNotifier;

  String get _currentUserId => supabase.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activeConvNotifier = ref.read(activeConversationIdProvider.notifier);
    _suppressDismissBarNotifier = ref.read(
      suppressKeyboardDismissBarProvider.notifier,
    );
    // Broadcast "is typing" to the admin team on the support channel.
    if (widget.conversation.isSupport) {
      _textController.addListener(_onTypingChanged);
    }
    // Detect "@..." for the job-link picker.
    _textController.addListener(_onComposerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Mark this conversation as active so foreground FCM banners are suppressed
      _activeConvNotifier.state = widget.conversation.id;
      // Hide the global keyboard dismiss bar — the chat input is already at the
      // bottom of the screen, and the bar would overlay it.
      _suppressDismissBarNotifier.state = true;
      _markAsRead();
      // Force a fresh message fetch: the provider may be reused from a previous
      // visit (autoDispose can keep it alive across same-frame navigation), so
      // stale state would be shown without this refresh.
      ref
          .read(conversationMessagesProvider(widget.conversation.id).notifier)
          .refresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Supabase Realtime can miss messages delivered while the app was backgrounded,
    // so re-fetch (and mark read) on resume instead of waiting for a manual refresh.
    if (state == AppLifecycleState.resumed && mounted) {
      ref
          .read(conversationMessagesProvider(widget.conversation.id).notifier)
          .refresh();
      _markAsRead();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Defer state writes — Riverpod disallows provider mutations during
    // widget tree finalization (dispose is called while the tree is unmounting).
    Future.microtask(() {
      _activeConvNotifier.state = null;
      _suppressDismissBarNotifier.state = false;
    });
    _dismissReactionBar();
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _searchController.dispose();
    _mentionDebounce?.cancel();
    super.dispose();
  }

  Future<void> _markAsRead() async {
    await ref
        .read(conversationMessagesProvider(widget.conversation.id).notifier)
        .markAsRead(_currentUserId);
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    if (animate) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void _onTypingChanged() {
    if (_textController.text.isEmpty) return;
    ref
        .read(supportTypingProvider(widget.conversation.id).notifier)
        .notifyTyping();
  }

  void _startReply(ChatMessage m) {
    _dismissReactionBar();
    setState(() => _replyTo = m);
    _focusNode.requestFocus();
  }

  void _react(ChatMessage m, String emoji) {
    ref
        .read(conversationReactionsProvider(widget.conversation.id).notifier)
        .toggle(messageId: m.id, emoji: emoji, userId: _currentUserId);
  }

  void _dismissReactionBar() {
    _reactionBar?.remove();
    _reactionBar = null;
  }

  /// Messenger-style floating reaction bar shown on long-press, near the finger.
  void _showReactionBar(Offset globalPos, ChatMessage m) {
    _dismissReactionBar();
    // Messenger-style: a short haptic the moment the emoji bar pops up.
    HapticFeedback.mediumImpact();
    final _c = DSTheme.of(context);
    final size = MediaQuery.of(context).size;
    const barWidth = 296.0;
    final left = (globalPos.dx - barWidth / 2).clamp(
      8.0,
      size.width - barWidth - 8.0,
    );
    final top = (globalPos.dy - 70).clamp(90.0, size.height - 140);
    final myEmoji = ref
        .read(conversationReactionsProvider(widget.conversation.id).notifier)
        .myEmoji(m.id, _currentUserId);

    _reactionBar = OverlayEntry(
      builder:
          (ctx) => Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _dismissReactionBar,
                ),
              ),
              Positioned(
                left: left,
                top: top,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _c.bg.surface,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final e in _kQuickReactions)
                          GestureDetector(
                            onTap: () {
                              _dismissReactionBar();
                              _react(m, e);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              decoration:
                                  e == myEmoji
                                      ? BoxDecoration(
                                        color: _c.brand.primary.withValues(
                                          alpha: 0.25,
                                        ),
                                        shape: BoxShape.circle,
                                      )
                                      : null,
                              child: Text(
                                e,
                                style: const TextStyle(fontSize: 26),
                              ),
                            ),
                          ),
                        Container(
                          width: 1,
                          height: 24,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          color: _c.border.subtle,
                        ),
                        GestureDetector(
                          onTap: () {
                            _dismissReactionBar();
                            _startReply(m);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.reply,
                              size: 24,
                              color: _c.text.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
    Overlay.of(context).insert(_reactionBar!);
  }

  void _jumpToMessage(int messageId) {
    setState(() => _highlightId = messageId);
    // The flash clears itself after a moment.
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted && _highlightId == messageId)
        setState(() => _highlightId = null);
    });
  }

  void _closeSearch() {
    setState(() {
      _searchOpen = false;
      _searchTerm = '';
    });
    _searchController.clear();
  }

  // Updates the "@" mention query from the composer's text + caret.
  void _onComposerChanged() {
    final sel = _textController.selection;
    final text = _textController.text;
    if (!sel.isValid || sel.baseOffset < 0) return _setMention(null, -1);
    final caret = sel.baseOffset.clamp(0, text.length);
    final upto = text.substring(0, caret);
    final at = upto.lastIndexOf('@');
    if (at == -1) return _setMention(null, -1);
    final between = upto.substring(at + 1);
    if (between.contains(RegExp(r'\s'))) return _setMention(null, -1);
    if (RegExp(r'^(job|extjob):\d+$').hasMatch(between)) {
      return _setMention(null, -1);
    }
    _setMention(between, at);
  }

  void _setMention(String? query, int start) {
    if (query == _mentionQuery && start == _mentionStart) return;
    setState(() {
      _mentionQuery = query;
      _mentionStart = start;
    });
    // Debounce the actual search so we don't fire one request per keystroke.
    _mentionDebounce?.cancel();
    if (query == null) {
      setState(() => _mentionSearchQuery = '');
      return;
    }
    _mentionDebounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _mentionSearchQuery = query);
    });
  }

  void _insertJobToken(LinkableJob job) {
    final text = _textController.text;
    final caret = _textController.selection.baseOffset.clamp(0, text.length);
    if (_mentionStart < 0 || _mentionStart > text.length) return;
    // Never let the prefix/suffix slices overlap if the caret moved before "@".
    final start = _mentionStart < caret ? _mentionStart : caret;
    final newText =
        '${text.substring(0, start)}@${job.ref} ${text.substring(caret)}';
    final newCaret = start + job.ref.length + 2; // "@" + ref + trailing space
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCaret),
    );
    setState(() {
      _mentionQuery = null;
      _mentionStart = -1;
    });
  }

  /// Opens a tapped job link. Mirrors NotificationsService.navigateTo: fetch the
  /// entity by id, then go to the right tab + push the detail screen. Only
  /// reached for links the server already marked accessible for this viewer.
  Future<void> _openJobTarget(JobLinkTarget target) async {
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // Push the job detail ON TOP of the chat (unlike the notification-tap path, which resets to
    // home first), so the back button returns to the conversation instead of the home feed.
    try {
      switch (target.kind) {
        case 'dj_quote':
          final json =
              await supabase
                  .from('Quotes')
                  .select('*, job:Jobs(*)')
                  .eq('id', target.id)
                  .single();
          final quote = DjQuoteModel.fromJson(json).toEntity();
          router.pushNamed(AppRoutes.quoteDetail, extra: quote);
        case 'dj_open_job':
          final json =
              await supabase.from('Jobs').select().eq('id', target.id).single();
          final job = JobModel.fromJson(json).toEntity();
          router.pushNamed(AppRoutes.djQuoteForm, extra: job);
        case 'dj_ext_job':
          final json =
              await supabase
                  .from('ExtJobs')
                  .select()
                  .eq('id', target.id)
                  .single();
          final extJob = ExtJobModel.fromJson(json).toEntity();
          router.pushNamed(AppRoutes.extJobDetail, extra: extJob);
        case 'musician_offer':
          final json =
              await supabase
                  .from('ServiceOffers')
                  .select(
                    '*, job:Jobs!ServiceOffers_job_id_fkey(*), ext_job:ExtJobs!ServiceOffers_ext_job_id_fkey(*)',
                  )
                  .eq('id', target.id)
                  .single();
          final offer = ServiceOfferModel.fromJson(json).toEntity();
          router.pushNamed(AppRoutes.serviceOfferDetail, extra: offer);
        case 'musician_ext_job':
          final json =
              await supabase
                  .from('ExtJobs')
                  .select()
                  .eq('id', target.id)
                  .single();
          final extJob = ExtJobModel.fromJson(json).toEntity();
          router.pushNamed(AppRoutes.extJobDetail, extra: extJob);
        case 'musician_open_job':
          final json =
              await supabase.from('Jobs').select().eq('id', target.id).single();
          final job = JobModel.fromJson(json).toEntity();
          router.pushNamed(AppRoutes.instrumentalistOfferForm, extra: job);
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Kunne ikke åbne jobbet')),
      );
    }
  }

  Future<void> _pickImage() async {
    if (_isSending) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1920,
    );
    if (picked == null) return;
    setState(() {
      _pendingImage = picked;
      _errorMsg = null;
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    final image = _pendingImage;
    if ((text.isEmpty && image == null) || _isSending) return;

    final replyToId = _replyTo?.id;
    setState(() {
      _isSending = true;
      _errorMsg = null;
      _replyTo = null;
    });
    _textController.clear();

    final notifier = ref.read(
      conversationMessagesProvider(widget.conversation.id).notifier,
    );

    // Upload the staged image first (if any), then send the message.
    String? attachmentUrl;
    if (image != null) {
      try {
        attachmentUrl = await notifier.uploadImage(
          userId: _currentUserId,
          filePath: image.path,
        );
      } catch (_) {
        if (mounted) {
          setState(() {
            _isSending = false;
            _errorMsg = 'Billedet kunne ikke uploades. Prøv igen.';
            _textController.text = text;
          });
        }
        return;
      }
    }

    final error = await notifier.sendMessage(
      senderId: _currentUserId,
      senderType: widget.conversation.senderType,
      message: text,
      replyToId: replyToId,
      attachmentUrl: attachmentUrl,
    );

    if (mounted) {
      setState(() {
        _isSending = false;
        if (error == null) {
          _pendingImage = null;
        } else {
          _errorMsg = error;
          _textController.text = text;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final messagesAsync = ref.watch(
      conversationMessagesProvider(widget.conversation.id),
    );
    // "DJTILBUD is typing" — only on the support channel.
    final adminTyping =
        widget.conversation.isSupport &&
        ref.watch(supportTypingProvider(widget.conversation.id));
    final reactions = ref.watch(
      conversationReactionsProvider(widget.conversation.id),
    );

    ref.listen(conversationMessagesProvider(widget.conversation.id), (
      previous,
      next,
    ) {
      final prevCount = previous?.valueOrNull?.length ?? 0;
      final nextCount = next.valueOrNull?.length ?? 0;
      if (nextCount > prevCount) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
          _markAsRead();
        });
      }
    });

    return Scaffold(
      backgroundColor: _c.bg.surface,
      // Take manual control of keyboard avoidance: the routed content sits in a
      // Stack (MaterialApp.builder), where the Scaffold's own auto-resize is
      // unreliable, so we pad the body by viewInsets.bottom below instead.
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: _c.bg.surface,
        surfaceTintColor: _c.bg.surface,
        titleSpacing: 0,
        title:
            _searchOpen
                ? Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _c.bg.canvas,
                    borderRadius: BorderRadius.circular(DSRadius.md),
                    border: Border.all(color: _c.border.subtle),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 18, color: _c.text.muted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: DSTextStyle.bodyMd.copyWith(
                            color: _c.text.primary,
                          ),
                          cursorColor: _c.brand.primaryActive,
                          decoration: InputDecoration(
                            hintText: 'Søg i samtalen',
                            hintStyle: DSTextStyle.bodyMd.copyWith(
                              color: _c.text.muted,
                            ),
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (v) => setState(() => _searchTerm = v),
                        ),
                      ),
                    ],
                  ),
                )
                : Text(
                  widget.conversation.partnerName,
                  style: DSTextStyle.headingSm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _c.text.primary,
                  ),
                ),
        actions: [
          IconButton(
            icon: Icon(
              _searchOpen ? Icons.close : Icons.search,
              color: _c.text.secondary,
            ),
            tooltip: _searchOpen ? 'Luk søgning' : 'Søg i samtalen',
            onPressed: () {
              if (_searchOpen) {
                _closeSearch();
              } else {
                setState(() => _searchOpen = true);
              }
            },
          ),
        ],
      ),
      body: Padding(
        // Lift the whole chat (message list + composer) above the keyboard.
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            _JobBanner(conversation: widget.conversation),
            Expanded(
              child: messagesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (e, _) => Center(
                      child: Text(
                        'Kunne ikke hente beskeder',
                        style: DSTextStyle.bodyMd.copyWith(
                          color: _c.text.muted,
                        ),
                      ),
                    ),
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'Send en besked for at starte samtalen',
                        style: DSTextStyle.bodyMd.copyWith(
                          color: _c.text.muted,
                        ),
                      ),
                    );
                  }
                  // While searching, filter the conversation to messages that
                  // contain the term (the term itself is highlighted in-bubble).
                  final term = _searchTerm.trim().toLowerCase();
                  final searching = _searchOpen && term.isNotEmpty;
                  final displayed =
                      searching
                          ? messages
                              .where(
                                (m) =>
                                    !m.isSystemMessage &&
                                    m.message.toLowerCase().contains(term),
                              )
                              .toList()
                          : messages;

                  if (searching && displayed.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(DSSpacing.s4),
                        child: Text(
                          'Ingen beskeder matcher "$_searchTerm"',
                          textAlign: TextAlign.center,
                          style: DSTextStyle.bodyMd.copyWith(
                            color: _c.text.muted,
                          ),
                        ),
                      ),
                    );
                  }

                  // Don't yank to the bottom while searching the history.
                  if (!searching) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom(animate: false);
                    });
                  }

                  // Resolve every job-link token in the conversation, per viewer.
                  final refsCsv = (messages
                          .expand((m) => extractJobRefs(m.message))
                          .toSet()
                          .toList()
                        ..sort())
                      .join(',');
                  final jobLinks =
                      ref
                          .watch(jobLinkResolutionsProvider(refsCsv))
                          .valueOrNull ??
                      const <String, JobLinkResolution>{};

                  return _MessageList(
                    messages: displayed,
                    currentUserId: _currentUserId,
                    partnerName: widget.conversation.partnerName,
                    isSupport: widget.conversation.isSupport,
                    scrollController: _scrollController,
                    reactions: reactions,
                    highlightId: _highlightId,
                    searchTerm: searching ? _searchTerm : null,
                    jobLinks: jobLinks,
                    onJobTap: _openJobTarget,
                    onReply: _startReply,
                    onReact: _react,
                    onLongPressStart: _showReactionBar,
                    onJumpToReplied: _jumpToMessage,
                  );
                },
              ),
            ),

            if (adminTyping)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DSSpacing.s4,
                  vertical: DSSpacing.s1,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'DJTILBUD skriver...',
                    style: DSTextStyle.bodySm.copyWith(
                      color: _c.text.muted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),

            if (_errorMsg != null)
              Container(
                width: double.infinity,
                color: _c.state.danger.withValues(alpha: 0.16),
                padding: const EdgeInsets.symmetric(
                  horizontal: DSSpacing.s4,
                  vertical: DSSpacing.s2,
                ),
                child: Text(
                  _errorMsg!,
                  style: DSTextStyle.labelMd.copyWith(color: _c.state.danger),
                ),
              ),

            if (_replyTo != null)
              Container(
                padding: const EdgeInsets.fromLTRB(
                  DSSpacing.s4,
                  DSSpacing.s2,
                  DSSpacing.s2,
                  0,
                ),
                child: Row(
                  children: [
                    Container(width: 3, height: 32, color: _c.brand.primary),
                    const SizedBox(width: DSSpacing.s2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Svarer ${_replyTo!.senderType == 'admin' ? (_replyTo!.senderName ?? 'DJTILBUD') : (_replyTo!.senderId == _currentUserId ? 'dig selv' : widget.conversation.partnerName)}',
                            style: DSTextStyle.labelSm.copyWith(
                              color: _c.text.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _replyTo!.isSystemMessage
                                ? 'Systembesked'
                                : _replyTo!.message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DSTextStyle.bodySm.copyWith(
                              color: _c.text.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 18, color: _c.text.muted),
                      onPressed: () => setState(() => _replyTo = null),
                    ),
                  ],
                ),
              ),

            if (_mentionQuery != null)
              _MentionPicker(
                results:
                    ref
                        .watch(linkableJobsProvider(_mentionSearchQuery))
                        .valueOrNull ??
                    const [],
                onSelect: _insertJobToken,
              ),

            if (_pendingImage != null)
              Container(
                padding: const EdgeInsets.fromLTRB(
                  DSSpacing.s4,
                  DSSpacing.s2,
                  DSSpacing.s2,
                  0,
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(DSRadius.sm),
                      child: Image.file(
                        File(_pendingImage!.path),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: DSSpacing.s2),
                    Expanded(
                      child: Text(
                        'Billede vedhæftet',
                        style: DSTextStyle.bodySm.copyWith(
                          color: _c.text.muted,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 18, color: _c.text.muted),
                      onPressed:
                          _isSending
                              ? null
                              : () => setState(() => _pendingImage = null),
                    ),
                  ],
                ),
              ),

            _MessageInput(
              controller: _textController,
              focusNode: _focusNode,
              isSending: _isSending,
              onSend: _sendMessage,
              onAttach: _pickImage,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Job navigation banner ────────────────────────────────────────────────────

class _JobBanner extends ConsumerWidget {
  const _JobBanner({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _c = DSTheme.of(context);
    final conv = conversation;
    // The support channel has no job to link to — no banner.
    if (conv.isSupport) return const SizedBox.shrink();
    VoidCallback? onTap;

    if (conv.senderType == 'dj') {
      if (conv.extJobId != null) {
        final extJobs = ref.watch(djExtJobsProvider).valueOrNull ?? [];
        final matches = extJobs.where((e) => e.id == conv.extJobId).toList();
        if (matches.isNotEmpty) {
          final extJob = matches.first;
          onTap =
              () => context.pushNamed(AppRoutes.extJobDetail, extra: extJob);
        }
      } else if (conv.jobId != null) {
        final quotes = ref.watch(djQuotesProvider).valueOrNull ?? [];
        final matches = quotes.where((q) => q.jobId == conv.jobId).toList();
        if (matches.isNotEmpty) {
          final quote = matches.first;
          onTap = () => context.pushNamed(AppRoutes.quoteDetail, extra: quote);
        }
      }
    } else if (conv.senderType == 'musician') {
      final offers = ref.watch(serviceOffersProvider).valueOrNull ?? [];
      final matches =
          offers
              .where(
                (o) =>
                    (conv.jobId != null && o.jobId == conv.jobId) ||
                    (conv.extJobId != null && o.extJobId == conv.extJobId),
              )
              .toList();
      if (matches.isNotEmpty) {
        final offer = matches.first;
        onTap =
            () => context.pushNamed(AppRoutes.serviceOfferDetail, extra: offer);
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _c.bg.canvas,
          border: Border(bottom: BorderSide(color: _c.border.subtle)),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s4,
          vertical: DSSpacing.s3 + 2,
        ),
        child: Row(
          children: [
            Icon(LucideIcons.briefcase, size: 14, color: _c.text.secondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                conv.jobInfo,
                style: DSTextStyle.labelMd.copyWith(
                  color: _c.text.primary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                LucideIcons.chevronRight,
                size: 15,
                color: _c.text.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Message list ─────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.currentUserId,
    required this.partnerName,
    required this.scrollController,
    required this.reactions,
    required this.onReply,
    required this.onReact,
    required this.onLongPressStart,
    required this.onJumpToReplied,
    this.isSupport = false,
    this.highlightId,
    this.searchTerm,
    this.jobLinks = const {},
    this.onJobTap,
  });

  final List<ChatMessage> messages;
  final String currentUserId;
  final String partnerName;
  final bool isSupport;
  final ScrollController scrollController;
  final Map<int, List<MessageReaction>> reactions;
  final int? highlightId;
  final String? searchTerm;
  final Map<String, JobLinkResolution> jobLinks;
  final void Function(JobLinkTarget)? onJobTap;
  final void Function(ChatMessage) onReply;
  final void Function(ChatMessage, String) onReact;
  final void Function(Offset, ChatMessage) onLongPressStart;
  final void Function(int) onJumpToReplied;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    // Group messages by calendar date
    final groups = <({DateTime date, List<ChatMessage> messages})>[];
    DateTime? currentDate;

    for (final msg in messages) {
      final msgDate = DateTime(
        msg.createdAt.year,
        msg.createdAt.month,
        msg.createdAt.day,
      );
      if (currentDate == null || msgDate != currentDate) {
        currentDate = msgDate;
        groups.add((date: msgDate, messages: [msg]));
      } else {
        groups.last.messages.add(msg);
      }
    }

    final byId = {for (final m in messages) m.id: m};

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: groups.length,
      itemBuilder: (context, groupIndex) {
        final group = groups[groupIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DateDivider(date: group.date),
            ...List.generate(group.messages.length, (i) {
              final msg = group.messages[i];
              final prev = i > 0 ? group.messages[i - 1] : null;
              final next =
                  i < group.messages.length - 1 ? group.messages[i + 1] : null;

              // Group consecutive messages from the same side. On support the side is the
              // sender_type (admin vs user); elsewhere it's the sender id.
              String keyOf(ChatMessage m) =>
                  isSupport
                      ? (m.senderType == 'admin' ? 'admin' : 'user')
                      : m.senderId;
              final isGroupStart = prev == null || keyOf(prev) != keyOf(msg);
              final isGroupEnd = next == null || keyOf(next) != keyOf(msg);
              final showTimestamp =
                  next == null ||
                  keyOf(next) != keyOf(msg) ||
                  next.createdAt.difference(msg.createdAt).inMinutes >= 1;

              // On the support channel the other side is always the admin team, so decide own-ness
              // by sender_type (robust even if one account is both admin + musician — otherwise
              // both sides share a uid and every bubble renders as "own").
              final isOwn =
                  isSupport
                      ? msg.senderType != 'admin'
                      : msg.senderId == currentUserId;
              return _MessageBubble(
                message: msg,
                isOwn: isOwn,
                partnerName: partnerName,
                showTimestamp: showTimestamp,
                showAvatar: isGroupEnd,
                isGroupStart: isGroupStart,
                isSupport: isSupport,
                currentUserId: currentUserId,
                repliedTo: msg.replyToId != null ? byId[msg.replyToId] : null,
                reactions: reactions[msg.id] ?? const [],
                isHighlighted: highlightId == msg.id,
                searchTerm: searchTerm,
                jobLinks: jobLinks,
                onJobTap: onJobTap,
                onReply: onReply,
                onReact: onReact,
                onLongPressStart: onLongPressStart,
                onJumpToReplied: onJumpToReplied,
              );
            }),
          ],
        );
      },
    );
  }
}

// ─── Date divider ─────────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String label;
    if (date == today) {
      label = 'I dag';
    } else if (date == yesterday) {
      label = 'I går';
    } else {
      const months = [
        'jan',
        'feb',
        'mar',
        'apr',
        'maj',
        'jun',
        'jul',
        'aug',
        'sep',
        'okt',
        'nov',
        'dec',
      ];
      label = '${date.day}. ${months[date.month - 1]} ${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: DSSpacing.s3,
        horizontal: DSSpacing.s4,
      ),
      child: Row(
        children: [
          Expanded(child: Divider(color: _c.border.subtle)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s3),
            child: Text(
              label,
              style: DSTextStyle.labelSm.copyWith(color: _c.text.muted),
            ),
          ),
          Expanded(child: Divider(color: _c.border.subtle)),
        ],
      ),
    );
  }
}

// ─── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isOwn,
    required this.partnerName,
    required this.showTimestamp,
    required this.currentUserId,
    required this.reactions,
    required this.onReply,
    required this.onReact,
    required this.onLongPressStart,
    required this.onJumpToReplied,
    this.repliedTo,
    this.isSupport = false,
    this.isHighlighted = false,
    this.showAvatar = true,
    this.isGroupStart = true,
    this.searchTerm,
    this.jobLinks = const {},
    this.onJobTap,
  });

  final ChatMessage message;
  final bool isOwn;
  final String partnerName;
  final bool showTimestamp;
  final String currentUserId;
  final bool isSupport;
  final ChatMessage? repliedTo;
  final List<MessageReaction> reactions;
  final bool isHighlighted;
  final String? searchTerm;
  final Map<String, JobLinkResolution> jobLinks;
  final void Function(JobLinkTarget)? onJobTap;
  final void Function(ChatMessage) onReply;
  final void Function(ChatMessage, String) onReact;
  final void Function(Offset, ChatMessage) onLongPressStart;
  final void Function(int) onJumpToReplied;
  // Within a run of same-side messages: avatar only on the last, name only on the first.
  final bool showAvatar;
  final bool isGroupStart;

  static const _avatarSize = 28.0;

  /// Centered themed dialog listing who reacted with which emoji (this is a
  /// 2-party chat, so each reaction is either mine or the other party's).
  void _showReactors(BuildContext context) {
    final _c = DSTheme.of(context);
    showDialog<void>(
      context: context,
      builder:
          (ctx) => Dialog(
            backgroundColor: _c.bg.surface,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DSRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Reaktioner',
                    style: DSTextStyle.headingSm.copyWith(
                      color: _c.text.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final r in reactions)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.userId == currentUserId ? 'Dig' : partnerName,
                              style: DSTextStyle.bodyMd.copyWith(
                                color: _c.text.primary,
                              ),
                            ),
                          ),
                          Text(r.emoji, style: const TextStyle(fontSize: 22)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(
                        'Luk',
                        style: DSTextStyle.labelLg.copyWith(
                          color: _c.brand.primaryActive,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    if (message.isSystemMessage) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: DSSpacing.s1,
          horizontal: DSSpacing.s4,
        ),
        child: Center(
          child: Text(
            message.message,
            style: DSTextStyle.bodySm.copyWith(
              color: _c.text.muted,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final timeString = _formatTime(message.createdAt);
    // Admin replies (support channel) carry their own name/avatar so each shows up as themselves.
    final partnerDisplayName = message.senderName ?? partnerName;
    final partnerAvatarUrl = message.senderAvatarUrl;
    // Name only on the first message of a same-side run.
    final showSenderLabel =
        !isOwn && isGroupStart && message.senderName != null;

    // Group reactions by emoji + find the current user's pick (to highlight + toggle).
    final byEmoji = <String, int>{};
    String? myEmoji;
    for (final r in reactions) {
      byEmoji[r.emoji] = (byEmoji[r.emoji] ?? 0) + 1;
      if (r.userId == currentUserId) myEmoji = r.emoji;
    }

    return Padding(
      padding: EdgeInsets.only(
        left: isOwn ? 56 : 8,
        right: isOwn ? 8 : 56,
        top: isGroupStart ? 8 : 1,
        bottom: showTimestamp ? 2 : 0,
      ),
      child: _SwipeToReply(
        onReply: () => onReply(message),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment:
              isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            // Avatar — only for partner messages, and only on the last of a same-side run.
            if (!isOwn) ...[
              showAvatar
                  ? _ChatAvatar(
                    name: partnerDisplayName,
                    imageUrl: partnerAvatarUrl,
                  )
                  : const SizedBox(width: _avatarSize),
              const SizedBox(width: 6),
            ],

            // Bubble + optional timestamp
            Flexible(
              child: Column(
                crossAxisAlignment:
                    isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showSenderLabel)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 2),
                      child: Text(
                        partnerDisplayName,
                        style: DSTextStyle.labelSm.copyWith(
                          color: _c.text.muted,
                        ),
                      ),
                    ),
                  if (repliedTo != null)
                    GestureDetector(
                      onTap: () => onJumpToReplied(repliedTo!.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
                        decoration: BoxDecoration(
                          color: _c.bg.canvas,
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(color: _c.brand.primary, width: 3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              repliedTo!.senderType == 'admin'
                                  ? (repliedTo!.senderName ?? 'DJTILBUD')
                                  : (repliedTo!.senderId == currentUserId
                                      ? 'Dig'
                                      : partnerName),
                              style: DSTextStyle.labelSm.copyWith(
                                color: _c.text.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              repliedTo!.isSystemMessage
                                  ? 'Systembesked'
                                  : repliedTo!.message,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DSTextStyle.bodySm.copyWith(
                                color: _c.text.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Reserve transparent space below the bubble when reacted so
                      // the straddling badge stays INSIDE the Stack's bounds and is
                      // fully tappable (Flutter won't hit-test outside a parent).
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: byEmoji.isEmpty ? 0 : 11,
                        ),
                        child: GestureDetector(
                          onLongPressStart:
                              (d) =>
                                  onLongPressStart(d.globalPosition, message),
                          child: Container(
                            padding: EdgeInsets.fromLTRB(
                              14,
                              10,
                              14,
                              // Keep the badge clear of the message text.
                              byEmoji.isEmpty ? 10 : 22,
                            ),
                            decoration: BoxDecoration(
                              color: isOwn ? _c.brand.primary : _c.bg.surface,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(DSRadius.lg),
                                topRight: const Radius.circular(DSRadius.lg),
                                bottomLeft:
                                    isOwn
                                        ? const Radius.circular(DSRadius.lg)
                                        : const Radius.circular(DSRadius.sm),
                                bottomRight:
                                    isOwn
                                        ? const Radius.circular(DSRadius.sm)
                                        : const Radius.circular(DSRadius.lg),
                              ),
                              border:
                                  isHighlighted
                                      ? Border.all(
                                        color: _c.brand.primaryActive,
                                        width: 2,
                                      )
                                      : isOwn
                                      ? null
                                      : Border.all(
                                        color: _c.border.subtle,
                                        width: 1,
                                      ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (message.attachmentUrl != null)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      bottom: message.message.isEmpty ? 0 : 6,
                                    ),
                                    child: GestureDetector(
                                      onTap:
                                          () => _showFullImage(
                                            context,
                                            message.attachmentUrl!,
                                          ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          DSRadius.md,
                                        ),
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 220,
                                            maxHeight: 260,
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl: message.attachmentUrl!,
                                            fit: BoxFit.cover,
                                            placeholder:
                                                (_, __) => Container(
                                                  width: 180,
                                                  height: 180,
                                                  color: _c.bg.canvas,
                                                ),
                                            errorWidget:
                                                (_, __, ___) => Container(
                                                  width: 180,
                                                  height: 120,
                                                  color: _c.bg.canvas,
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    color: _c.text.muted,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (message.message.isNotEmpty)
                                  _FormattedText(
                                    text: message.message,
                                    highlight: searchTerm,
                                    jobLinks: jobLinks,
                                    onJobTap: onJobTap,
                                    baseStyle: DSTextStyle.bodyMd.copyWith(
                                      color:
                                          isOwn
                                              ? _c.brand.onPrimary
                                              : _c.text.primary,
                                      height: 1.4,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Reaction badge — a white circular pill straddling the
                      // bubble's bottom corner (Messenger style). Reserved
                      // bottom padding keeps it clear of the text.
                      if (byEmoji.isNotEmpty)
                        Positioned(
                          bottom: 0,
                          left: isOwn ? null : 8,
                          right: isOwn ? 8 : null,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: _c.bg.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _c.bg.canvas, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final entry in byEmoji.entries)
                                  GestureDetector(
                                    // Tapping the badge shows who reacted; it
                                    // does NOT toggle. Adding and removing both
                                    // go through the long-press reaction bar.
                                    onTap: () => _showReactors(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      decoration:
                                          entry.key == myEmoji
                                              ? BoxDecoration(
                                                color: _c.brand.primary
                                                    .withValues(alpha: 0.22),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              )
                                              : null,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            entry.key,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                          if (entry.value > 1) ...[
                                            const SizedBox(width: 2),
                                            Text(
                                              '${entry.value}',
                                              style: DSTextStyle.labelSm
                                                  .copyWith(
                                                    color: _c.text.secondary,
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (showTimestamp)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: DSSpacing.s1,
                        bottom: DSSpacing.s1,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timeString,
                            style: DSTextStyle.bodySm.copyWith(
                              fontSize: 11,
                              color: _c.text.muted,
                            ),
                          ),
                          if (isOwn && message.readAt != null) ...[
                            Text(
                              ' • Set kl ${_formatTime(message.readAt!)}',
                              style: DSTextStyle.bodySm.copyWith(
                                fontSize: 11,
                                color: _c.text.muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Keep spacing symmetrical on own-message side
            if (isOwn) const SizedBox(width: _avatarSize + 6),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// Swipe a message to the right to reply (Messenger style): the bubble slides, a reply icon is
// revealed, and crossing the threshold fires onReply before snapping back.
class _SwipeToReply extends StatefulWidget {
  const _SwipeToReply({required this.child, required this.onReply});

  final Widget child;
  final VoidCallback onReply;

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply> {
  double _dx = 0;
  // Whether this drag has already crossed the reply threshold (so the haptic
  // fires once, the moment it's crossed, like Messenger).
  bool _passedThreshold = false;
  static const _threshold = 56.0;
  static const _max = 84.0;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return GestureDetector(
      onHorizontalDragUpdate: (d) {
        setState(() => _dx = (_dx + d.delta.dx).clamp(0.0, _max));
        if (_dx >= _threshold && !_passedThreshold) {
          _passedThreshold = true;
          HapticFeedback.lightImpact();
        } else if (_dx < _threshold && _passedThreshold) {
          _passedThreshold = false;
        }
      },
      onHorizontalDragEnd: (_) {
        if (_dx >= _threshold) widget.onReply();
        _passedThreshold = false;
        setState(() => _dx = 0);
      },
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          if (_dx > 4)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Opacity(
                opacity: (_dx / _threshold).clamp(0.0, 1.0),
                child: Icon(Icons.reply, size: 20, color: _c.text.muted),
              ),
            ),
          AnimatedContainer(
            duration: Duration(milliseconds: _dx == 0 ? 150 : 0),
            transform: Matrix4.translationValues(_dx, 0, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

// Small avatar using DS tokens — shows a photo when available, else initials.
class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({required this.name, this.imageUrl});

  final String name;
  final String? imageUrl;

  static const _size = 28.0;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _initials(_c),
          placeholder: (_, __) => _initials(_c),
        ),
      );
    }
    return _initials(_c);
  }

  Widget _initials(DSColors _c) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _c.brand.primary.withValues(alpha: 0.12),
      ),
      child: Center(
        child: Text(
          initial,
          style: DSTextStyle.labelSm.copyWith(
            color: _c.brand.primaryActive,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Formatted text (bold + bullets + paragraphs) ────────────────────────────

class _FormattedText extends StatelessWidget {
  const _FormattedText({
    required this.text,
    required this.baseStyle,
    this.highlight,
    this.jobLinks = const {},
    this.onJobTap,
  });

  final String text;
  final TextStyle baseStyle;
  // When set, case-insensitive occurrences of this term get an amber highlight
  // (used by in-conversation search).
  final String? highlight;
  // Resolved job links + tap handler; `@job:id` / `@extjob:id` tokens render as chips.
  final Map<String, JobLinkResolution> jobLinks;
  final void Function(JobLinkTarget)? onJobTap;

  static final _boldRegex = RegExp(r'\*\*(.*?)\*\*');

  // Splits [raw] on job-ref tokens (rendered as chips), then highlights the rest.
  List<InlineSpan> _emit(String raw, {bool bold = false}) {
    if (!jobRefRegExp.hasMatch(raw)) return _emitHighlighted(raw, bold: bold);
    final spans = <InlineSpan>[];
    int i = 0;
    for (final m in jobRefRegExp.allMatches(raw)) {
      if (m.start > i) {
        spans.addAll(_emitHighlighted(raw.substring(i, m.start), bold: bold));
      }
      final ref = '${m.group(1)}:${m.group(2)}';
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _JobChip(
            ref: ref,
            resolution: jobLinks[ref],
            onTap: onJobTap,
            baseColor: baseStyle.color,
          ),
        ),
      );
      i = m.end;
    }
    if (i < raw.length) {
      spans.addAll(_emitHighlighted(raw.substring(i), bold: bold));
    }
    return spans;
  }

  // Emits [raw] as spans, splitting on the highlight term so matches get an
  // amber background. [bold] applies to the whole segment.
  List<InlineSpan> _emitHighlighted(String raw, {bool bold = false}) {
    final boldStyle =
        bold ? const TextStyle(fontWeight: FontWeight.w700) : null;
    final h = highlight?.trim().toLowerCase();
    if (h == null || h.isEmpty) {
      return [TextSpan(text: raw, style: boldStyle)];
    }
    final spans = <InlineSpan>[];
    final lower = raw.toLowerCase();
    int i = 0;
    while (i < raw.length) {
      final idx = lower.indexOf(h, i);
      if (idx == -1) {
        spans.add(TextSpan(text: raw.substring(i), style: boldStyle));
        break;
      }
      if (idx > i) {
        spans.add(TextSpan(text: raw.substring(i, idx), style: boldStyle));
      }
      spans.add(
        TextSpan(
          text: raw.substring(idx, idx + h.length),
          style: (boldStyle ?? const TextStyle()).copyWith(
            backgroundColor: const Color(0xFFFFE082), // amber highlight
            color: Colors.black,
          ),
        ),
      );
      i = idx + h.length;
    }
    return spans;
  }

  List<InlineSpan> _parseInline(String raw) {
    final spans = <InlineSpan>[];
    int cursor = 0;
    for (final match in _boldRegex.allMatches(raw)) {
      if (match.start > cursor) {
        spans.addAll(_emit(raw.substring(cursor, match.start)));
      }
      spans.addAll(_emit(match.group(1) ?? '', bold: true));
      cursor = match.end;
    }
    if (cursor < raw.length) spans.addAll(_emit(raw.substring(cursor)));
    if (spans.isEmpty) spans.add(TextSpan(text: raw));
    return spans;
  }

  Widget _buildLine(String line) {
    final isBullet = line.startsWith('- ');
    final content = isBullet ? line.substring(2) : line;
    final inlineSpans = _parseInline(content);

    if (isBullet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: baseStyle),
          Flexible(
            child: RichText(
              text: TextSpan(style: baseStyle, children: inlineSpans),
            ),
          ),
        ],
      );
    }
    return RichText(text: TextSpan(style: baseStyle, children: inlineSpans));
  }

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final paragraphs = text.split(RegExp(r'\n\n+'));
    final blocks = <Widget>[];

    for (int p = 0; p < paragraphs.length; p++) {
      if (p > 0) blocks.add(const SizedBox(height: 8));
      final lines = paragraphs[p].split('\n');
      for (int l = 0; l < lines.length; l++) {
        if (l > 0) blocks.add(const SizedBox(height: 3));
        blocks.add(_buildLine(lines[l]));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: blocks,
    );
  }
}

// A job reference rendered inline as a bold id (`#2313`, or `#E2313` for ext
// jobs). Tappable when the viewer may open it, greyed + inert otherwise.
class _JobChip extends StatelessWidget {
  const _JobChip({
    required this.ref,
    required this.resolution,
    this.onTap,
    this.baseColor,
  });

  final String ref;
  final JobLinkResolution? resolution;
  final void Function(JobLinkTarget)? onTap;
  // The surrounding text colour, used while the link is still resolving so it
  // reads as plain text rather than flashing as a disabled link.
  final Color? baseColor;

  String _label() {
    final parts = ref.split(':');
    final id = parts.length > 1 ? parts[1] : '';
    return ref.startsWith('extjob:') ? '#E$id' : '#$id';
  }

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final res = resolution;
    final pending = res == null;
    final accessible = res?.accessible == true && res?.target != null;

    final color =
        accessible
            ? _c.brand.primaryActive
            : pending
            ? (baseColor ?? _c.text.primary)
            : _c.text.muted;

    final label = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        _label(),
        style: DSTextStyle.bodyMd.copyWith(
          fontWeight: FontWeight.w700,
          color: color,
          decoration: accessible ? TextDecoration.underline : null,
        ),
      ),
    );

    if (!accessible) {
      // Still resolving — render inert (no explainer yet).
      if (pending) return label;
      // Resolved but not accessible to this viewer → tap explains why it can't be opened.
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Du har ikke adgang til dette job')),
          );
        },
        child: label,
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap?.call(res!.target!),
      child: label,
    );
  }
}

// The composer "@" job picker, shown above the input.
class _MentionPicker extends StatelessWidget {
  const _MentionPicker({required this.results, required this.onSelect});

  final List<LinkableJob> results;
  final void Function(LinkableJob) onSelect;

  static const _months = [
    'jan',
    'feb',
    'mar',
    'apr',
    'maj',
    'jun',
    'jul',
    'aug',
    'sep',
    'okt',
    'nov',
    'dec',
  ];

  String _label(LinkableJob job) {
    final fallback = job.kind == 'extjob' ? 'Opgave' : 'Job';
    final ev =
        (job.eventType != null && job.eventType!.isNotEmpty)
            ? job.eventType!
            : fallback;
    if (job.date != null) {
      final d = DateTime.tryParse(job.date!);
      if (d != null) return '$ev · ${d.day}. ${_months[d.month - 1]}';
    }
    return ev;
  }

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    if (results.isEmpty) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: _c.bg.surface,
        border: Border(top: BorderSide(color: _c.border.subtle)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: results.length,
        separatorBuilder:
            (_, __) => Divider(height: 1, color: _c.border.subtle),
        itemBuilder: (context, i) {
          final job = results[i];
          return InkWell(
            onTap: () => onSelect(job),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🎵 ${_label(job)}',
                    style: DSTextStyle.bodyMd.copyWith(
                      color: _c.text.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${job.kind == 'extjob' ? 'Ekstern opgave' : 'Job'} #${job.id}',
                    style: DSTextStyle.labelSm.copyWith(color: _c.text.muted),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Message input ────────────────────────────────────────────────────────────

class _MessageInput extends StatelessWidget {
  const _MessageInput({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.onSend,
    required this.onAttach,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: _c.bg.surface,
        border: Border(top: BorderSide(color: _c.border.subtle)),
      ),
      padding: const EdgeInsets.fromLTRB(
        DSSpacing.s3,
        DSSpacing.s2,
        DSSpacing.s2,
        DSSpacing.s2,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attach an image
            IconButton(
              icon: Icon(LucideIcons.image, color: _c.text.secondary),
              tooltip: 'Vedhæft billede',
              onPressed: isSending ? null : onAttach,
            ),
            // Input — DSInput with no label, multi-line
            Expanded(
              child: DSInput(
                controller: controller,
                focusNode: focusNode,
                hint: 'Skriv en besked...',
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                keyboardType: TextInputType.multiline,
              ),
            ),
            const SizedBox(width: DSSpacing.s2),

            // Send button
            DSIconButton(
              icon: LucideIcons.send,
              variant: DSIconButtonVariant.primary,
              isLoading: isSending,
              onTap: isSending ? null : onSend,
            ),
          ],
        ),
      ),
    );
  }
}
