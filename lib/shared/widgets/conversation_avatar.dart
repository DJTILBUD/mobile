import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';

/// The circular avatar for a chat participant.
///
/// Shared so the same person looks the same in the conversation list, the long-press sheet and the
/// thread header. Was private to chat_screen and hardcoded to 48px; extracted (rather than copied)
/// when the admin thread header needed a smaller one, since a hand-mirrored copy is exactly how the
/// chat widgets drift apart.
///
/// Falls back image -> initials -> "?", so a broken or slow image never leaves an empty circle.
/// [isSupport] renders the DJTILBUD agent mark instead of a person.
class ConversationAvatar extends StatelessWidget {
  const ConversationAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.isSupport = false,
    this.size = 48,
  });

  final String name;
  final String? imageUrl;
  final bool isSupport;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);

    if (isSupport) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: c.brand.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.support_agent,
          color: c.brand.onPrimary,
          // Scaled from the original 26-at-48 so smaller avatars stay balanced.
          size: size * 0.54,
        ),
      );
    }

    final initials = _InitialsAvatar(name: name, c: c, size: size);

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => initials,
          placeholder: (_, __) => initials,
        ),
      );
    }
    return initials;
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({
    required this.name,
    required this.c,
    required this.size,
  });

  final String name;
  final DSColors c;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.bg.inputBg, shape: BoxShape.circle),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            // Scaled from the original 18-at-48.
            fontSize: size * 0.375,
            fontWeight: FontWeight.w700,
            color: c.text.secondary,
          ),
        ),
      ),
    );
  }
}
