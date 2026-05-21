import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/first_win/presentation/providers/first_win_provider.dart';

class _Step {
  const _Step({required this.title, required this.body, required this.icon});
  final String title;
  final String body;
  final IconData icon;
}

const _djSteps = <_Step>[
  _Step(
    icon: LucideIcons.trophy,
    title: 'Tillykke med dit første job!',
    body:
        'Kunden har valgt dig — det er en stor milepæl. Her er hvad der sker nu.',
  ),
  _Step(
    icon: LucideIcons.phone,
    title: 'Vi kontakter kunden',
    body:
        'DJ Tilbud ringer typisk kunden op inden for kort tid for at bekræfte detaljerne. Du får besked når kunden er kontaktet, og du kan så aftale det sidste direkte.',
  ),
  _Step(
    icon: LucideIcons.checkCircle,
    title: 'Bekræft du er klar',
    body:
        'Gennemgå udstyrslisten og bekræft at du er klar når tiden nærmer sig. Efter jobbet markerer du det som spillet, og vi sender faktura.',
  ),
];

const _musicianSteps = <_Step>[
  _Step(
    icon: LucideIcons.trophy,
    title: 'Tillykke med dit første job!',
    body:
        'Kunden har valgt dig — det er en stor milepæl. Her er hvad der sker nu.',
  ),
  _Step(
    icon: LucideIcons.phone,
    title: 'Vi koordinerer med kunden',
    body:
        'DJ Tilbud kontakter typisk kunden hurtigt for at bekræfte detaljerne. Du får besked når kunden er kontaktet, og I kan så aftale det sidste direkte.',
  ),
  _Step(
    icon: LucideIcons.checkCircle,
    title: 'Bekræft du er klar',
    body:
        'Gennemgå jobbets detaljer og bekræft at du er klar når tiden nærmer sig. Efter jobbet markerer du det som spillet, og vi sender faktura.',
  ),
];

/// Shows the first-win celebration dialog. Marks the popup as shown only after
/// the user dismisses the final step, so cancelling mid-walkthrough lets it
/// reappear next time. Idempotent via the RPC's IS NULL guard.
Future<void> showFirstWinDialog(
  BuildContext context,
  WidgetRef ref,
  MusicianRole role,
) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _FirstWinDialog(role: role),
  );
}

class _FirstWinDialog extends ConsumerStatefulWidget {
  const _FirstWinDialog({required this.role});

  final MusicianRole role;

  @override
  ConsumerState<_FirstWinDialog> createState() => _FirstWinDialogState();
}

class _FirstWinDialogState extends ConsumerState<_FirstWinDialog> {
  int _step = 0;
  bool _finishing = false;

  List<_Step> get _steps =>
      widget.role == MusicianRole.dj ? _djSteps : _musicianSteps;

  Future<void> _handleNext() async {
    final isLast = _step == _steps.length - 1;
    if (!isLast) {
      setState(() => _step++);
      return;
    }
    setState(() => _finishing = true);
    try {
      await markFirstWinShown(ref, widget.role);
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final current = _steps[_step];
    final isLast = _step == _steps.length - 1;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DSRadius.lg),
      ),
      backgroundColor: _c.bg.surface,
      child: Padding(
        padding: const EdgeInsets.all(DSSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _c.brand.primary.withValues(alpha: 0.12),
              ),
              child: Icon(current.icon, size: 32, color: _c.brand.primary),
            ),
            const SizedBox(height: DSSpacing.s4),
            Text(
              current.title,
              style: DSTextStyle.headingSm.copyWith(color: _c.text.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DSSpacing.s3),
            Text(
              current.body,
              style: DSTextStyle.bodyMd.copyWith(color: _c.text.secondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DSSpacing.s4),
            _StepDots(count: _steps.length, current: _step, color: _c.brand.primary, mutedColor: _c.border.subtle),
            const SizedBox(height: DSSpacing.s4),
            DSButton(
              label: isLast ? 'Forstået' : 'Næste',
              variant: DSButtonVariant.primary,
              size: DSButtonSize.lg,
              expand: true,
              isLoading: _finishing,
              onTap: _finishing ? null : _handleNext,
            ),
            if (_step > 0 && !_finishing) ...[
              const SizedBox(height: DSSpacing.s2),
              GestureDetector(
                onTap: () => setState(() => _step--),
                child: Text(
                  'Tilbage',
                  style: DSTextStyle.labelMd.copyWith(color: _c.text.muted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({
    required this.count,
    required this.current,
    required this.color,
    required this.mutedColor,
  });

  final int count;
  final int current;
  final Color color;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i <= current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: i == current ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? color : mutedColor,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
