import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/admin_message.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _c = lightColors;

class AdminMessagesScreen extends ConsumerWidget {
  const AdminMessagesScreen({super.key, required this.role});

  final MusicianRole role;

  bool get _isDj => role == MusicianRole.dj;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(adminMessagesProvider(_isDj));

    return Scaffold(
      backgroundColor: _c.bg.canvas,
      appBar: AppBar(
        title: const Text('Beskeder fra admin'),
        backgroundColor: _c.bg.surface,
        surfaceTintColor: _c.bg.surface,
      ),
      body: messagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Fejl: $e', style: DSTextStyle.bodyMd.copyWith(color: _c.state.danger)),
        ),
        data: (messages) {
          if (messages.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.inbox, size: 48, color: _c.text.muted),
                  const SizedBox(height: DSSpacing.s3),
                  Text(
                    'Ingen beskeder endnu',
                    style: DSTextStyle.headingSm.copyWith(color: _c.text.primary),
                  ),
                  const SizedBox(height: DSSpacing.s1),
                  Text(
                    'Når admin sender dig en besked, vil den dukke op her.',
                    style: DSTextStyle.labelMd.copyWith(color: _c.text.muted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: DSSpacing.s3),
            itemCount: messages.length,
            itemBuilder: (context, index) => _MessageCard(
              message: messages[index],
              isDj: _isDj,
              onRead: () => ref.invalidate(adminMessagesProvider(_isDj)),
            ),
          );
        },
      ),
    );
  }
}

class _MessageCard extends ConsumerStatefulWidget {
  const _MessageCard({
    required this.message,
    required this.isDj,
    required this.onRead,
  });

  final AdminMessage message;
  final bool isDj;
  final VoidCallback onRead;

  @override
  ConsumerState<_MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends ConsumerState<_MessageCard> {
  bool _expanded = false;

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (!widget.message.isRead) {
      final userId = supabase.auth.currentUser?.id ?? '';
      ref.read(markAdminMessageReadProvider.notifier).mark(
            messageId: widget.message.id,
            userId: userId,
            isDj: widget.isDj,
          );
      widget.onRead();
    }
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final dateStr = DateFormat('d. MMM yyyy', 'da_DK').format(msg.createdAt);

    return GestureDetector(
      onTap: _toggle,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s4,
          vertical: DSSpacing.s1,
        ),
        decoration: BoxDecoration(
          color: _c.bg.surface,
          borderRadius: BorderRadius.circular(DSRadius.md),
          border: Border.all(
            color: msg.isRead ? _c.border.subtle : _c.brand.primaryActive,
            width: msg.isRead ? 1 : 1.5,
          ),
          boxShadow: DSShadow.sm,
        ),
        child: Padding(
          padding: const EdgeInsets.all(DSSpacing.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!msg.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 5, right: DSSpacing.s2),
                      decoration: BoxDecoration(
                        color: _c.brand.primaryActive,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      msg.header,
                      style: DSTextStyle.headingSm.copyWith(
                        fontSize: 15,
                        fontWeight: msg.isRead
                            ? FontWeight.w500
                            : FontWeight.w700,
                        color: _c.text.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: DSSpacing.s2),
                  Icon(
                    _expanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 18,
                    color: _c.text.muted,
                  ),
                ],
              ),
              const SizedBox(height: DSSpacing.s1),
              Text(
                dateStr,
                style: DSTextStyle.bodySm.copyWith(color: _c.text.muted),
              ),
              if (_expanded) ...[
                const SizedBox(height: DSSpacing.s3),
                Divider(height: 1, color: _c.border.subtle),
                const SizedBox(height: DSSpacing.s3),
                Text(
                  msg.content,
                  style: DSTextStyle.bodyMd.copyWith(
                    color: _c.text.primary,
                    height: 1.6,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
