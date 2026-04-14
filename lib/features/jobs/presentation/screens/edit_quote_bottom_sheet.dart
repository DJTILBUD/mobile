import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/utils/equipment_description.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/dj_quote.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/equipment_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

const kEditWindowMinutes = 10;

/// Opens the edit quote bottom sheet. Returns true if the quote was saved.
Future<bool> showEditQuoteBottomSheet(
  BuildContext context, {
  required DjQuote quote,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => EditQuoteBottomSheet(quote: quote),
  );
  return result == true;
}

class EditQuoteBottomSheet extends ConsumerStatefulWidget {
  const EditQuoteBottomSheet({super.key, required this.quote});

  final DjQuote quote;

  @override
  ConsumerState<EditQuoteBottomSheet> createState() =>
      _EditQuoteBottomSheetState();
}

class _EditQuoteBottomSheetState extends ConsumerState<EditQuoteBottomSheet> {
  static const _c = lightColors;

  late final TextEditingController _priceCtrl;
  late final TextEditingController _pitchCtrl;
  late final TextEditingController _earlyPriceCtrl;

  late List<String> _selectedEquipment;
  late int _topSpeakerCount;
  late int _bottomSpeakerCount;
  bool _noEquipmentSelected = false;

  bool _offerEarlySetup = false;
  int _secondsLeft = 0;
  Timer? _timer;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _priceCtrl =
        TextEditingController(text: widget.quote.priceDkk.toString());
    _pitchCtrl = TextEditingController(text: widget.quote.salesPitch);

    // Pre-populate equipment from existing quote (handles both JSON and legacy free-text)
    final parsed = parseEquipmentDescription(widget.quote.equipmentDescription);
    _selectedEquipment = List.from(parsed.selectedEquipment);
    _topSpeakerCount = parsed.topSpeakerCount;
    _bottomSpeakerCount = parsed.bottomSpeakerCount;
    // If the saved description is structured JSON with empty gear, the DJ
    // explicitly chose "no equipment" — reflect that in the checkbox.
    final structured = parseStructuredEquipmentDescription(widget.quote.equipmentDescription);
    if (structured != null && structured.selectedEquipment.isEmpty) {
      _noEquipmentSelected = true;
    }
    _earlyPriceCtrl = TextEditingController(
      text: widget.quote.earlySetupPrice?.toString() ?? '',
    );

    // Preserve early setup offering if it was already set
    _offerEarlySetup = widget.quote.earlySetupStatus == 'offered' ||
        widget.quote.earlySetupStatus == 'accepted';

    _computeSecondsLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _computeSecondsLeft();
      }
    });
  }

  void _computeSecondsLeft() {
    final deadline = widget.quote.createdAt
        .add(const Duration(minutes: kEditWindowMinutes));
    final diff = deadline.difference(DateTime.now()).inSeconds;
    setState(() => _secondsLeft = diff < 0 ? 0 : diff);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _priceCtrl.dispose();
    _pitchCtrl.dispose();
    _earlyPriceCtrl.dispose();
    super.dispose();
  }

  bool get _windowOpen => _secondsLeft > 0;

  String get _countdownLabel {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String? _validate() {
    final price = int.tryParse(_priceCtrl.text.trim());
    if (price == null || price <= 0) return 'Pris skal være større end 0';
    if (_selectedEquipment.isEmpty && !_noEquipmentSelected) return 'Vælg mindst ét stykke udstyr';
    final pitchLen = _pitchCtrl.text.trim().length;
    if (pitchLen > 0 && pitchLen < 100) {
      return 'Salgstale skal enten være tom eller mindst 100 tegn';
    }
    if (_offerEarlySetup) {
      final ep = int.tryParse(_earlyPriceCtrl.text.trim());
      if (ep == null || ep < 0) return 'Pris for tidlig opsætning er ugyldig';
    }
    return null;
  }

  Future<void> _save() async {
    final err = _validate();
    if (err != null) {
      setState(() => _validationError = err);
      return;
    }
    setState(() => _validationError = null);

    final price = int.parse(_priceCtrl.text.trim());
    final earlyPrice = _offerEarlySetup
        ? (int.tryParse(_earlyPriceCtrl.text.trim()) ?? 0)
        : null;

    final success = await ref.read(editDjQuoteProvider.notifier).edit(
          quoteId: widget.quote.id,
          priceDkk: price,
          equipmentDescription: serializeEquipmentDescription(
            _selectedEquipment,
            _topSpeakerCount,
            _bottomSpeakerCount,
          ),
          salesPitch: _pitchCtrl.text.trim(),
          earlySetupStatus: _offerEarlySetup ? 'offered' : null,
          earlySetupPrice: earlyPrice,
        );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      DSToast.show(context,
          variant: DSToastVariant.error, title: 'Noget gik galt. Prøv igen.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(editDjQuoteProvider) is AsyncLoading;
    final isExpired = !_windowOpen;
    final isUrgent = _secondsLeft < 120; // < 2 minutes

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: _c.bg.canvas,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(DSRadius.lg)),
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: DSSpacing.s2),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _c.border.subtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: DSSpacing.s1),

              // Countdown banner
              _CountdownBanner(
                isExpired: isExpired,
                isUrgent: isUrgent,
                countdownLabel: _countdownLabel,
              ),

              // Scrollable form
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(
                      DSSpacing.s4, DSSpacing.s4, DSSpacing.s4, DSSpacing.s8),
                  children: [
                    Text(
                      'Redigér tilbud',
                      style: DSTextStyle.headingMd.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _c.text.primary,
                      ),
                    ),
                    const SizedBox(height: DSSpacing.s4),

                    DSInput(
                      controller: _priceCtrl,
                      label: 'Pris (kr.)',
                      hint: '0',
                      keyboardType: TextInputType.number,
                      enabled: !isExpired && !isSaving,
                    ),
                    const SizedBox(height: DSSpacing.s4),

                    IgnorePointer(
                      ignoring: isExpired || isSaving,
                      child: Opacity(
                        opacity: (isExpired || isSaving) ? 0.5 : 1.0,
                        child: EquipmentPicker(
                          selectedEquipment: _selectedEquipment,
                          topSpeakerCount: _topSpeakerCount,
                          bottomSpeakerCount: _bottomSpeakerCount,
                          noEquipmentSelected: _noEquipmentSelected,
                          onChanged: (selected, top, bund) => setState(() {
                            _selectedEquipment = selected;
                            _topSpeakerCount = top;
                            _bottomSpeakerCount = bund;
                            if (selected.isNotEmpty) _noEquipmentSelected = false;
                          }),
                          onNoEquipmentChanged: (value) => setState(() {
                            _noEquipmentSelected = value;
                            if (value) _selectedEquipment = [];
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: DSSpacing.s4),

                    DSInput(
                      controller: _pitchCtrl,
                      label: 'Salgstale',
                      hint: 'Beskriv dig selv og dit tilbud... (min. 100 tegn)',
                      maxLines: 6,
                      minLines: 4,
                      enabled: !isExpired && !isSaving,
                    ),
                    const SizedBox(height: DSSpacing.s4),

                    // Early setup toggle — only editable before customer decides
                    if (widget.quote.earlySetupStatus != 'accepted' &&
                        widget.quote.earlySetupStatus != 'rejected') ...[
                      DSSwitch(
                        label: 'Tilbyd tidlig opsætning',
                        value: _offerEarlySetup,
                        onChanged: (isExpired || isSaving)
                            ? null
                            : (v) => setState(() => _offerEarlySetup = v),
                      ),
                      if (_offerEarlySetup) ...[
                        const SizedBox(height: DSSpacing.s3),
                        DSInput(
                          controller: _earlyPriceCtrl,
                          label: 'Pris for tidlig opsætning (kr.)',
                          hint: '0 for gratis',
                          keyboardType: TextInputType.number,
                          enabled: !isExpired && !isSaving,
                        ),
                      ],
                      const SizedBox(height: DSSpacing.s4),
                    ],

                    if (_validationError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(DSSpacing.s3),
                        decoration: BoxDecoration(
                          color: _c.state.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(DSRadius.sm),
                          border: Border.all(
                              color: _c.state.danger.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _validationError!,
                          style: DSTextStyle.labelMd.copyWith(color: _c.state.danger),
                        ),
                      ),
                      const SizedBox(height: DSSpacing.s4),
                    ],

                    if (!isExpired)
                      DSButton(
                        label: 'Gem ændringer',
                        variant: DSButtonVariant.primary,
                        expand: true,
                        isLoading: isSaving,
                        onTap: isSaving ? null : _save,
                      )
                    else
                      DSButton(
                        label: 'Redigeringsvinduet er udløbet',
                        variant: DSButtonVariant.secondary,
                        expand: true,
                        onTap: null,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CountdownBanner extends StatelessWidget {
  const _CountdownBanner({
    required this.isExpired,
    required this.isUrgent,
    required this.countdownLabel,
  });

  final bool isExpired;
  final bool isUrgent;
  final String countdownLabel;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color text;
    final String label;
    final IconData icon;

    if (isExpired) {
      bg = _c.state.danger.withValues(alpha: 0.08);
      border = _c.state.danger.withValues(alpha: 0.3);
      text = _c.state.danger;
      label = 'Redigeringsvinduet er udløbet';
      icon = LucideIcons.timerOff;
    } else if (isUrgent) {
      bg = _c.state.warning.withValues(alpha: 0.12);
      border = _c.state.warning.withValues(alpha: 0.4);
      text = _c.text.primary;
      label = 'Skynd dig! Du kan redigere i $countdownLabel';
      icon = LucideIcons.timer;
    } else {
      bg = _c.state.info.withValues(alpha: 0.08);
      border = _c.state.info.withValues(alpha: 0.3);
      text = _c.text.primary;
      label = 'Du kan redigere dit tilbud i $countdownLabel';
      icon = LucideIcons.timer;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
          DSSpacing.s4, DSSpacing.s2, DSSpacing.s4, 0),
      padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s3, vertical: DSSpacing.s2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DSRadius.sm),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: text),
          const SizedBox(width: DSSpacing.s2),
          Text(label, style: DSTextStyle.labelMd.copyWith(color: text)),
        ],
      ),
    );
  }
}
