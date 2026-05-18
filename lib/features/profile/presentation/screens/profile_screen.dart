import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dj_tilbud_app/core/widgets/restart_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/router/app_routes.dart';
import 'package:dj_tilbud_app/core/theme/theme_provider.dart';
import 'package:dj_tilbud_app/features/agent/presentation/providers/agent_provider.dart';
import 'package:dj_tilbud_app/features/agent/presentation/widgets/profile_coach_bottom_sheet.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/dj_profile.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/musician_profile.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/user_file.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
          onGoToReviews: () {
            Navigator.of(context).pop();
            context.pushNamed(AppRoutes.reviews, extra: role);
          },
          onGoToMedia: () {
            Navigator.of(context).pop();
            context.pushNamed(AppRoutes.media);
          },
          onBioAccepted: (_) {
            Navigator.of(context).pop();
            context.pushNamed(AppRoutes.editProfile, extra: role);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
      final _c = DSTheme.of(context);
    final nameAsync = role == MusicianRole.dj
        ? ref.watch(djProfileProvider.select((p) => p.whenData((d) => d.fullName)))
        : ref.watch(musicianProfileProvider.select((p) => p.whenData((d) => d.fullName)));

    final displayName = nameAsync.valueOrNull ?? '';

    // Full profile + reviews + files for coach context — loaded silently, don't block UI
    final profileAsync = role == MusicianRole.dj
        ? ref.watch(djProfileProvider)
        : ref.watch(musicianProfileProvider);

    final reviewsAsync = role == MusicianRole.dj
        ? ref.watch(djReviewsProvider)
        : ref.watch(musicianReviewsProvider);

    final filesAsync = ref.watch(userFilesProvider);

    final coachContext = profileAsync.whenData((p) {
      final base = role == MusicianRole.dj
          ? djToUserContext(p as DjProfile)
          : musicianToUserContext(p as MusicianProfile);
      final files = filesAsync.valueOrNull ?? [];
      final videoCount = files
          .where((f) =>
              f.type == UserFileType.profileVideo ||
              f.type == UserFileType.commonVideo)
          .length;
      return <String, dynamic>{
        ...base,
        'reviewCount': reviewsAsync.valueOrNull?.length ?? 0,
        'hasProfileImage': files.any((f) => f.type == UserFileType.profile),
        'videoCount': videoCount,
        if (role == MusicianRole.dj)
          'hasSoundcloud': (p as DjProfile).soundcloudUrl?.isNotEmpty == true,
      };
    });

    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: _c.bg.canvas,
      appBar: AppBar(
        title: Text('Profil', style: DSTextStyle.headingSm.copyWith(color: _c.text.primary)),
        backgroundColor: _c.bg.surface,
        surfaceTintColor: _c.bg.surface,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? LucideIcons.sun : LucideIcons.moon,
              color: _c.text.secondary,
              size: 20,
            ),
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
        ],
      ),
      floatingActionButton: coachContext.valueOrNull != null
          ? FloatingActionButton.extended(
              onPressed: () =>
                  _openCoach(context, ref, coachContext.valueOrNull!),
              backgroundColor: _c.brand.primary,
              foregroundColor: _c.brand.onPrimary,
              elevation: 2,
              icon: const Icon(LucideIcons.sparkles, size: 18),
              label: Text(
                'Profilcoach',
                style: DSTextStyle.labelMd.copyWith(fontWeight: FontWeight.w600),
              ),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: DSSpacing.s4),
        children: [
          // User header — tappable → profile preview
          GestureDetector(
            onTap: () => context.pushNamed(AppRoutes.profilePreview, extra: role),
            child: Padding(
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
                        Row(
                          children: [
                            Text(
                              role == MusicianRole.dj ? 'DJ' : 'Musiker',
                              style: TextStyle(
                                fontSize: 13,
                                color: _c.text.secondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '· Se forhåndsvisning',
                              style: TextStyle(
                                fontSize: 13,
                                color: _c.brand.primaryActive,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, size: 18, color: _c.text.muted),
                ],
              ),
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
            icon: LucideIcons.bell,
            label: 'Notifikationer',
            onTap: () => context.pushNamed(AppRoutes.notificationSettings, extra: role),
          ),
          _MenuItem(
            icon: LucideIcons.mailOpen,
            label: 'Beskeder fra DJTilbud',
            badgeCount: ref.watch(unreadAdminMessageCountProvider(role == MusicianRole.dj)),
            onTap: () => context.pushNamed(AppRoutes.adminMessages, extra: role),
          ),
          _MenuItem(
            icon: LucideIcons.bookOpen,
            label: 'FAQ',
            onTap: () => context.pushNamed(AppRoutes.faq, extra: role),
          ),
          _MenuItem(
            icon: LucideIcons.shield,
            label: 'Privatlivspolitik',
            onTap: () => launchUrl(
              Uri.parse('https://djtilbud.dk/privacy-policy/'),
              mode: LaunchMode.externalApplication,
            ),
          ),

          const SizedBox(height: DSSpacing.s4),
          Divider(height: 1, color: _c.border.subtle),
          const SizedBox(height: DSSpacing.s2),

          // Logout
          _MenuItem(
            icon: LucideIcons.logOut,
            label: 'Log ud',
            color: _c.state.danger,
            onTap: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) RestartWidget.restartApp(context);
            },
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
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
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
      trailing: badgeCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _c.brand.primaryActive,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$badgeCount',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _c.brand.onPrimary,
                ),
              ),
            )
          : color == null
              ? Icon(LucideIcons.chevronRight, color: _c.text.muted, size: 20)
              : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: DSSpacing.s6, vertical: 2),
    );
  }
}
