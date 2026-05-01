import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';

/// Bottom sheet that mirrors the web app's CustomerDetailsModal.
/// Lets the musician choose between:
///   1. "Jeg har snakket med kunden" — marks them as contacted immediately
///   2. "Jeg har aftalt at snakke med kunden senere" — picks a future date
///
/// Callbacks return `true` on success so the caller can update local state.
class ContactCustomerSheet extends StatefulWidget {
  const ContactCustomerSheet({
    super.key,
    required this.onContacted,
    required this.onPlanned,
    this.existingPlannedDate,
  });

  /// Called when the user confirms "I've already spoken with the customer".
  final Future<bool> Function() onContacted;

  /// Called with an ISO date string (YYYY-MM-DD) when the user confirms a
  /// planned future contact date.
  final Future<bool> Function(String date) onPlanned;

  /// Pre-selects the planned mode and pre-fills the date if one is already set.
  final DateTime? existingPlannedDate;

  @override
  State<ContactCustomerSheet> createState() => _ContactCustomerSheetState();
}

class _ContactCustomerSheetState extends State<ContactCustomerSheet> {
  DSColors get _c => DSTheme.of(context);
  _Mode _mode = _Mode.contacted;
  DateTime? _plannedDate;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingPlannedDate != null) {
      _mode = _Mode.planned;
      _plannedDate = widget.existingPlannedDate;
    }
  }

  String _formatDate(DateTime d) =>
      DateFormat('d. MMMM yyyy', 'da_DK').format(d);

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _plannedDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      locale: const Locale('da'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: _c.brand.primary,
            onPrimary: _c.brand.onPrimary,
            surface: _c.bg.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _plannedDate = picked);
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    bool success;
    if (_mode == _Mode.contacted) {
      success = await widget.onContacted();
    } else {
      if (_plannedDate == null) {
        setState(() => _loading = false);
        return;
      }
      final dateStr = DateFormat('yyyy-MM-dd').format(_plannedDate!);
      success = await widget.onPlanned(dateStr);
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (success) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    final canConfirm = _mode == _Mode.contacted || _plannedDate != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            DSSpacing.s4, DSSpacing.s4, DSSpacing.s4, DSSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle ──────────────────────────────────────────────────────
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _c.border.subtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: DSSpacing.s4),

            // ── Title ────────────────────────────────────────────────────────
            Text(
              'Kundekontakt',
              style: DSTextStyle.headingSm.copyWith(color: _c.text.primary),
            ),
            const SizedBox(height: DSSpacing.s4),

            // ── Option 1: Already spoken ─────────────────────────────────────
            _OptionTile(
              selected: _mode == _Mode.contacted,
              icon: LucideIcons.phoneCall,
              label: 'Jeg har snakket med kunden',
              onTap: () => setState(() => _mode = _Mode.contacted),
            ),
            const SizedBox(height: DSSpacing.s2),

            // ── Option 2: Planned ─────────────────────────────────────────────
            _OptionTile(
              selected: _mode == _Mode.planned,
              icon: LucideIcons.calendarClock,
              label: 'Jeg har aftalt at snakke med kunden senere',
              onTap: () => setState(() => _mode = _Mode.planned),
            ),

            // ── Date picker (visible in planned mode) ────────────────────────
            if (_mode == _Mode.planned) ...[
              const SizedBox(height: DSSpacing.s4),
              Text(
                'Hvornår taler I sammen?',
                style: DSTextStyle.labelMd.copyWith(
                  color: _c.text.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: DSSpacing.s2),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: DSSpacing.s4,
                    vertical: DSSpacing.s3,
                  ),
                  decoration: BoxDecoration(
                    color: _c.bg.inputBg,
                    borderRadius: BorderRadius.circular(DSRadius.md),
                    border: Border.all(
                      color: _plannedDate != null
                          ? _c.brand.accent
                          : _c.border.subtle,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.calendar,
                          size: 18, color: _c.text.secondary),
                      const SizedBox(width: DSSpacing.s2),
                      Text(
                        _plannedDate != null
                            ? _formatDate(_plannedDate!)
                            : 'Vælg dato',
                        style: DSTextStyle.bodyMd.copyWith(
                          color: _plannedDate != null
                              ? _c.text.primary
                              : _c.text.muted,
                        ),
                      ),
                      const Spacer(),
                      Icon(LucideIcons.chevronDown,
                          size: 16, color: _c.text.muted),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: DSSpacing.s6),

            // ── Confirm button ───────────────────────────────────────────────
            DSButton(
              label: _mode == _Mode.contacted
                  ? 'Bekræft kontakt'
                  : 'Gem planlagt dato',
              variant: DSButtonVariant.primary,
              expand: true,
              isLoading: _loading,
              onTap: (canConfirm && !_loading) ? _confirm : null,
            ),
          ],
        ),
      ),
    );
  }
}

enum _Mode { contacted, planned }

// ── Option tile ──────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(DSSpacing.s3),
        decoration: BoxDecoration(
          color: selected
              ? _c.brand.primary.withValues(alpha: 0.12)
              : _c.bg.surface,
          borderRadius: BorderRadius.circular(DSRadius.md),
          border: Border.all(
            color: selected ? _c.brand.primary : _c.border.subtle,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? _c.brand.primaryActive : _c.text.secondary,
            ),
            const SizedBox(width: DSSpacing.s3),
            Expanded(
              child: Text(
                label,
                style: DSTextStyle.bodyMd.copyWith(
                  color: selected ? _c.brand.primaryActive : _c.text.primary,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? _c.brand.primary : _c.border.subtle,
                  width: selected ? 5 : 1.5,
                ),
                color: selected ? _c.brand.primary : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
