import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/payment_info.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _c = lightColors;

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

  PaymentType _paymentType = PaymentType.invoice;
  final _cprCtrl = TextEditingController();
  final _regNumCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  @override
  void dispose() {
    _cprCtrl.dispose();
    _regNumCtrl.dispose();
    _accountCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  void _initFromData(PaymentInfo? info) {
    if (_initialized) return;
    _initialized = true;
    if (info == null) return;
    _paymentType = info.payment;
    _cprCtrl.text = info.cpr ?? '';
    _regNumCtrl.text = info.registrationNumber?.toString() ?? '';
    _accountCtrl.text = info.accountNumber ?? '';
    _streetCtrl.text = info.street ?? '';
    _cityCtrl.text = info.cityPostalCode ?? '';
  }

  Future<void> _save() async {
    if (_paymentType == PaymentType.bIncome && !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final repo = ref.read(profileRepositoryProvider);
      final isDj = widget.role == MusicianRole.dj;
      await repo.upsertPaymentInfo(
        userId: supabase.auth.currentUser!.id,
        isDj: isDj,
        info: PaymentInfo(
          payment: _paymentType,
          cpr: _cprCtrl.text.trim().isEmpty ? null : _cprCtrl.text.trim(),
          registrationNumber: int.tryParse(_regNumCtrl.text.trim()),
          accountNumber: _accountCtrl.text.trim().isEmpty ? null : _accountCtrl.text.trim(),
          street: _streetCtrl.text.trim().isEmpty ? null : _streetCtrl.text.trim(),
          cityPostalCode: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        ),
      );
      ref.invalidate(isDj ? djPaymentInfoProvider : musicianPaymentInfoProvider);
      if (mounted) {
        DSToast.show(context, variant: DSToastVariant.success, title: 'Betalingsinfo gemt');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) DSToast.show(context, variant: DSToastVariant.error, title: 'Fejl: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDj = widget.role == MusicianRole.dj;
    final paymentAsync = isDj ? ref.watch(djPaymentInfoProvider) : ref.watch(musicianPaymentInfoProvider);

    return Scaffold(
      backgroundColor: _c.bg.canvas,
      appBar: AppBar(
        title: Text('Betalingsoplysninger', style: DSTextStyle.headingSm.copyWith(color: _c.text.primary)),
        backgroundColor: _c.bg.surface,
        surfaceTintColor: _c.bg.surface,
      ),
      body: paymentAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: _c.brand.primary)),
        error: (e, _) => Center(child: Text('Fejl: $e')),
        data: (info) {
          _initFromData(info);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(DSSpacing.s6),
              children: [
                Text('Betalingstype', style: DSTextStyle.labelLg.copyWith(fontWeight: FontWeight.w600, color: _c.text.primary)),
                const SizedBox(height: DSSpacing.s2),
                _PaymentTypeSelector(
                  value: _paymentType,
                  onChanged: (v) => setState(() => _paymentType = v),
                ),
                const SizedBox(height: DSSpacing.s6),

                if (_paymentType == PaymentType.invoice) ...[
                  Container(
                    padding: const EdgeInsets.all(DSSpacing.s4),
                    decoration: BoxDecoration(
                      color: _c.state.info.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(DSRadius.md),
                      border: Border.all(color: _c.state.info.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Faktura information', style: DSTextStyle.labelLg.copyWith(fontWeight: FontWeight.w600, color: _c.text.primary)),
                        const SizedBox(height: DSSpacing.s2),
                        Text('Send faktura til:', style: DSTextStyle.labelMd.copyWith(color: _c.text.muted)),
                        const SizedBox(height: DSSpacing.s1),
                        Text('regnskab@djtilbud.dk', style: DSTextStyle.labelLg.copyWith(color: _c.text.primary)),
                        const SizedBox(height: DSSpacing.s2),
                        Text('CVR: 43071963 (LEJSB I/S)', style: DSTextStyle.labelMd.copyWith(color: _c.text.secondary)),
                        const SizedBox(height: DSSpacing.s1),
                        Text('Betalingsbetingelser: 20 dage', style: DSTextStyle.labelMd.copyWith(color: _c.text.secondary)),
                        const SizedBox(height: DSSpacing.s2),
                        Text('Husk at skrive Job ID på fakturaen.', style: DSTextStyle.labelMd.copyWith(color: _c.text.primary)),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(DSSpacing.s3),
                    margin: const EdgeInsets.only(bottom: DSSpacing.s4),
                    decoration: BoxDecoration(
                      color: _c.state.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(DSRadius.sm),
                      border: Border.all(color: _c.state.warning.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.info, size: 16, color: _c.state.warning),
                        const SizedBox(width: DSSpacing.s2),
                        Expanded(
                          child: Text(
                            'For at udbetale løn har vi brug for dit CPR-nummer og bankoplysninger. Kun DJTILBUD og du kan se disse.',
                            style: DSTextStyle.bodySm.copyWith(color: _c.text.secondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DSInput(
                    controller: _cprCtrl,
                    label: 'CPR-nummer',
                    hint: '123456-7890',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Påkrævet' : null,
                  ),
                  const SizedBox(height: DSSpacing.s4),
                  DSInput(
                    controller: _regNumCtrl,
                    label: 'Registreringsnummer',
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Påkrævet' : null,
                  ),
                  const SizedBox(height: DSSpacing.s4),
                  DSInput(
                    controller: _accountCtrl,
                    label: 'Kontonummer',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Påkrævet' : null,
                  ),
                  const SizedBox(height: DSSpacing.s4),
                  DSInput(
                    controller: _streetCtrl,
                    label: 'Adresse',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Påkrævet' : null,
                  ),
                  const SizedBox(height: DSSpacing.s4),
                  DSInput(
                    controller: _cityCtrl,
                    label: 'Postnummer & by',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Påkrævet' : null,
                  ),
                ],

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
    );
  }
}

class _PaymentTypeSelector extends StatelessWidget {
  const _PaymentTypeSelector({required this.value, required this.onChanged});

  final PaymentType value;
  final ValueChanged<PaymentType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _TypeCard(
          label: 'Faktura',
          subtitle: 'Du sender faktura',
          selected: value == PaymentType.invoice,
          onTap: () => onChanged(PaymentType.invoice),
        )),
        const SizedBox(width: DSSpacing.s3),
        Expanded(child: _TypeCard(
          label: 'B-indkomst',
          subtitle: 'Løn via b-honorar',
          selected: value == PaymentType.bIncome,
          onTap: () => onChanged(PaymentType.bIncome),
        )),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.label, required this.subtitle, required this.selected, required this.onTap});

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
          color: selected ? _c.brand.primary.withValues(alpha: 0.08) : _c.bg.surface,
        ),
        child: Column(
          children: [
            Text(label, style: DSTextStyle.labelLg.copyWith(fontWeight: FontWeight.w600, color: selected ? _c.brand.primary : _c.text.secondary)),
            const SizedBox(height: 2),
            Text(subtitle, style: DSTextStyle.bodySm.copyWith(fontSize: 11, color: selected ? _c.text.primary : _c.text.muted)),
          ],
        ),
      ),
    );
  }
}
