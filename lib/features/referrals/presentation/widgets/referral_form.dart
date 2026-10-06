import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/referrals/domain/entities/referral.dart';
import 'package:dj_tilbud_app/features/referrals/domain/phone_countries.dart';
import 'package:dj_tilbud_app/features/referrals/domain/referral_labels.dart';

/// The "hand a job over" form. Mirrors the web form field for field: the customer's name, phone,
/// event date, event type and region are required (the two dropdowns use the customer DJ-form's
/// own lists); everything else is optional context for the team.
/// Validation is done on VALUES (not `Form.validate()`), see mobile CLAUDE.md on lazy ListViews.
class ReferralForm extends StatefulWidget {
  const ReferralForm({
    super.key,
    required this.onSubmit,
    required this.isSubmitting,
  });

  final Future<bool> Function(ReferralInput input) onSubmit;
  final bool isSubmitting;

  @override
  State<ReferralForm> createState() => ReferralFormState();
}

class ReferralFormState extends State<ReferralForm> {
  final _leadName = TextEditingController();
  final _phoneLocal = TextEditingController();
  final _email = TextEditingController();
  final _location = TextEditingController();
  final _guests = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _date;
  String? _eventType;
  String? _region;
  String _phoneCountryCode = defaultPhoneCountryCode;
  ReferralRoleType _roleType = ReferralRoleType.djOnly;

  List<TextEditingController> get _controllers => [
    _leadName,
    _phoneLocal,
    _email,
    _location,
    _guests,
    _notes,
  ];

  PhoneCountry get _selectedPhoneCountry => findPhoneCountry(_phoneCountryCode);

  // Normalizes on every keystroke, exactly like dj-form's controlled input, so a pasted
  // international number (or a typed +/00 prefix) always lands on the right local digits.
  void _onPhoneChanged(String raw) {
    final normalized = normalizePhoneLocal(raw, _selectedPhoneCountry.dialCode);
    if (normalized != raw) {
      _phoneLocal.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }
    setState(() {});
  }

  void _onPhoneCountryChanged(String? code) {
    if (code == null) return;
    final normalized = normalizePhoneLocal(
      _phoneLocal.text,
      findPhoneCountry(code).dialCode,
    );
    setState(() {
      _phoneCountryCode = code;
      _phoneLocal.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canSubmit =>
      referralInputIsComplete(
        leadName: _leadName.text,
        phoneLocal: _phoneLocal.text,
        date: _date,
        eventType: _eventType,
        region: _region,
      ) &&
      !widget.isSubmitting;

  void _reset() {
    for (final c in _controllers) {
      c.clear();
    }
    setState(() {
      _date = null;
      _eventType = null;
      _region = null;
      _phoneCountryCode = defaultPhoneCountryCode;
      _roleType = ReferralRoleType.djOnly;
    });
  }

  Future<void> _pickDate() async {
    final c = DSTheme.of(context);
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
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
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final ok = await widget.onSubmit(
      ReferralInput(
        leadName: _leadName.text,
        date: _date!,
        eventType: _eventType!,
        region: _region!,
        email: _email.text,
        phoneNumber: formatE164Phone(_phoneCountryCode, _phoneLocal.text),
        location: _location.text,
        guestsAmount: int.tryParse(_guests.text.trim()),
        roleType: _roleType,
        notes: _notes.text,
      ),
    );
    if (ok && mounted) _reset();
  }

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    void refresh(String _) => setState(() {});

    return DSSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Kundens oplysninger',
            style: DSTextStyle.headingSm.copyWith(color: c.text.primary),
          ),
          const SizedBox(height: DSSpacing.s3),
          DSInput(
            label: 'Kundens navn',
            hint: 'Fornavn og efternavn',
            controller: _leadName,
            textCapitalization: TextCapitalization.words,
            onChanged: refresh,
          ),
          const SizedBox(height: DSSpacing.s3),
          Text(
            'Kundens telefonnummer',
            style: DSTextStyle.labelMd.copyWith(
              fontWeight: FontWeight.w500,
              color: c.text.primary,
            ),
          ),
          const SizedBox(height: DSSpacing.s2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 118,
                child: DSDropdown<String>(
                  value: _phoneCountryCode,
                  items:
                      phoneCountries
                          .map(
                            (country) => DSDropdownItem(
                              value: country.code,
                              label: '${country.flag} +${country.dialCode}',
                            ),
                          )
                          .toList(),
                  onChanged: _onPhoneCountryChanged,
                ),
              ),
              const SizedBox(width: DSSpacing.s2),
              Expanded(
                child: DSInput(
                  hint: 'Skriv kundens tlf. nummer',
                  controller: _phoneLocal,
                  keyboardType: TextInputType.phone,
                  onChanged: _onPhoneChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.s3),
          DSInput(
            label: 'Kundens email',
            hint: 'kunde@email.dk',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: DSSpacing.s3),
          GestureDetector(
            onTap: widget.isSubmitting ? null : _pickDate,
            child: AbsorbPointer(
              child: DSInput(
                key: ValueKey(_date),
                label: 'Dato for arrangementet',
                hint: 'Vælg dato',
                readOnly: true,
                initialValue: _date == null ? '' : formatReferralDate(_date!),
                iconRight: LucideIcons.calendar,
              ),
            ),
          ),
          const SizedBox(height: DSSpacing.s3),
          DSDropdown<String>(
            label: 'Type af arrangement',
            hint: 'Vælg type',
            value: _eventType,
            items:
                referralEventTypes
                    .map((t) => DSDropdownItem(value: t, label: t))
                    .toList(),
            onChanged: (v) => setState(() => _eventType = v),
          ),
          const SizedBox(height: DSSpacing.s3),
          DSDropdown<String>(
            label: 'Region',
            hint: 'Vælg region',
            value: _region,
            items:
                referralRegions
                    .map((r) => DSDropdownItem(value: r, label: r))
                    .toList(),
            onChanged: (v) => setState(() => _region = v),
          ),
          const SizedBox(height: DSSpacing.s3),
          DSInput(
            label: 'Hvor holdes festen?',
            hint: 'Fx Nybro Kro',
            helperText:
                'Andre skriver fx: "I min have på Parkvej" · "Nybro Kro" · "Gammel Kongevej 140b"',
            controller: _location,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: DSSpacing.s3),
          DSInput(
            label: 'Antal gæster',
            hint: '80',
            controller: _guests,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: DSSpacing.s3),
          DSDropdown<ReferralRoleType>(
            label: 'Hvad søger kunden?',
            value: _roleType,
            items:
                ReferralRoleType.values
                    .map(
                      (t) => DSDropdownItem(value: t, label: roleTypeLabel(t)),
                    )
                    .toList(),
            onChanged:
                (v) => setState(() => _roleType = v ?? ReferralRoleType.djOnly),
          ),
          const SizedBox(height: DSSpacing.s3),
          DSInput(
            label: 'Noget vi skal vide?',
            hint: 'Fx hvad kunden har fortalt om musik, tidspunkt eller budget',
            controller: _notes,
            minLines: 3,
            maxLines: 6,
          ),
          const SizedBox(height: DSSpacing.s4),
          DSButton(
            label: 'Giv jobbet videre',
            size: DSButtonSize.lg,
            expand: true,
            isLoading: widget.isSubmitting,
            enabled: _canSubmit,
            onTap: _canSubmit ? _submit : null,
          ),
        ],
      ),
    );
  }
}
