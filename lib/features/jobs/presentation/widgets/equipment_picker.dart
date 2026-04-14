import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/utils/equipment_description.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _c = lightColors;

/// Visual card-grid equipment picker — matches the web app's QuoteForm UI.
///
/// Calls [onChanged] whenever the selection or speaker counts change.
class EquipmentPicker extends StatelessWidget {
  const EquipmentPicker({
    super.key,
    required this.selectedEquipment,
    required this.topSpeakerCount,
    required this.bottomSpeakerCount,
    required this.noEquipmentSelected,
    required this.onChanged,
    required this.onNoEquipmentChanged,
  });

  final List<String> selectedEquipment;
  final int topSpeakerCount;
  final int bottomSpeakerCount;
  /// True when the user explicitly checked "Jeg medbringer ikke udstyr".
  final bool noEquipmentSelected;
  final void Function(List<String> selected, int top, int bund) onChanged;
  final ValueChanged<bool> onNoEquipmentChanged;

  void _toggle(String label) {
    final next = List<String>.from(selectedEquipment);
    next.contains(label) ? next.remove(label) : next.add(label);
    onChanged(next, topSpeakerCount, bottomSpeakerCount);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Udstyr',
          style: DSTextStyle.labelLg.copyWith(color: _c.text.primary),
        ),
        const SizedBox(height: DSSpacing.s3),

        // Equipment grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: DSSpacing.s2,
            crossAxisSpacing: DSSpacing.s2,
            childAspectRatio: 2.8,
          ),
          itemCount: equipmentOptions.length,
          itemBuilder: (context, index) {
            final label = equipmentOptions[index];
            final active = selectedEquipment.contains(label);
            return _EquipmentCard(
              label: label,
              active: active,
              onTap: () => _toggle(label),
            );
          },
        ),

        // Speaker count controls (shown when Højtalere is selected)
        if (selectedEquipment.contains('Højtalere')) ...[
          const SizedBox(height: DSSpacing.s3),
          Container(
            padding: const EdgeInsets.all(DSSpacing.s3),
            decoration: BoxDecoration(
              color: _c.brand.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(DSRadius.md),
              border: Border.all(color: _c.brand.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Antal højtalere',
                  style: DSTextStyle.labelMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _c.text.primary,
                  ),
                ),
                const SizedBox(height: DSSpacing.s3),
                Row(
                  children: [
                    Expanded(
                      child: _CounterRow(
                        label: 'Top højtaler',
                        count: topSpeakerCount,
                        onDecrement: topSpeakerCount > 0
                            ? () => onChanged(
                                  selectedEquipment,
                                  topSpeakerCount - 1,
                                  bottomSpeakerCount,
                                )
                            : null,
                        onIncrement: () => onChanged(
                          selectedEquipment,
                          topSpeakerCount + 1,
                          bottomSpeakerCount,
                        ),
                      ),
                    ),
                    const SizedBox(width: DSSpacing.s3),
                    Expanded(
                      child: _CounterRow(
                        label: 'Bund højtaler',
                        count: bottomSpeakerCount,
                        onDecrement: bottomSpeakerCount > 0
                            ? () => onChanged(
                                  selectedEquipment,
                                  topSpeakerCount,
                                  bottomSpeakerCount - 1,
                                )
                            : null,
                        onIncrement: () => onChanged(
                          selectedEquipment,
                          topSpeakerCount,
                          bottomSpeakerCount + 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        // "No equipment" option
        const SizedBox(height: DSSpacing.s3),
        DSCheckbox(
          label: 'Jeg medbringer ikke udstyr',
          value: noEquipmentSelected,
          onChanged: onNoEquipmentChanged,
        ),
      ],
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DSMotion.fast,
        decoration: BoxDecoration(
          color: active ? _c.brand.primary : _c.bg.inputBg,
          borderRadius: BorderRadius.circular(DSRadius.md),
          border: Border.all(
            color: active ? _c.brand.primary : _c.border.subtle,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: DSTextStyle.labelMd.copyWith(
              fontWeight: FontWeight.w600,
              color: active ? _c.brand.onPrimary : _c.text.secondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.label,
    required this.count,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final int count;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: DSTextStyle.bodySm.copyWith(fontSize: 11, color: _c.text.muted),
        ),
        const SizedBox(height: DSSpacing.s1),
        Row(
          children: [
            _CounterButton(
              icon: LucideIcons.minus,
              onTap: onDecrement,
            ),
            const SizedBox(width: DSSpacing.s2),
            Text(
              '$count',
              style: DSTextStyle.headingSm.copyWith(
                fontWeight: FontWeight.w700,
                color: _c.text.primary,
              ),
            ),
            const SizedBox(width: DSSpacing.s2),
            _CounterButton(
              icon: LucideIcons.plus,
              onTap: onIncrement,
            ),
          ],
        ),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled ? _c.bg.surface : _c.bg.inputBg,
          borderRadius: BorderRadius.circular(DSRadius.sm),
          border: Border.all(
            color: enabled ? _c.border.subtle : _c.bg.inputBg,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? _c.text.primary : _c.text.muted,
        ),
      ),
    );
  }
}
