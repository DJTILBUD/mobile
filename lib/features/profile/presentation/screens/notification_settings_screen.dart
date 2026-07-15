import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/notifications/notifications_service.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/chat/presentation/providers/admin_support_provider.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key, required this.role});

  final MusicianRole role;

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _loading = true;
  String? _error;
  Set<String> _disabled = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final data =
          await supabase
              .from('DeviceTokens')
              .select('disabled_notification_types')
              .eq('user_id', userId)
              .limit(1)
              .maybeSingle();

      if (mounted) {
        setState(() {
          _loading = false;
          final raw = data?['disabled_notification_types'] as List<dynamic>?;
          _disabled = (raw?.cast<String>() ?? <String>[]).toSet();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Kunne ikke hente indstillinger. Prøv igen.';
        });
      }
    }
  }

  bool _isEnabled(List<String> types) =>
      !types.any((t) => _disabled.contains(t));

  Future<void> _toggle(List<String> types, bool enabled) async {
    // Never write to DeviceTokens while impersonating — this UPDATE matches the
    // real user's device rows and would change which notifications they get.
    if (NotificationsService.isImpersonating) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notifikationsindstillinger kan ikke ændres under impersonation.',
          ),
        ),
      );
      return;
    }

    // Optimistic update
    setState(() {
      if (enabled) {
        _disabled.removeAll(types);
      } else {
        _disabled.addAll(types);
      }
    });

    try {
      final userId = supabase.auth.currentUser!.id;
      await supabase
          .from('DeviceTokens')
          .update({'disabled_notification_types': _disabled.toList()})
          .eq('user_id', userId);
    } catch (_) {
      // Rollback
      if (mounted) {
        setState(() {
          if (enabled) {
            _disabled.addAll(types);
          } else {
            _disabled.removeAll(types);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    final isDj = widget.role == MusicianRole.dj;
    final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;

    return Scaffold(
      backgroundColor: c.bg.canvas,
      appBar: AppBar(
        backgroundColor: c.bg.surface,
        surfaceTintColor: c.bg.surface,
        title: Text(
          'Notifikationsindstillinger',
          style: DSTextStyle.headingSm.copyWith(color: c.text.primary),
        ),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      style: DSTextStyle.bodyMd.copyWith(color: c.text.muted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DSSpacing.s4),
                    DSButton(
                      label: 'Prøv igen',
                      variant: DSButtonVariant.secondary,
                      onTap: () {
                        setState(() {
                          _loading = true;
                          _error = null;
                        });
                        _load();
                      },
                    ),
                  ],
                ),
              )
              : ListView(
                children: [
                  for (final section in _sectionsForRole(isDj, isAdmin)) ...[
                    _SectionHeader(label: section.header, colors: c),
                    for (final g in section.groups)
                      _ToggleTile(
                        label: g.label,
                        subtitle: g.subtitle,
                        enabled: _isEnabled(g.types),
                        onChanged: (v) => _toggle(g.types, v),
                        colors: c,
                      ),
                  ],
                  const SizedBox(height: DSSpacing.s6),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DSSpacing.s6,
                    ),
                    child: Text(
                      'Ændringer gælder for alle dine enheder.',
                      style: DSTextStyle.bodySm.copyWith(color: c.text.muted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: DSSpacing.s6),
                ],
              ),
    );
  }

  // Every notification the musician can actually silence. Each `types` entry is the exact
  // opt-out string the sending Edge Function checks against DeviceTokens.disabled_notification_types
  // (web-app/supabase/functions/notify-*). Adding a type here that no sender honours would show a
  // toggle that does nothing, so keep this in sync with those functions. Deliberately EXCLUDED:
  // `ext_job_assigned` (notify-ext-job-assigned) and `custom_notification` (notify-custom) — their
  // senders do not read disabled_notification_types, so they cannot be turned off.
  List<_NotifSection> _sectionsForRole(bool isDj, bool isAdmin) {
    return [
      _NotifSection(
        header: 'Job',
        groups: [
          _NotifGroup(
            label: 'Nye job',
            subtitle: 'Når der er et nyt bookingønske der matcher dig',
            // Only DJs receive re-sent jobs (`another_round`).
            types:
                isDj ? const ['new_job', 'another_round'] : const ['new_job'],
          ),
          if (!isDj)
            const _NotifGroup(
              label: 'Udvalgte job',
              subtitle: 'Når du er tildelt et eksklusivt job direkte',
              types: ['new_ext_job'],
            ),
        ],
      ),
      _NotifSection(
        header: 'Tilbud',
        groups: [
          _NotifGroup(
            label: 'Svar på tilbud',
            subtitle:
                isDj
                    ? 'Når et tilbud accepteres eller afvises'
                    : 'Når dit tilbud accepteres eller afvises',
            types:
                isDj
                    ? const ['quote_won', 'quote_lost']
                    : const ['offer_won', 'offer_lost'],
          ),
        ],
      ),
      const _NotifSection(
        header: 'Kommunikation',
        groups: [
          _NotifGroup(
            label: 'Chatbeskeder',
            subtitle: 'Når du modtager en ny besked',
            types: ['chat_message'],
          ),
          _NotifGroup(
            label: 'Reaktioner',
            subtitle: 'Når nogen reagerer på din besked',
            types: ['chat_reaction'],
          ),
          _NotifGroup(
            label: 'Ubesvarede chats',
            subtitle: 'Påmindelse om at svare i en chat du ikke har brugt',
            types: ['chat_unused_reminder'],
          ),
        ],
      ),
      const _NotifSection(
        header: 'Påmindelser',
        groups: [
          _NotifGroup(
            label: 'Klar-påmindelser',
            subtitle: 'Påmindelser om at bekræfte du er klar til et job',
            types: ['ready_reminder'],
          ),
          _NotifGroup(
            label: 'Ekstra timer',
            subtitle: 'Påmindelser om at registrere ekstra timer efter et job',
            types: ['extra_hours_reminder'],
          ),
          _NotifGroup(
            label: 'Kontakt kunden',
            subtitle: 'Påmindelser om at kontakte kunden efter en booking',
            types: ['contact_customer_reminder'],
          ),
          _NotifGroup(
            label: 'Send faktura',
            subtitle: 'Påmindelser om at markere jobbet klar til fakturering',
            types: ['send_invoice_reminder'],
          ),
        ],
      ),
      if (isDj)
        const _NotifSection(
          header: 'Content',
          groups: [
            _NotifGroup(
              label: 'Content-påmindelser',
              subtitle:
                  'Påmindelser om at optage og uploade content fra dine job',
              types: ['content_record_reminder', 'content_upload_reminder'],
            ),
            _NotifGroup(
              label: 'Svar på content',
              subtitle: 'Når dit content bliver godkendt eller afvist',
              types: ['content_accepted', 'content_rejected'],
            ),
          ],
        ),
      _NotifSection(
        header: 'Andet',
        groups: [
          if (isDj)
            const _NotifGroup(
              label: 'Sangønsker',
              subtitle: 'Når en gæst sender et sangønske til dit job',
              types: ['song_request'],
            ),
          const _NotifGroup(
            label: 'Beskeder fra DJTilbud',
            subtitle: 'Vigtige beskeder fra DJTilbuds team',
            types: ['admin_message'],
          ),
        ],
      ),
      // Admin-only: support-inbox pushes (a user wrote to DJTILBUD support).
      if (isAdmin)
        const _NotifSection(
          header: 'Support (team)',
          groups: [
            _NotifGroup(
              label: 'Support-beskeder',
              subtitle: 'Når en bruger skriver til DJTILBUD-support',
              types: ['support_admin'],
            ),
          ],
        ),
    ];
  }
}

/// A single toggle row: one user-facing notification category mapped to the
/// opt-out type string(s) the sender checks. Turning it off adds every string
/// in [types] to DeviceTokens.disabled_notification_types.
class _NotifGroup {
  const _NotifGroup({
    required this.label,
    required this.subtitle,
    required this.types,
  });

  final String label;
  final String subtitle;
  final List<String> types;
}

/// A titled group of [_NotifGroup] toggles.
class _NotifSection {
  const _NotifSection({required this.header, required this.groups});

  final String header;
  final List<_NotifGroup> groups;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.colors});

  final String label;
  final DSColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DSSpacing.s6,
        DSSpacing.s4,
        DSSpacing.s6,
        DSSpacing.s1,
      ),
      child: Text(
        label.toUpperCase(),
        style: DSTextStyle.labelSm.copyWith(
          color: colors.text.muted,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.label,
    required this.subtitle,
    required this.enabled,
    required this.onChanged,
    required this.colors,
  });

  final String label;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final DSColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.bg.surface,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s6,
          vertical: DSSpacing.s1,
        ),
        title: Text(
          label,
          style: DSTextStyle.bodyMd.copyWith(
            color: colors.text.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: DSTextStyle.bodySm.copyWith(color: colors.text.muted),
        ),
        trailing: Switch.adaptive(
          value: enabled,
          onChanged: onChanged,
          activeColor: colors.brand.primaryActive,
        ),
      ),
    );
  }
}
