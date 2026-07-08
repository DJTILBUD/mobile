import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/error/error_messages.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/payment_info.dart';
import 'package:dj_tilbud_app/features/profile/domain/self_billing_complete.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:dj_tilbud_app/core/utils/unsaved_changes_dialog.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key, required this.role});

  final MusicianRole role;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _initialized = false;
  String _initialFingerprint = '';

  PaymentType _paymentType = PaymentType.invoice;
  BusinessEntityType _businessType = BusinessEntityType.private_;
  final _cprCtrl = TextEditingController();
  final _cvrCtrl = TextEditingController();
  final _billingEmailCtrl = TextEditingController();
  final _regNumCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  @override
  void dispose() {
    _cprCtrl.dispose();
    _cvrCtrl.dispose();
    _billingEmailCtrl.dispose();
    _regNumCtrl.dispose();
    _accountCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  bool get _isAps => _businessType == BusinessEntityType.aps;

  String _fingerprint() => [
    _paymentType.name,
    _businessType.name,
    _cprCtrl.text,
    _cvrCtrl.text,
    _billingEmailCtrl.text,
    _regNumCtrl.text,
    _accountCtrl.text,
    _streetCtrl.text,
    _cityCtrl.text,
  ].join('|');

  bool get _isDirty => _initialized && _fingerprint() != _initialFingerprint;

  Future<void> _onPopInvoked(bool didPop, _) async {
    if (didPop) return;
    final confirmed = await showUnsavedChangesDialog(context);
    if (confirmed == true && mounted) Navigator.of(context).pop();
  }

  void _initFromData(PaymentInfo? info) {
    if (_initialized) return;
    _initialized = true;
    if (info != null) {
      _paymentType = info.payment;
      _businessType = info.businessType ?? BusinessEntityType.private_;
      _cprCtrl.text = info.cpr ?? '';
      _cvrCtrl.text = info.cvr ?? '';
      _billingEmailCtrl.text = info.billingEmail ?? '';
      _regNumCtrl.text = info.registrationNumber?.toString() ?? '';
      _accountCtrl.text = info.accountNumber ?? '';
      _streetCtrl.text = info.street ?? '';
      _cityCtrl.text = info.cityPostalCode ?? '';
    }
    _initialFingerprint = _fingerprint();
    for (final c in [
      _cprCtrl,
      _cvrCtrl,
      _billingEmailCtrl,
      _regNumCtrl,
      _accountCtrl,
      _streetCtrl,
      _cityCtrl,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  Future<void> _save() async {
    // The self-billing fields (business type / CVR / CPR / billing email) are
    // always shown, so always run the form validators. The B-income bank fields
    // only attach validators when that branch is rendered.
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final repo = ref.read(profileRepositoryProvider);
      final isDj = widget.role == MusicianRole.dj;
      await repo.upsertPaymentInfo(
        userId: supabase.auth.currentUser!.id,
        isDj: isDj,
        info: PaymentInfo(
          payment: _paymentType,
          // For an ApS the CPR is not relevant; persist null so the self-billing
          // gate (CVR for aps / CPR for private) is consistent.
          cpr:
              _isAps || _cprCtrl.text.trim().isEmpty
                  ? null
                  : _cprCtrl.text.trim(),
          registrationNumber:
              _regNumCtrl.text.trim().isEmpty ? null : _regNumCtrl.text.trim(),
          accountNumber:
              _accountCtrl.text.trim().isEmpty
                  ? null
                  : _accountCtrl.text.trim(),
          street:
              _streetCtrl.text.trim().isEmpty ? null : _streetCtrl.text.trim(),
          cityPostalCode:
              _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
          businessType: _businessType,
          cvr: _cvrCtrl.text.trim().isEmpty ? null : _cvrCtrl.text.trim(),
          billingEmail:
              _billingEmailCtrl.text.trim().isEmpty
                  ? null
                  : _billingEmailCtrl.text.trim(),
        ),
      );
      ref.invalidate(
        isDj ? djPaymentInfoProvider : musicianPaymentInfoProvider,
      );
      if (mounted) {
        DSToast.show(
          context,
          variant: DSToastVariant.success,
          title: 'Betalingsinfo gemt',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted)
        DSToast.show(
          context,
          variant: DSToastVariant.error,
          title: friendlyErrorMessage(
            e,
            fallback: 'Betalingsoplysningerne kunne ikke gemmes. Prøv igen.',
          ),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final isDj = widget.role == MusicianRole.dj;
    final paymentAsync =
        isDj
            ? ref.watch(djPaymentInfoProvider)
            : ref.watch(musicianPaymentInfoProvider);

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        backgroundColor: _c.bg.canvas,
        appBar: AppBar(
          title: Text(
            'Betalingsoplysninger',
            style: DSTextStyle.headingSm.copyWith(color: _c.text.primary),
          ),
          backgroundColor: _c.bg.surface,
          surfaceTintColor: _c.bg.surface,
        ),
        body: paymentAsync.when(
          loading:
              () => Center(
                child: CircularProgressIndicator(color: _c.brand.primary),
              ),
          error: (e, _) => Center(child: Text('Fejl: $e')),
          data: (info) {
            _initFromData(info);

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(DSSpacing.s6),
                children: [
                  // ── Self-billing (faktureringsoplysninger) ──
                  Text(
                    'Faktureringsoplysninger',
                    style: DSTextStyle.labelLg.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _c.text.primary,
                    ),
                  ),
                  const SizedBox(height: DSSpacing.s1),
                  Text(
                    'Ifølge EU-direktivet DAC7 om digitale platforme er DJTILBUD forpligtet til at indsamle og '
                    'indberette disse oplysninger om dig til Skattestyrelsen, så felterne er obligatoriske og skal '
                    'udfyldes, før du kan afgive bud eller tilbud. Alle følsomme oplysninger (CPR, bankoplysninger '
                    'og adresse) krypteres og opbevares sikkert i overensstemmelse med GDPR. Kun DJTILBUD og du har '
                    'adgang til dem.',
                    style: DSTextStyle.bodySm.copyWith(color: _c.text.muted),
                  ),
                  const SizedBox(height: DSSpacing.s3),
                  Text(
                    'Virksomhedstype',
                    style: DSTextStyle.labelMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _c.text.secondary,
                    ),
                  ),
                  const SizedBox(height: DSSpacing.s2),
                  _BusinessTypeSelector(
                    value: _businessType,
                    onChanged: (v) {
                      setState(() => _businessType = v);
                    },
                  ),
                  const SizedBox(height: DSSpacing.s4),
                  DSInput(
                    controller: _cvrCtrl,
                    label:
                        _businessType.requiresCvr
                            ? 'CVR-nummer'
                            : 'CVR-nummer (valgfrit)',
                    hint: '12345678',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (_businessType.requiresCvr &&
                          (v == null || v.trim().isEmpty)) {
                        return 'Påkrævet for virksomhed';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: DSSpacing.s4),
                  DSInput(
                    controller: _billingEmailCtrl,
                    label: 'Fakturerings-email',
                    hint: 'faktura@eksempel.dk',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return 'Påkrævet';
                      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Indtast en gyldig email';
                      }
                      return null;
                    },
                  ),
                  if (!_isAps) ...[
                    const SizedBox(height: DSSpacing.s4),
                    DSInput(
                      controller: _cprCtrl,
                      label: 'CPR-nummer',
                      hint: '123456-7890',
                      validator: (v) {
                        if (_isAps) return null;
                        return (v == null || v.trim().isEmpty)
                            ? 'Påkrævet'
                            : null;
                      },
                    ),
                  ],
                  const SizedBox(height: DSSpacing.s6),

                  Text(
                    'Betalingstype',
                    style: DSTextStyle.labelLg.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _c.text.primary,
                    ),
                  ),
                  const SizedBox(height: DSSpacing.s2),
                  _PaymentTypeSelector(
                    value: _paymentType,
                    onChanged: (v) {
                      setState(() => _paymentType = v);
                    },
                  ),
                  const SizedBox(height: DSSpacing.s6),

                  if (_paymentType == PaymentType.invoice) ...[
                    Container(
                      padding: const EdgeInsets.all(DSSpacing.s4),
                      decoration: BoxDecoration(
                        color: _c.state.info.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(DSRadius.md),
                        border: Border.all(
                          color: _c.state.info.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Faktura information',
                            style: DSTextStyle.labelLg.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _c.text.primary,
                            ),
                          ),
                          const SizedBox(height: DSSpacing.s2),
                          Text(
                            'Send faktura til:',
                            style: DSTextStyle.labelMd.copyWith(
                              color: _c.text.muted,
                            ),
                          ),
                          const SizedBox(height: DSSpacing.s1),
                          Text(
                            'regnskab@djtilbud.dk',
                            style: DSTextStyle.labelLg.copyWith(
                              color: _c.text.primary,
                            ),
                          ),
                          const SizedBox(height: DSSpacing.s2),
                          Text(
                            'Navn: DJTILBUD ApS',
                            style: DSTextStyle.labelMd.copyWith(
                              color: _c.text.secondary,
                            ),
                          ),
                          const SizedBox(height: DSSpacing.s1),
                          Text(
                            'CVR: 46181786',
                            style: DSTextStyle.labelMd.copyWith(
                              color: _c.text.secondary,
                            ),
                          ),
                          const SizedBox(height: DSSpacing.s1),
                          Text(
                            'Betalingsbetingelser: 20 dage',
                            style: DSTextStyle.labelMd.copyWith(
                              color: _c.text.secondary,
                            ),
                          ),
                          const SizedBox(height: DSSpacing.s2),
                          Text(
                            'Husk at skrive Job ID på fakturaen.',
                            style: DSTextStyle.labelMd.copyWith(
                              color: _c.text.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: DSSpacing.s6),

                  // ── Bankoplysninger (always required, regardless of payment type) ──
                  Text(
                    'Bankoplysninger',
                    style: DSTextStyle.labelLg.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _c.text.primary,
                    ),
                  ),
                  const SizedBox(height: DSSpacing.s1),
                  Container(
                    padding: const EdgeInsets.all(DSSpacing.s3),
                    margin: const EdgeInsets.only(bottom: DSSpacing.s4),
                    decoration: BoxDecoration(
                      color: _c.state.warning.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(DSRadius.sm),
                      border: Border.all(
                        color: _c.state.warning.withValues(alpha: 0.50),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.info,
                          size: 16,
                          color: _c.state.warning,
                        ),
                        const SizedBox(width: DSSpacing.s2),
                        Expanded(
                          child: Text(
                            'Vi bruger dine bankoplysninger til fakturering og udbetaling. Kun DJTILBUD og du kan se disse.',
                            style: DSTextStyle.bodySm.copyWith(
                              color: _c.text.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DSInput(
                    controller: _regNumCtrl,
                    label: 'Registreringsnummer',
                    keyboardType: TextInputType.number,
                    validator:
                        (v) =>
                            (v == null || v.trim().isEmpty) ? 'Påkrævet' : null,
                  ),
                  const SizedBox(height: DSSpacing.s4),
                  DSInput(
                    controller: _accountCtrl,
                    label: 'Kontonummer',
                    validator:
                        (v) =>
                            (v == null || v.trim().isEmpty) ? 'Påkrævet' : null,
                  ),
                  const SizedBox(height: DSSpacing.s4),
                  DSInput(
                    controller: _streetCtrl,
                    label: 'Adresse',
                    validator:
                        (v) =>
                            (v == null || v.trim().isEmpty) ? 'Påkrævet' : null,
                  ),
                  const SizedBox(height: DSSpacing.s4),
                  DSInput(
                    controller: _cityCtrl,
                    label: 'Postnummer & by',
                    validator:
                        (v) =>
                            (v == null || v.trim().isEmpty) ? 'Påkrævet' : null,
                  ),

                  const SizedBox(height: DSSpacing.s8),
                  DSButton(
                    label: 'Gem',
                    size: DSButtonSize.lg,
                    expand: true,
                    isLoading: _saving,
                    onTap: _saving ? null : _save,
                  ),
                  const SizedBox(height: DSSpacing.s8),
                ],
              ),
            );
          },
        ),
      ), // PopScope
    );
  }
}

class _PaymentTypeSelector extends StatelessWidget {
  const _PaymentTypeSelector({required this.value, required this.onChanged});

  final PaymentType value;
  final ValueChanged<PaymentType> onChanged;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return Row(
      children: [
        Expanded(
          child: _TypeCard(
            label: 'Faktura',
            subtitle: 'Du sender faktura',
            selected: value == PaymentType.invoice,
            onTap: () => onChanged(PaymentType.invoice),
          ),
        ),
        const SizedBox(width: DSSpacing.s3),
        Expanded(
          child: _TypeCard(
            label: 'B-indkomst',
            subtitle: 'Løn via b-honorar',
            selected: value == PaymentType.bIncome,
            onTap: () => onChanged(PaymentType.bIncome),
          ),
        ),
      ],
    );
  }
}

class _BusinessTypeSelector extends StatelessWidget {
  const _BusinessTypeSelector({required this.value, required this.onChanged});

  final BusinessEntityType value;
  final ValueChanged<BusinessEntityType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TypeCard(
          label: 'Privat',
          subtitle: 'Privatperson · kun CPR',
          selected: value == BusinessEntityType.private_,
          onTap: () => onChanged(BusinessEntityType.private_),
        ),
        const SizedBox(height: DSSpacing.s3),
        _TypeCard(
          label: 'Enkeltmandsvirksomhed',
          subtitle: 'CVR + CPR',
          selected: value == BusinessEntityType.soleTrader,
          onTap: () => onChanged(BusinessEntityType.soleTrader),
        ),
        const SizedBox(height: DSSpacing.s3),
        _TypeCard(
          label: 'ApS',
          subtitle: 'Selskab · kun CVR',
          selected: value == BusinessEntityType.aps,
          onTap: () => onChanged(BusinessEntityType.aps),
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(DSSpacing.s4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DSRadius.md),
          border: Border.all(
            color: selected ? _c.brand.primary : _c.border.subtle,
            width: selected ? 2 : 1,
          ),
          color:
              selected
                  ? _c.brand.primary.withValues(alpha: 0.08)
                  : _c.bg.surface,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: DSTextStyle.labelLg.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? _c.brand.primary : _c.text.secondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: DSTextStyle.bodySm.copyWith(
                fontSize: 11,
                color: selected ? _c.text.primary : _c.text.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
