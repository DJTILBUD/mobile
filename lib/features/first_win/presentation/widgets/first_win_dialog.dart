import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/first_win/presentation/providers/first_win_provider.dart';

/// Which musician walkthrough to show. Mirrors the web app's MusicianVariant.
/// (The DJ role ignores this.)
enum MusicianVariant { solo, withDj }

class _Step {
  const _Step({
    required this.title,
    required this.body,
    required this.icon,
    this.infoBox,
    this.checklistItems,
  });

  final String title;
  final String body;
  final IconData icon;
  final String? infoBox;
  final List<String>? checklistItems;
}

// ─── Step content — copied 1:1 from web app FirstWinPopup.tsx ─────────────────

const _djSteps = <_Step>[
  _Step(
    icon: LucideIcons.trophy,
    title: 'Tillykke, kunden har valgt dig!',
    body:
        'Du er tæt på målstregen, nu skal du lige drible bolden i mål. Samtalen med kunden er uforpligtende, så du skal sælge dig selv og vise, at du er en erfaren DJ med styr på tingene. Læs herunder hvad der sker nu.',
    infoBox: 'Send kunden en SMS og aftal et opkald, det viser professionalismen.',
  ),
  _Step(
    icon: LucideIcons.phone,
    title: 'Kontakt kunden',
    body: 'Ring til kunden. Gennemgå listen, alle punkter skal afklares inden I lægger på.',
    checklistItems: [
      'Aftal playliste, sangønsker og opstilling',
      'Spørg ind til festen og bekræft adresse',
    ],
  ),
  _Step(
    icon: LucideIcons.fileText,
    title: 'Aftal fakturering',
    body:
        'Inden samtalen slutter skal faktureringen afklares. Vi sender faktura på 50% efter samtalen,de resterende 50% betales inden arrangementet.',
    checklistItems: [
      'Bekræft beløb + evt. ekstra (opsætning, tid, timer)',
      'Sig til kunden: Vi sender faktura på 50% efter samtalen - under forudsætning af, at beløbet er afklaret',
    ],
    infoBox:
        'Bemærk: Er der tidlig opsætning eller ændring i tidspunkt, skal dette afklares før fakturaen sendes.',
  ),
  _Step(
    icon: LucideIcons.calendarCheck,
    title: 'Bekræft at du er klar',
    body:
        "5 dage før arrangementet bliver knappen 'Bekræft klar' aktiv,klik den så vi ved du er klar.",
  ),
];

const _musicianWithDjSteps = <_Step>[
  _Step(
    icon: LucideIcons.trophy,
    title: 'Tillykke, du har vundet dit første job med DJ!',
    body:
        "Du spiller dette job med en DJ, I kontakter begge kunden. DJ'en lukker aftalen og fakturerer, du sørger for sax-delen.",
    infoBox:
        "Send kunden en SMS og aftal opkald, koordinér med DJ'en så I ikke ringer oven i hinanden.",
  ),
  _Step(
    icon: LucideIcons.phone,
    title: 'Kontakt kunden',
    body: 'Ring til kunden. Gennemgå listen, alle punkter skal afklares inden I lægger på.',
    checklistItems: [
      'Snak om musikken og opstilling for sax-delen',
      "Koordinér med DJ'en hvordan i spiller sammen",
      'Spørg ind til arrangementet og bekræft adresse',
    ],
  ),
  _Step(
    icon: LucideIcons.heartHandshake,
    title: "Overlad lukningen til DJ'en",
    body:
        "Når du spiller med DJ behæver du ikke tale fakturering med kunden, det gør DJ'en. Bekræft over for kunden at DJ'en følger op, og giv DJ'en et overblik over jeres aftaler.",
    checklistItems: [
      "Send en kort besked til DJ'en med jeres aftaler fra samtalen",
      'Har kunden et særligt ønske der koster ekstra? Registrer tillægget på jobsiden',
    ],
    infoBox:
        "DJ'en sender faktura på 50% efter sin samtale med kunden. De resterende 50% betales inden arrangementet.",
  ),
  _Step(
    icon: LucideIcons.calendarCheck,
    title: 'Bekræft at du er klar',
    body:
        "5 dage før arrangementet bliver knappen 'Bekræft klar' aktiv,klik den så vi ved du er klar.",
  ),
];

const _musicianSoloSteps = <_Step>[
  _Step(
    icon: LucideIcons.trophy,
    title: 'Tillykke, du har vundet dit første job uden DJ!',
    body:
        'Du er tæt på målstregen, nu skal du lige drible bolden i mål. Vis at du er en erfaren saxofonist med styr på tingene. Læs herunder hvad der sker nu.',
    infoBox: 'Send kunden en SMS og aftal et opkald, det viser professionalismen.',
  ),
  _Step(
    icon: LucideIcons.phone,
    title: 'Kontakt kunden',
    body: 'Ring til kunden. Gennemgå listen, alle punkter skal afklares inden I lægger på.',
    checklistItems: [
      'Aftal musikken, ønsker og opstilling',
      'Spørg ind til arrangementet og bekræft adresse',
    ],
  ),
  _Step(
    icon: LucideIcons.fileText,
    title: 'Aftal fakturering',
    body:
        'Inden samtalen slutter skal faktureringen afklares. Vi sender faktura på 50% efter samtalen,de resterende 50% betales inden arrangementet.',
    checklistItems: [
      'Bekræft beløb + evt. ekstra (opsætning, tid, sets)',
      'Har kunden et særligt ønske der koster ekstra? Registrer tillægget på jobsiden inden fakturaen sendes',
      'Sig til kunden: Vi sender faktura på 50% efter samtalen,under forudsætning af, at beløbet er afklaret',
    ],
  ),
  _Step(
    icon: LucideIcons.calendarCheck,
    title: 'Bekræft at du er klar',
    body:
        "5 dage før arrangementet bliver knappen 'Bekræft klar' aktiv,klik den så vi ved du er klar.",
  ),
];

/// Shows the first-win celebration dialog. Marks the popup as shown only after
/// the user dismisses the final step, so cancelling mid-walkthrough (or closing
/// with the X) lets it reappear next time. Idempotent via the RPC's IS NULL guard.
Future<void> showFirstWinDialog(
  BuildContext context,
  WidgetRef ref,
  MusicianRole role, {
  MusicianVariant musicianVariant = MusicianVariant.solo,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _FirstWinDialog(role: role, musicianVariant: musicianVariant),
  );
}

class _FirstWinDialog extends ConsumerStatefulWidget {
  const _FirstWinDialog({required this.role, required this.musicianVariant});

  final MusicianRole role;
  final MusicianVariant musicianVariant;

  @override
  ConsumerState<_FirstWinDialog> createState() => _FirstWinDialogState();
}

class _FirstWinDialogState extends ConsumerState<_FirstWinDialog> {
  int _step = 0;
  bool _finishing = false;
  final Map<int, Set<int>> _checkedByStep = {};

  List<_Step> get _steps {
    if (widget.role == MusicianRole.dj) return _djSteps;
    return widget.musicianVariant == MusicianVariant.solo
        ? _musicianSoloSteps
        : _musicianWithDjSteps;
  }

  Set<int> get _currentChecked => _checkedByStep[_step] ?? <int>{};

  bool get _allItemsChecked {
    final items = _steps[_step].checklistItems;
    if (items == null || items.isEmpty) return true;
    final checked = _currentChecked;
    return List.generate(items.length, (i) => i).every(checked.contains);
  }

  void _toggleItem(int index) {
    setState(() {
      final set = Set<int>.from(_checkedByStep[_step] ?? <int>{});
      set.contains(index) ? set.remove(index) : set.add(index);
      _checkedByStep[_step] = set;
    });
  }

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
    final c = DSTheme.of(context);
    final steps = _steps;
    final current = steps[_step];
    final isLast = _step == steps.length - 1;
    final items = current.checklistItems;

    // canPop:false blocks the Android back button/gesture; barrierDismissible is
    // already false. There is no close button, so the walkthrough can ONLY be
    // dismissed by completing it and tapping "Forstået" — matches the web app.
    return PopScope(
      canPop: false,
      child: Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: DSSpacing.s4, vertical: DSSpacing.s8),
      backgroundColor: c.bg.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.lg)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    DSSpacing.s6, DSSpacing.s8, DSSpacing.s6, DSSpacing.s4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                        // Icon circle
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.brand.primary.withValues(alpha: 0.18),
                          ),
                          child: Icon(current.icon, size: 32, color: c.brand.primaryActive),
                        ),
                        const SizedBox(height: DSSpacing.s4),

                        // Title + body
                        Text(
                          current.title,
                          style: DSTextStyle.headingLg.copyWith(color: c.text.primary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: DSSpacing.s3),
                        Text(
                          current.body,
                          style: DSTextStyle.bodyLg.copyWith(color: c.text.secondary),
                          textAlign: TextAlign.center,
                        ),

                        // Info box BEFORE checklist when there is no checklist (step 1)
                        if (current.infoBox != null && items == null) ...[
                          const SizedBox(height: DSSpacing.s4),
                          _InfoBox(text: current.infoBox!, c: c),
                        ],

                        // Checklist items
                        if (items != null) ...[
                          const SizedBox(height: DSSpacing.s4),
                          ...List.generate(items.length, (i) {
                            return Padding(
                              padding: EdgeInsets.only(top: i == 0 ? 0 : DSSpacing.s2),
                              child: _ChecklistCard(
                                text: items[i],
                                checked: _currentChecked.contains(i),
                                onTap: () => _toggleItem(i),
                                c: c,
                              ),
                            );
                          }),
                        ],

                        // Info box AFTER checklist when both exist (step 3)
                        if (current.infoBox != null && items != null) ...[
                          const SizedBox(height: DSSpacing.s4),
                          _InfoBox(text: current.infoBox!, c: c),
                        ],

                        // Pagination dots
                        const SizedBox(height: DSSpacing.s4),
                        _StepDots(
                          count: steps.length,
                          current: _step,
                          color: c.brand.primary,
                          mutedColor: c.border.subtle,
                        ),
                  ],
                ),
              ),
            ),

            // Footer with top border + prev / next
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.border.subtle)),
              ),
              padding: const EdgeInsets.all(DSSpacing.s4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DSButton(
                    label: 'Forrige',
                    variant: DSButtonVariant.ghost,
                    size: DSButtonSize.md,
                    iconLeft: LucideIcons.arrowLeft,
                    onTap: (_step == 0 || _finishing)
                        ? null
                        : () => setState(() => _step--),
                  ),
                  DSButton(
                    label: isLast ? 'Forstået' : 'Næste',
                    variant: DSButtonVariant.primary,
                    size: DSButtonSize.md,
                    iconRight: isLast ? LucideIcons.check : LucideIcons.arrowRight,
                    isLoading: _finishing,
                    onTap: (!_allItemsChecked || _finishing) ? null : _handleNext,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.text, required this.c});

  final String text;
  final DSColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DSSpacing.s4),
      decoration: BoxDecoration(
        color: c.bg.inputBg,
        borderRadius: BorderRadius.circular(DSRadius.lg),
      ),
      child: Text(
        text,
        style: DSTextStyle.bodyMd.copyWith(color: c.text.secondary),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({
    required this.text,
    required this.checked,
    required this.onTap,
    required this.c,
  });

  final String text;
  final bool checked;
  final VoidCallback onTap;
  final DSColors c;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.all(DSSpacing.s4),
        decoration: BoxDecoration(
          color: c.bg.surface,
          border: Border.all(color: c.border.subtle),
          borderRadius: BorderRadius.circular(DSRadius.lg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            checked
                ? Icon(LucideIcons.checkCircle, size: 20, color: c.brand.primary)
                : Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: c.border.subtle, width: 2),
                    ),
                  ),
            const SizedBox(width: DSSpacing.s3),
            Expanded(
              child: Text(
                text,
                style: DSTextStyle.bodyMd.copyWith(
                  color: checked ? c.text.muted : c.text.primary,
                  decoration: checked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
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
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: i == current ? 24 : 8,
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
