import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/jobs/domain/equipment_delivery.dart';

/// Danish labels for the delivery choice fields (wire values stay in the domain enums).
const deliveryAccessLabels = {
  DeliveryAccess.ground: 'Stueplan',
  DeliveryAccess.elevator: 'Elevator',
  DeliveryAccess.stairs: 'Trapper uden elevator',
  DeliveryAccess.unknown: 'Ved ikke',
};
const deliverySetupDayLabels = {
  DeliverySetupDay.dayBefore: 'Dagen før',
  DeliverySetupDay.sameDay: 'Samme dag',
};
const deliveryTeardownDayLabels = {
  DeliveryTeardownDay.nextDay: 'Dagen efter',
  DeliveryTeardownDay.sameNight: 'Samme aften',
};

/// A labelled row of single-choice chips. Tapping the selected chip again clears it (the field
/// is optional until the DJ knows the answer), so a null value is representable, unlike
/// `DSSegmentedControl`.
class DeliveryChoiceField<T> extends StatelessWidget {
  const DeliveryChoiceField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final Map<T, String> options;
  final T? value;
  final ValueChanged<T?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: DSTextStyle.labelMd.copyWith(color: c.text.secondary),
        ),
        const SizedBox(height: DSSpacing.s2),
        Wrap(
          spacing: DSSpacing.s2,
          runSpacing: DSSpacing.s2,
          children: [
            for (final entry in options.entries)
              DSChip(
                label: entry.value,
                selected: entry.key == value,
                enabled: enabled || entry.key == value,
                onTap:
                    enabled
                        ? () => onChanged(entry.key == value ? null : entry.key)
                        : null,
              ),
          ],
        ),
      ],
    );
  }
}

/// "Hvornår taler du med kunden?": a date picker for `collect_on`, with a clear action.
class DeliveryCollectDateField extends StatelessWidget {
  const DeliveryCollectDateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.lastDate,
    this.enabled = true,
  });

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  /// The event date: there is no point collecting the info after it.
  final DateTime? lastDate;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    final c = DSTheme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var last = lastDate ?? today.add(const Duration(days: 730));
    if (last.isBefore(today)) last = today;
    var initial = value ?? today;
    if (initial.isBefore(today)) initial = today;
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: last,
      locale: const Locale('da'),
      builder:
          (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: ColorScheme.light(
                primary: c.brand.primary,
                onPrimary: c.brand.onPrimary,
                surface: c.bg.surface,
              ),
            ),
            child: child!,
          ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    final text =
        value != null
            ? DateFormat('EEEE d. MMMM', 'da_DK').format(value!)
            : 'Vælg dato';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hvornår taler du med kunden?',
          style: DSTextStyle.labelMd.copyWith(color: c.text.secondary),
        ),
        const SizedBox(height: DSSpacing.s2),
        Row(
          children: [
            Expanded(
              child: DSButton(
                label: text,
                variant: DSButtonVariant.secondary,
                iconLeft: LucideIcons.calendar,
                enabled: enabled,
                onTap: enabled ? () => _pick(context) : null,
              ),
            ),
            if (value != null && enabled) ...[
              const SizedBox(width: DSSpacing.s2),
              DSIconButton(icon: LucideIcons.x, onTap: () => onChanged(null)),
            ],
          ],
        ),
        const SizedBox(height: DSSpacing.s1),
        Text(
          'Vi minder dig om det den dag.',
          style: DSTextStyle.labelMd.copyWith(color: c.text.muted),
        ),
      ],
    );
  }
}
