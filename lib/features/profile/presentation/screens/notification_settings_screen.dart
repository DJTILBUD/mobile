import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';

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
      final data = await supabase
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

    return Scaffold(
      backgroundColor: c.bg.canvas,
      appBar: AppBar(
        backgroundColor: c.bg.surface,
        surfaceTintColor: c.bg.surface,
        title: Text(
          'Notifikationer',
          style: DSTextStyle.headingSm.copyWith(color: c.text.primary),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        style:
                            DSTextStyle.bodyMd.copyWith(color: c.text.muted),
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
                    _SectionHeader(label: 'Job-underretninger', colors: c),
                    _ToggleTile(
                      label: 'Nye job',
                      subtitle: 'Når der er et nyt bookingønske der matcher dig',
                      enabled: _isEnabled(['new_job', 'another_round']),
                      onChanged: (v) => _toggle(['new_job', 'another_round'], v),
                      colors: c,
                    ),
                    if (!isDj)
                      _ToggleTile(
                        label: 'Udvalgte job',
                        subtitle: 'Når du er tildelt et eksklusivt job direkte',
                        enabled: _isEnabled(['new_ext_job']),
                        onChanged: (v) => _toggle(['new_ext_job'], v),
                        colors: c,
                      ),
                    _SectionHeader(label: 'Tilbud', colors: c),
                    _ToggleTile(
                      label: 'Svar på tilbud',
                      subtitle: isDj
                          ? 'Når et tilbud accepteres eller afvises'
                          : 'Når dit tilbud accepteres eller afvises',
                      enabled: _isEnabled(
                        isDj
                            ? ['quote_won', 'quote_lost']
                            : ['offer_won', 'offer_lost'],
                      ),
                      onChanged: (v) => _toggle(
                        isDj
                            ? ['quote_won', 'quote_lost']
                            : ['offer_won', 'offer_lost'],
                        v,
                      ),
                      colors: c,
                    ),
                    _SectionHeader(label: 'Kommunikation', colors: c),
                    _ToggleTile(
                      label: 'Chatbeskeder',
                      subtitle: 'Når du modtager en ny besked',
                      enabled: _isEnabled(['chat_message']),
                      onChanged: (v) => _toggle(['chat_message'], v),
                      colors: c,
                    ),
                    _ToggleTile(
                      label: 'Klar-påmindelser',
                      subtitle: 'Påmindelser om at bekræfte du er klar til et job',
                      enabled: _isEnabled(['ready_reminder']),
                      onChanged: (v) => _toggle(['ready_reminder'], v),
                      colors: c,
                    ),
                    _SectionHeader(label: 'Andet', colors: c),
                    _ToggleTile(
                      label: 'Beskeder fra DJTilbud',
                      subtitle: 'Vigtige beskeder fra DJTilbuds team',
                      enabled: _isEnabled(['admin_message']),
                      onChanged: (v) => _toggle(['admin_message'], v),
                      colors: c,
                    ),
                    const SizedBox(height: DSSpacing.s6),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: DSSpacing.s6),
                      child: Text(
                        'Ændringer gælder for alle dine enheder.',
                        style:
                            DSTextStyle.bodySm.copyWith(color: c.text.muted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: DSSpacing.s6),
                  ],
                ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.colors});

  final String label;
  final DSColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DSSpacing.s6, DSSpacing.s4, DSSpacing.s6, DSSpacing.s1),
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
            horizontal: DSSpacing.s6, vertical: DSSpacing.s1),
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
