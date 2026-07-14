import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/error/app_exception.dart';
import 'package:dj_tilbud_app/features/chat/data/datasources/admin_support_datasource.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/job_link.dart';
import 'package:dj_tilbud_app/features/chat/presentation/providers/admin_support_provider.dart';

/// Bottom sheet to start a NEW support conversation as an admin: pick a DJ/musician, write the
/// first message, send. Pops with the created [AdminSupportThread] on success so the caller can open
/// it. Mirrors the admin tool's "Ny besked" composer.
class NewSupportMessageSheet extends ConsumerStatefulWidget {
  const NewSupportMessageSheet({super.key});

  @override
  ConsumerState<NewSupportMessageSheet> createState() =>
      _NewSupportMessageSheetState();
}

class _NewSupportMessageSheetState
    extends ConsumerState<NewSupportMessageSheet> {
  final _searchController = TextEditingController();
  final _messageController = TextEditingController();
  String _query = '';
  Timer? _debounce;
  AdminRecipient? _selected;
  bool _sending = false;
  String? _error;

  // "@" job picker for the first message (mirrors the in-thread composer) so an admin can link a
  // job directly when starting a conversation, instead of having to send something first.
  String? _mentionQuery;
  int _mentionStart = -1;
  String _mentionSearchQuery = '';
  Timer? _mentionDebounce;

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

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onComposerChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mentionDebounce?.cancel();
    _messageController.removeListener(_onComposerChanged);
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // Detect an active "@..." token at the caret; a whitespace or a completed "@job:id" ends it.
  void _onComposerChanged() {
    final sel = _messageController.selection;
    final text = _messageController.text;
    final caret =
        (sel.isValid && sel.baseOffset >= 0)
            ? sel.baseOffset.clamp(0, text.length)
            : text.length;
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
    final text = _messageController.text;
    final caret = _messageController.selection.baseOffset.clamp(0, text.length);
    if (_mentionStart < 0 || _mentionStart > text.length) return;
    final start = _mentionStart < caret ? _mentionStart : caret;
    final newText =
        '${text.substring(0, start)}@${job.ref} ${text.substring(caret)}';
    final newCaret = start + job.ref.length + 2; // "@" + ref + trailing space
    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCaret),
    );
    setState(() {
      _mentionQuery = null;
      _mentionStart = -1;
    });
  }

  String _jobLabel(LinkableJob job) {
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

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _query = v.trim());
    });
  }

  Future<void> _send() async {
    final recipient = _selected;
    final text = _messageController.text.trim();
    if (recipient == null || text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final conversationId = await ref
          .read(adminSupportDatasourceProvider)
          .startConversation(userId: recipient.userId, message: text);
      if (!mounted) return;
      Navigator.of(context).pop(
        AdminSupportThread(
          id: conversationId,
          userName: recipient.name,
          userId: recipient.userId,
          userRole: recipient.role,
          userAvatarUrl: recipient.avatarUrl,
          lastMessage: text,
          // UTC to match server timestamps (the inbox formats these assuming UTC).
          lastMessageAt: DateTime.now().toUtc().toIso8601String(),
        ),
      );
    } on DatabaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'Noget gik galt. Prøv igen.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _c.border.strong,
                  borderRadius: BorderRadius.circular(DSRadius.pill),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DSSpacing.s4,
                  DSSpacing.s3,
                  DSSpacing.s4,
                  DSSpacing.s2,
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.messageSquarePlus,
                      size: 18,
                      color: _c.text.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ny besked',
                      style: DSTextStyle.headingSm.copyWith(
                        color: _c.text.primary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(LucideIcons.x, color: _c.text.muted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Flexible(child: _selected == null ? _picker(_c) : _composer(_c)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 1: pick a recipient ──────────────────────────────────────────────
  Widget _picker(DSColors _c) {
    final recipientsAsync = ref.watch(adminSupportRecipientsProvider(_query));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DSSpacing.s4,
            0,
            DSSpacing.s4,
            DSSpacing.s2,
          ),
          child: DSInput(
            controller: _searchController,
            hint: 'Søg efter DJ eller musiker',
            iconLeft: LucideIcons.search,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
          ),
        ),
        Flexible(
          child: recipientsAsync.when(
            loading:
                () => const Padding(
                  padding: EdgeInsets.all(DSSpacing.s6),
                  child: Center(child: CircularProgressIndicator()),
                ),
            error:
                (_, __) => Padding(
                  padding: const EdgeInsets.all(DSSpacing.s6),
                  child: Text(
                    'Kunne ikke hente brugere',
                    style: DSTextStyle.bodyMd.copyWith(color: _c.text.muted),
                  ),
                ),
            data: (recipients) {
              if (recipients.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(DSSpacing.s6),
                  child: Text(
                    'Ingen brugere fundet',
                    style: DSTextStyle.bodyMd.copyWith(color: _c.text.muted),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: DSSpacing.s4),
                itemCount: recipients.length,
                itemBuilder: (context, i) {
                  final r = recipients[i];
                  return InkWell(
                    onTap:
                        () => setState(() {
                          _selected = r;
                          _error = null;
                        }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DSSpacing.s4,
                        vertical: DSSpacing.s2,
                      ),
                      child: Row(
                        children: [
                          _Avatar(name: r.name, imageUrl: r.avatarUrl),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: DSTextStyle.bodyMd.copyWith(
                                    color: _c.text.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  r.role == 'dj' ? 'DJ' : 'Musiker',
                                  style: DSTextStyle.labelSm.copyWith(
                                    color: _c.text.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Step 2: write the message ─────────────────────────────────────────────
  Widget _composer(DSColors _c) {
    final r = _selected!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        DSSpacing.s4,
        0,
        DSSpacing.s4,
        DSSpacing.s4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(DSSpacing.s2),
            decoration: BoxDecoration(
              color: _c.bg.canvas,
              borderRadius: BorderRadius.circular(DSRadius.md),
            ),
            child: Row(
              children: [
                _Avatar(name: r.name, imageUrl: r.avatarUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DSTextStyle.bodyMd.copyWith(
                          color: _c.text.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        r.role == 'dj' ? 'DJ' : 'Musiker',
                        style: DSTextStyle.labelSm.copyWith(
                          color: _c.text.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed:
                      _sending
                          ? null
                          : () => setState(() {
                            _selected = null;
                            _error = null;
                          }),
                  child: const Text('Skift'),
                ),
              ],
            ),
          ),
          const SizedBox(height: DSSpacing.s3),
          DSInput(
            controller: _messageController,
            hint: 'Skriv din besked... (@ for at linke et job)',
            maxLines: 5,
            minLines: 3,
            enabled: !_sending,
          ),
          if (_mentionQuery != null) ...[
            const SizedBox(height: DSSpacing.s2),
            _mentionList(_c),
          ],
          if (_error != null) ...[
            const SizedBox(height: DSSpacing.s2),
            Text(
              _error!,
              style: DSTextStyle.labelSm.copyWith(color: _c.state.danger),
            ),
          ],
          const SizedBox(height: DSSpacing.s3),
          DSButton(
            label: _sending ? 'Sender...' : 'Send besked',
            iconLeft: LucideIcons.send,
            isLoading: _sending,
            expand: true,
            onTap: _send,
          ),
        ],
      ),
    );
  }

  // The "@" job picker list, resolved against the chosen recipient so it can warn about jobs the
  // DJ/musician can't see. Tapping a row inserts an `@job:<id>` token into the message.
  Widget _mentionList(DSColors _c) {
    final r = _selected!;
    final results =
        ref
            .watch(
              adminLinkableJobsProvider('${r.userId}|$_mentionSearchQuery'),
            )
            .valueOrNull ??
        const <LinkableJob>[];
    final decoration = BoxDecoration(
      color: _c.bg.surface,
      borderRadius: BorderRadius.circular(DSRadius.md),
      border: Border.all(color: _c.border.subtle),
    );
    if (results.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: decoration,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          'Ingen jobs matcher — skriv fx 491 (internt job) eller E491 (eksternt) efter @',
          style: DSTextStyle.labelMd.copyWith(color: _c.text.muted),
        ),
      );
    }
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: decoration,
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: results.length,
        separatorBuilder:
            (_, __) => Divider(height: 1, color: _c.border.subtle),
        itemBuilder: (context, i) {
          final job = results[i];
          final notVisible = job.visibleToRecipient == false;
          return InkWell(
            onTap: () => _insertJobToken(job),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _jobLabel(job),
                    style: DSTextStyle.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _c.text.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${job.ref}',
                    style: DSTextStyle.labelSm.copyWith(color: _c.text.muted),
                  ),
                  if (notVisible) ...[
                    const SizedBox(height: 2),
                    Text(
                      '⚠ Ikke synlig for ${r.name}',
                      style: DSTextStyle.labelSm.copyWith(
                        color: _c.state.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Small circular avatar: profile image if present, else initials.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.imageUrl});

  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final initials =
        name.trim().isEmpty
            ? '?'
            : name
                .trim()
                .split(RegExp(r'\s+'))
                .take(2)
                .map((w) => w[0])
                .join()
                .toUpperCase();
    return ClipOval(
      child: SizedBox(
        width: 36,
        height: 36,
        child:
            imageUrl != null && imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _initials(_c, initials),
                  placeholder: (_, __) => _initials(_c, initials),
                )
                : _initials(_c, initials),
      ),
    );
  }

  Widget _initials(DSColors _c, String initials) => Container(
    color: _c.brand.primary.withValues(alpha: 0.15),
    alignment: Alignment.center,
    child: Text(
      initials,
      style: DSTextStyle.labelSm.copyWith(
        color: _c.brand.primaryActive,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
