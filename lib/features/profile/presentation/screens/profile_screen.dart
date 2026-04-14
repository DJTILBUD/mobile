import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/router/app_routes.dart';
import 'package:dj_tilbud_app/features/agent/presentation/providers/agent_provider.dart';
import 'package:dj_tilbud_app/features/agent/presentation/widgets/profile_coach_bottom_sheet.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/dj_profile.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/musician_profile.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/user_file.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _c = lightColors;

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.role});

  final MusicianRole role;

  void _openCoach(BuildContext context, WidgetRef ref, Map<String, dynamic> userContext) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProviderScope(
        overrides: [
          agentSessionProvider.overrideWith(
            (ref) => AgentSessionNotifier(ref.watch(agentRepositoryProvider)),
          ),
        ],
        child: ProfileCoachBottomSheet(
          userContext: userContext,
          userRole: role == MusicianRole.dj ? 'dj' : 'musician',
          isDj: role == MusicianRole.dj,
          onEditProfile: () {
            Navigator.of(context).pop();
            context.pushNamed(AppRoutes.editProfile, extra: role);
          },
          onBioAccepted: (_) {
            // Bio was accepted inside the nested sheet — user still needs to save
            // from EditProfileScreen, so just navigate there.
            Navigator.of(context).pop();
            context.pushNamed(AppRoutes.editProfile, extra: role);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameAsync = role == MusicianRole.dj
        ? ref.watch(djProfileProvider.select((p) => p.whenData((d) => d.fullName)))
        : ref.watch(musicianProfileProvider.select((p) => p.whenData((d) => d.fullName)));

    final displayName = nameAsync.valueOrNull ?? '';

    // Full profile for coach context — loaded silently, doesn't block UI
    final profileAsync = role == MusicianRole.dj
        ? ref.watch(djProfileProvider)
        : ref.watch(musicianProfileProvider);

    final userContext = profileAsync.whenData((p) => role == MusicianRole.dj
        ? djToUserContext(p as DjProfile)
        : musicianToUserContext(p as MusicianProfile));

    return Scaffold(
      backgroundColor: _c.bg.canvas,
      appBar: AppBar(
        title: Text('Profil', style: DSTextStyle.headingSm.copyWith(color: _c.text.primary)),
        backgroundColor: _c.bg.surface,
        surfaceTintColor: _c.bg.surface,
      ),
      floatingActionButton: userContext.valueOrNull != null
          ? FloatingActionButton.extended(
              onPressed: () =>
                  _openCoach(context, ref, userContext.valueOrNull!),
              backgroundColor: _c.brand.primary,
              foregroundColor: _c.brand.onPrimary,
              elevation: 2,
              icon: const Icon(LucideIcons.sparkle, size: 18),
              label: Text(
                'Profilcoach',
                style: DSTextStyle.labelMd.copyWith(fontWeight: FontWeight.w600),
              ),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: DSSpacing.s4),
        children: [
          // User header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s6),
            child: Row(
              children: [
                DSAvatar(
                  size: 56,
                  imageUrl: ref
                      .watch(userFilesProvider)
                      .valueOrNull
                      ?.where((f) => f.type == UserFileType.profile)
                      .firstOrNull
                      ?.url,
                ),
                const SizedBox(width: DSSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName.isNotEmpty ? displayName : 'Indlæser...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _c.text.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        role == MusicianRole.dj ? 'DJ' : 'Musiker',
                        style: TextStyle(
                          fontSize: 13,
                          color: _c.text.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: DSSpacing.s6),
          Divider(height: 1, color: _c.border.subtle),

          // Menu items
          _MenuItem(
            icon: LucideIcons.user,
            label: 'Profil oplysninger',
            onTap: () => context.pushNamed(AppRoutes.editProfile, extra: role),
          ),
          _MenuItem(
            icon: LucideIcons.star,
            label: 'Anmeldelser',
            onTap: () => context.pushNamed(AppRoutes.reviews, extra: role),
          ),
          _MenuItem(
            icon: LucideIcons.film,
            label: 'Billeder & videoer',
            onTap: () => context.pushNamed(AppRoutes.media),
          ),
          _MenuItem(
            icon: LucideIcons.fileStack,
            label: 'Standardbeskeder',
            onTap: () => context.pushNamed(AppRoutes.standardMessages),
          ),
          _MenuItem(
            icon: LucideIcons.wallet,
            label: 'Betalingsoplysninger',
            onTap: () => context.pushNamed(AppRoutes.payment, extra: role),
          ),
          _MenuItem(
            icon: LucideIcons.calendarDays,
            label: 'Kalender',
            onTap: () => context.pushNamed(
              role == MusicianRole.dj
                  ? AppRoutes.djCalendar
                  : AppRoutes.instrumentalistCalendar,
            ),
          ),
          _MenuItem(
            icon: LucideIcons.eye,
            label: 'Forhåndsvisning',
            onTap: () => context.pushNamed(AppRoutes.profilePreview, extra: role),
          ),
          if (role == MusicianRole.dj)
            _MenuItem(
              icon: LucideIcons.sliders,
              label: 'Job-filtre',
              onTap: () {
                final id = ref.read(djProfileProvider).valueOrNull?.id;
                if (id != null) {
                  context.pushNamed(AppRoutes.djJobFilters, extra: id);
                }
              },
            ),

          _MenuItem(
            icon: LucideIcons.mailOpen,
            label: 'Beskeder fra admin',
            onTap: () => context.pushNamed(AppRoutes.adminMessages, extra: role),
          ),
          _MenuItem(
            icon: LucideIcons.messageSquare,
            label: 'Feedback',
            onTap: () => context.pushNamed(AppRoutes.feedback),
          ),
          _MenuItem(
            icon: LucideIcons.bookOpen,
            label: 'FAQ',
            onTap: () => context.pushNamed(AppRoutes.faq),
          ),

          const SizedBox(height: DSSpacing.s4),
          Divider(height: 1, color: _c.border.subtle),
          const SizedBox(height: DSSpacing.s2),

          // Logout
          _MenuItem(
            icon: LucideIcons.logOut,
            label: 'Log ud',
            color: _c.state.danger,
            onTap: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? _c.text.primary;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: c,
        ),
      ),
      trailing: color == null
          ? Icon(LucideIcons.chevronRight, color: _c.text.muted, size: 20)
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: DSSpacing.s6, vertical: 2),
    );
  }
}
