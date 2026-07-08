import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';

/// The shared chat composer bar: image-attach button + input + send button.
///
/// Used by BOTH the musician conversation screen and the admin support thread so
/// they look and behave identically. The image preview and the "@" job picker are
/// rendered by the parent ABOVE this bar (they differ per screen). `onChanged` is
/// optional so a screen that drives the "@" picker can hook composer edits.
class ChatMessageInput extends StatelessWidget {
  const ChatMessageInput({
    super.key,
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.onAttach,
    this.focusNode,
    this.onChanged,
    this.hint = 'Skriv en besked...',
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final ValueChanged<String>? onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.bg.surface,
        border: Border(top: BorderSide(color: c.border.subtle)),
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
              icon: Icon(LucideIcons.image, color: c.text.secondary),
              tooltip: 'Vedhæft billede',
              onPressed: isSending ? null : onAttach,
            ),
            // Input — DSInput with no label, multi-line
            Expanded(
              child: DSInput(
                controller: controller,
                focusNode: focusNode,
                hint: hint,
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                onChanged: onChanged,
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
