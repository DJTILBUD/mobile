import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/standard_message.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Compact "Standardbeskeder" button that lets the musician load a saved
/// [StandardMessage] into the pitch field. Self-hides when the user has no
/// saved messages. Shared by the DJ quote form and the instrumentalist offer
/// form so both load standard messages identically.
class StandardMessagePickerButton extends ConsumerWidget {
  const StandardMessagePickerButton({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _c = DSTheme.of(context);
    final messagesAsync = ref.watch(standardMessagesProvider);
    final messages = messagesAsync.valueOrNull ?? [];
    if (messages.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _showPicker(context, messages),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.listChecks, size: 14, color: _c.brand.primaryActive),
          const SizedBox(width: 4),
          Text(
            'Standardbeskeder',
            style: DSTextStyle.labelSm.copyWith(
              fontWeight: FontWeight.w600,
              color: _c.brand.primaryActive,
            ),
          ),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context, List<StandardMessage> messages) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _StandardMessagePickerSheet(
            messages: messages,
            onSelected: onSelected,
          ),
    );
  }
}

/// Compact "Gem som standardbesked" button that saves the current pitch as a new
/// [StandardMessage]. Mirrors the styling of [StandardMessagePickerButton] and
/// leaves the actual save logic to the caller via [onTap].
class SaveTemplateButton extends StatelessWidget {
  const SaveTemplateButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.bookmarkPlus,
            size: 14,
            color: _c.brand.primaryActive,
          ),
          const SizedBox(width: 4),
          Text(
            'Gem som standardbesked',
            style: DSTextStyle.labelSm.copyWith(
              fontWeight: FontWeight.w600,
              color: _c.brand.primaryActive,
            ),
          ),
        ],
      ),
    );
  }
}

class _StandardMessagePickerSheet extends StatelessWidget {
  const _StandardMessagePickerSheet({
    required this.messages,
    required this.onSelected,
  });

  final List<StandardMessage> messages;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: _c.bg.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DSRadius.lg),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + DSSpacing.s4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
                Expanded(
                  child: Text(
                    'Vælg standardbesked',
                    style: DSTextStyle.headingSm.copyWith(
                      color: _c.text.primary,
                    ),
                  ),
                ),
                DSIconButton(
                  icon: LucideIcons.x,
                  variant: DSIconButtonVariant.ghost,
                  size: DSButtonSize.sm,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: _c.border.subtle),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: DSSpacing.s2),
              itemCount: messages.length,
              separatorBuilder:
                  (_, __) => Divider(height: 1, color: _c.border.subtle),
              itemBuilder: (context, i) {
                final msg = messages[i];
                return InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    onSelected(msg.messageText);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DSSpacing.s4,
                      vertical: DSSpacing.s3,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _c.brand.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(DSRadius.pill),
                          ),
                          child: Text(
                            msg.eventType,
                            style: DSTextStyle.labelSm.copyWith(
                              color: _c.brand.primaryActive,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          msg.messageText,
                          style: DSTextStyle.bodyMd.copyWith(
                            color: _c.text.secondary,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
