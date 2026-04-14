import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/utils/event_type_labels.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/standard_message.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _c = lightColors;

const _eventTypes = [
  'bryllup', 'fødselsdag', 'firmafest', 'konfirmation',
  'studenterfest', 'julefrokost', 'sommerfest', 'andet',
];

class StandardMessagesScreen extends ConsumerWidget {
  const StandardMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(standardMessagesProvider);

    return Scaffold(
      backgroundColor: _c.bg.canvas,
      appBar: AppBar(
        title: Text('Standardbeskeder', style: DSTextStyle.headingSm.copyWith(color: _c.text.primary)),
        backgroundColor: _c.bg.surface,
        surfaceTintColor: _c.bg.surface,
      ),
      floatingActionButton: DSIconButton(
        icon: LucideIcons.plus,
        variant: DSIconButtonVariant.primary,
        size: DSButtonSize.lg,
        onTap: () => _showUpsertDialog(context, ref),
      ),
      body: messagesAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: _c.brand.primary)),
        error: (e, _) => Center(child: Text('Fejl: $e')),
        data: (messages) {
          if (messages.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.messageSquare, size: 48, color: _c.border.subtle),
                  const SizedBox(height: DSSpacing.s3),
                  Text('Ingen standardbeskeder endnu', style: DSTextStyle.bodyMd.copyWith(color: _c.text.secondary)),
                  const SizedBox(height: DSSpacing.s1),
                  Text('Tryk + for at tilføje en', style: DSTextStyle.labelMd.copyWith(fontWeight: FontWeight.w400, color: _c.text.muted)),
                ],
              ),
            );
          }

          // Group by event type
          final grouped = <String, List<StandardMessage>>{};
          for (final m in messages) {
            grouped.putIfAbsent(m.eventType, () => []).add(m);
          }

          return ListView(
            padding: const EdgeInsets.all(DSSpacing.s4),
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: DSSpacing.s3, bottom: DSSpacing.s2),
                    child: Text(
                      eventTypeLabel(entry.key),
                      style: DSTextStyle.labelLg.copyWith(fontWeight: FontWeight.w700, color: _c.text.primary),
                    ),
                  ),
                  ...entry.value.map((msg) => _MessageCard(
                    message: msg,
                    onEdit: () => _showUpsertDialog(context, ref, existing: msg),
                    onDelete: () => _confirmDelete(context, ref, msg),
                  )),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _showUpsertDialog(BuildContext context, WidgetRef ref, {StandardMessage? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _c.bg.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(DSRadius.lg))),
      builder: (ctx) => _MessageForm(
        existing: existing,
        onSave: (messageText, eventType) async {
          try {
            final repo = ref.read(profileRepositoryProvider);
            final userId = supabase.auth.currentUser!.id;
            if (existing != null) {
              await repo.updateStandardMessage(
                messageId: existing.id,
                messageText: messageText,
                eventType: eventType,
              );
            } else {
              await repo.createStandardMessage(
                userId: userId,
                messageText: messageText,
                eventType: eventType,
              );
            }
            ref.invalidate(standardMessagesProvider);
            if (ctx.mounted) Navigator.of(ctx).pop();
            if (context.mounted) {
              DSToast.show(context, variant: DSToastVariant.success, title: existing != null ? 'Besked opdateret' : 'Besked tilføjet');
            }
          } catch (e) {
            if (context.mounted) DSToast.show(context, variant: DSToastVariant.error, title: 'Fejl: $e');
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, StandardMessage msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Slet besked?'),
        actions: [
          DSButton(label: 'Annuller', variant: DSButtonVariant.ghost, size: DSButtonSize.sm, onTap: () => Navigator.of(ctx).pop()),
          DSButton(
            label: 'Slet',
            variant: DSButtonVariant.tertiary,
            size: DSButtonSize.sm,
            onTap: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(profileRepositoryProvider).deleteStandardMessage(msg.id);
                ref.invalidate(standardMessagesProvider);
                if (context.mounted) DSToast.show(context, variant: DSToastVariant.success, title: 'Besked slettet');
              } catch (e) {
                if (context.mounted) DSToast.show(context, variant: DSToastVariant.error, title: 'Fejl: $e');
              }
            },
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, required this.onEdit, required this.onDelete});

  final StandardMessage message;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DSSpacing.s2),
      child: DSSurface(
        padding: const EdgeInsets.all(DSSpacing.s3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                message.messageText,
                style: DSTextStyle.labelMd.copyWith(fontWeight: FontWeight.w400, color: _c.text.secondary),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Rediger')),
                PopupMenuItem(value: 'delete', child: Text('Slet', style: DSTextStyle.bodyMd.copyWith(color: _c.state.danger))),
              ],
              icon: Icon(LucideIcons.moreVertical, size: 18, color: _c.text.secondary),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageForm extends StatefulWidget {
  const _MessageForm({this.existing, required this.onSave});

  final StandardMessage? existing;
  final Future<void> Function(String messageText, String eventType) onSave;

  @override
  State<_MessageForm> createState() => _MessageFormState();
}

class _MessageFormState extends State<_MessageForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _textCtrl;
  late String _eventType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: widget.existing?.messageText ?? '');
    _eventType = widget.existing?.eventType ?? 'wedding';
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: DSSpacing.s6, right: DSSpacing.s6, top: DSSpacing.s6,
        bottom: MediaQuery.of(context).viewInsets.bottom + DSSpacing.s6,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing != null ? 'Rediger besked' : 'Ny standardbesked',
                style: DSTextStyle.headingMd.copyWith(fontWeight: FontWeight.w700, color: _c.text.primary),
              ),
              const SizedBox(height: DSSpacing.s4),
              DSDropdown<String>(
                label: 'Event type',
                value: _eventType,
                items: _eventTypes
                    .map((t) => DSDropdownItem(value: t, label: eventTypeLabel(t)))
                    .toList(),
                onChanged: (v) => setState(() => _eventType = v!),
              ),
              const SizedBox(height: DSSpacing.s3),
              DSInput(
                controller: _textCtrl,
                label: 'Besked',
                maxLines: 6,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Påkrævet' : null,
              ),
              const SizedBox(height: DSSpacing.s4),
              DSButton(
                label: widget.existing != null ? 'Opdater' : 'Tilføj',
                size: DSButtonSize.lg,
                expand: true,
                isLoading: _saving,
                onTap: _saving ? null : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _saving = true);
                  await widget.onSave(_textCtrl.text.trim(), _eventType);
                  if (mounted) setState(() => _saving = false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
