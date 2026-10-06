import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/error/error_messages.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/profile/domain/billing_email_validation.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/payment_info.dart';
import 'package:dj_tilbud_app/features/profile/domain/self_billing_complete.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:dj_tilbud_app/features/profile/presentation/widgets/billing_lock_card.dart';
import 'package:dj_tilbud_app/features/profile/presentation/widgets/self_billing_reference_format_card.dart';
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
  // Billing lock (web-app/documentation/billing-lock-plan.md): the server set
  // billing_locked_at, so the form is read-only until support approves a change.
  bool _locked = false;
  String _initialFingerprint = '';

  PaymentType _paymentType = PaymentType.invoice;
  BusinessEntityType _businessType = BusinessEntityType.private_;
  final _cprCtrl = TextEditingController();
  final _cvrCtrl = TextEditingController();
  final _billingEmailCtrl = TextEditingController();
  final _billingEmailSecondaryCtrl = TextEditingController();
  final _regNumCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  @override
  void dispose() {
    _cprCtrl.dispose();
    _cvrCtrl.dispose();
    _billingEmailCtrl.dispose();
    _billingEmailSecondaryCtrl.dispose();
    _regNumCtrl.dispose();
    _accountCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  bool get _isAps => _businessType == BusinessEntityType.aps;
  bool get _isInvoice => _paymentType == PaymentType.invoice;

  // A private person invoicing us: valid (CPR instead of CVR); used to show the
  // explanatory note under the business type.
  bool get _invoiceWithPrivate =>
      _isInvoice && _businessType == BusinessEntityType.private_;

  // Registered company name looked up by the web-app when the CVR was saved. Only
  // meaningful while the field still shows that CVR.
  String? _cvrCompanyName;
  String? _cvrCompanyNameFor;

  String _fingerprint() => [
    _paymentType.name,
    _businessType.name,
    _cprCtrl.text,
    _cvrCtrl.text,
    _billingEmailCtrl.text,
    _billingEmailSecondaryCtrl.text,
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

  // The server data last copied into the form. The providers are app-wide and cached, so the
  // screen re-applies whenever a refresh brings a NEW object (pull-to-refresh, or the refetch on
  // open), e.g. after support approved a change request and unlocked the info.
  PaymentInfo? _appliedInfo;
  // True while the form is being filled from server data, so the controller listeners do not call
  // setState during build.
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    // Always fetch fresh on open: an approval in admin must show without restarting the app.
    Future.microtask(() {
      if (mounted) _invalidatePaymentProviders();
    });
  }

  void _invalidatePaymentProviders() {
    ref.invalidate(
      widget.role == MusicianRole.dj
          ? djPaymentInfoProvider
          : musicianPaymentInfoProvider,
    );
    ref.invalidate(billingChangeRequestProvider);
  }

  Future<void> _refresh() async {
    _invalidatePaymentProviders();
    await Future.wait([
      ref.read(
        (widget.role == MusicianRole.dj
                ? djPaymentInfoProvider
                : musicianPaymentInfoProvider)
            .future,
      ),
      ref.read(billingChangeRequestProvider.future),
    ]);
  }

  void _initFromData(PaymentInfo? info) {
    if (_initialized && identical(info, _appliedInfo)) return;
    _appliedInfo = info;
    if (!_initialized) {
      // First load: the text fields are not built yet, so filling them here is safe.
      _initialized = true;
      _applyInfo(info);
      for (final c in [
        _cprCtrl,
        _cvrCtrl,
        _billingEmailCtrl,
        _billingEmailSecondaryCtrl,
        _regNumCtrl,
        _accountCtrl,
        _streetCtrl,
        _cityCtrl,
      ]) {
        c.addListener(() {
          if (!_applying) setState(() {});
        });
      }
      return;
    }
    // A refresh brought new data. This runs during build and the fields already exist, so the
    // refill waits for the frame to finish (changing a field's text mid-build throws).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(info, _appliedInfo)) return;
      setState(() {
        // Unsaved edits win over a refresh: only the lock state follows the server then.
        if (_isDirty) {
          _locked = info?.isLocked ?? false;
        } else {
          _applyInfo(info);
        }
      });
    });
  }

  /// Copies server data into the form and makes it the new "unchanged" baseline.
  void _applyInfo(PaymentInfo? info) {
    _applying = true;
    _locked = info?.isLocked ?? false;
    if (info != null) {
      _paymentType = info.payment;
      _businessType = info.businessType ?? BusinessEntityType.private_;
      _cprCtrl.text = info.cpr ?? '';
      _cvrCtrl.text = info.cvr ?? '';
      _cvrCompanyName = info.cvrCompanyName;
      _cvrCompanyNameFor = info.cvr;
      _billingEmailCtrl.text = info.billingEmail ?? '';
      _billingEmailSecondaryCtrl.text = info.billingEmailSecondary ?? '';
      _regNumCtrl.text = info.registrationNumber?.toString() ?? '';
      _accountCtrl.text = info.accountNumber ?? '';
      _streetCtrl.text = info.street ?? '';
      _cityCtrl.text = info.cityPostalCode ?? '';
    }
    _applying = false;
    _initialFingerprint = _fingerprint();
  }

  /// The form values as the payload the save sends.
  PaymentInfo _formInfo() => PaymentInfo(
    payment: _paymentType,
    // For an ApS the CPR is not relevant; persist null so the self-billing
    // gate (CVR for aps / CPR for private) is consistent.
    cpr: _isAps || _cprCtrl.text.trim().isEmpty ? null : _cprCtrl.text.trim(),
    registrationNumber:
        _regNumCtrl.text.trim().isEmpty ? null : _regNumCtrl.text.trim(),
    accountNumber:
        _accountCtrl.text.trim().isEmpty ? null : _accountCtrl.text.trim(),
    street: _streetCtrl.text.trim().isEmpty ? null : _streetCtrl.text.trim(),
    cityPostalCode:
        _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
    businessType: _businessType,
    // A private person has no CVR: never persist one left over from an earlier
    // business type (mirrors the web forms).
    cvr:
        !_businessType.requiresCvr || _cvrCtrl.text.trim().isEmpty
            ? null
            : _cvrCtrl.text.trim(),
    billingEmail:
        _billingEmailCtrl.text.trim().isEmpty
            ? null
            : _billingEmailCtrl.text.trim(),
    billingEmailSecondary:
        _billingEmailSecondaryCtrl.text.trim().isEmpty
            ? null
            : _billingEmailSecondaryCtrl.text.trim(),
  );

  Future<void> _save() async {
    // The self-billing fields (business type / CVR / CPR / billing email) are
    // always shown, so always run the form validators. The B-income bank fields
    // only attach validators when that branch is rendered.
    if (!_formKey.currentState!.validate()) return;
    // Value-level checks on top (Form.validate skips fields the lazy ListView has
    // unmounted, see CLAUDE.md). A private person may invoice too (CPR, no CVR);
    // a sole trader or an ApS needs the CVR.
    if (_isInvoice &&
        _businessType.requiresCvr &&
        _cvrCtrl.text.trim().isEmpty) {
      DSToast.show(
        context,
        variant: DSToastVariant.error,
        title: 'Udfyld dit CVR-nummer for at kunne fakturere.',
      );
      return;
    }
    // The optional second billing email: checked on the value too, so it cannot
    // be skipped when scrolled off-screen.
    final secondaryError = validateSecondaryBillingEmail(
      _billingEmailSecondaryCtrl.text,
      _billingEmailCtrl.text,
    );
    if (secondaryError != null) {
      DSToast.show(
        context,
        variant: DSToastVariant.error,
        title: secondaryError,
      );
      return;
    }
    // The save that makes the info complete locks it server-side. Make that an
    // explicit decision; an incomplete save goes through without asking.
    final info = _formInfo();
    if (isPaymentInfoComplete(info.toReadinessInfo())) {
      final confirmed = await showDSConfirm(
        context,
        title: 'Lås dine betalingsoplysninger?',
        message:
            'Tjek at alt er korrekt, især reg.- og kontonummer. Når du bekræfter, bliver '
            'oplysningerne låst, og de kan derefter kun ændres ved at sende en anmodning til support.',
        confirmLabel: 'Bekræft og lås',
      );
      if (!confirmed || !mounted) return;
    }
    setState(() => _saving = true);

    try {
      final repo = ref.read(profileRepositoryProvider);
      final isDj = widget.role == MusicianRole.dj;
      await repo.upsertPaymentInfo(
        userId: supabase.auth.currentUser!.id,
        isDj: isDj,
        info: info,
      );
      ref.invalidate(
        isDj ? djPaymentInfoProvider : musicianPaymentInfoProvider,
      );
      ref.invalidate(billingChangeRequestProvider);
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
              child: RefreshIndicator(
                color: _c.brand.primary,
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(DSSpacing.s6),
                  children: [
                    BillingLockCard(lockedAt: info?.billingLockedAt),
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
                    AbsorbPointer(
                      absorbing: _locked,
                      child: _BusinessTypeSelector(
                        value: _businessType,
                        onChanged: (v) {
                          setState(() => _businessType = v);
                        },
                      ),
                    ),
                    if (_invoiceWithPrivate) ...[
                      const SizedBox(height: DSSpacing.s3),
                      Text(
                        'Du kan godt få betaling via faktura som privatperson. Du skal ikke bruge '
                        'et CVR-nummer: vi bruger dit CPR-nummer, som du udfylder nedenfor.',
                        style: DSTextStyle.bodySm.copyWith(
                          color: _c.text.muted,
                        ),
                      ),
                    ],
                    // A private person has no CVR, so the field is not shown at all for
                    // that type (mirrors the web forms).
                    if (_businessType.requiresCvr) ...[
                      const SizedBox(height: DSSpacing.s4),
                      DSInput(
                        enabled: !_locked,
                        controller: _cvrCtrl,
                        label: 'CVR-nummer',
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
                    ],
                    if (_cvrCompanyName != null &&
                        _cvrCompanyNameFor != null &&
                        _cvrCtrl.text.trim() == _cvrCompanyNameFor) ...[
                      const SizedBox(height: DSSpacing.s2),
                      Text(
                        'Registreret navn: $_cvrCompanyName',
                        style: DSTextStyle.bodySm.copyWith(
                          color: _c.text.muted,
                        ),
                      ),
                    ],
                    const SizedBox(height: DSSpacing.s4),
                    DSInput(
                      enabled: !_locked,
                      controller: _billingEmailCtrl,
                      label: 'Fakturerings-email',
                      hint: 'faktura@eksempel.dk',
                      keyboardType: TextInputType.emailAddress,
                      validator: validateBillingEmail,
                    ),
                    const SizedBox(height: DSSpacing.s4),
                    DSInput(
                      enabled: !_locked,
                      controller: _billingEmailSecondaryCtrl,
                      label: 'Ekstra fakturerings-email (valgfri)',
                      hint: 'bogholderi@eksempel.dk',
                      helperText: 'Afregningen sendes også til denne adresse.',
                      keyboardType: TextInputType.emailAddress,
                      validator:
                          (v) => validateSecondaryBillingEmail(
                            v,
                            _billingEmailCtrl.text,
                          ),
                    ),
                    if (!_isAps) ...[
                      const SizedBox(height: DSSpacing.s4),
                      DSInput(
                        enabled: !_locked,
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
                    AbsorbPointer(
                      absorbing: _locked,
                      child: _PaymentTypeSelector(
                        value: _paymentType,
                        onChanged: (v) {
                          setState(() => _paymentType = v);
                        },
                      ),
                    ),
                    if (_isInvoice) ...[
                      const SizedBox(height: DSSpacing.s3),
                      Text(
                        // Everyone on Invoice is self-billed, a private person too (since 2026-10-05).
                        'Ved fakturering udsteder DJTILBUD en afregning (selvfakturering) på dine vegne '
                        'jf. handelsbetingelserne, og beløbet overføres til din bankkonto nedenfor. '
                        'Du skal ikke selv sende en faktura.',
                        style: DSTextStyle.bodySm.copyWith(
                          color: _c.text.muted,
                        ),
                      ),
                    ],
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
                            // Danish invoicing requires our postal address on the
                            // performer's invoice to us. Keep in sync with the web
                            // app's InvoiceBillingInfoCard, which shows the same block.
                            Text(
                              'Adresse: Gammel kongevej 140b kl, 1850 Frederiksberg',
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
                      enabled: !_locked,
                      controller: _regNumCtrl,
                      label: 'Registreringsnummer',
                      keyboardType: TextInputType.number,
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Påkrævet'
                                  : null,
                    ),
                    const SizedBox(height: DSSpacing.s4),
                    DSInput(
                      enabled: !_locked,
                      controller: _accountCtrl,
                      label: 'Kontonummer',
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Påkrævet'
                                  : null,
                    ),
                    const SizedBox(height: DSSpacing.s4),
                    DSInput(
                      enabled: !_locked,
                      controller: _streetCtrl,
                      label: 'Adresse',
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Påkrævet'
                                  : null,
                    ),
                    const SizedBox(height: DSSpacing.s4),
                    DSInput(
                      enabled: !_locked,
                      controller: _cityCtrl,
                      label: 'Postnummer & by',
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Påkrævet'
                                  : null,
                    ),

                    if (!_locked) ...[
                      const SizedBox(height: DSSpacing.s6),
                      Text(
                        'Når dine oplysninger er udfyldt og gemt, bliver de låst. '
                        'Derefter kan de kun ændres via en anmodning til support.',
                        style: DSTextStyle.bodySm.copyWith(
                          color: _c.text.muted,
                        ),
                      ),
                      const SizedBox(height: DSSpacing.s4),
                      DSButton(
                        label: 'Gem',
                        size: DSButtonSize.lg,
                        expand: true,
                        isLoading: _saving,
                        onTap: _saving ? null : _save,
                      ),
                    ],
                    // Outside the locked form on purpose: not billing-locked. Only
                    // for a SAVED Invoice setup, so saving the format can never
                    // create a billing row on its own.
                    if (info != null && info.isSelfBilled) ...[
                      const SizedBox(height: DSSpacing.s8),
                      SelfBillingReferenceFormatCard(
                        isDj: isDj,
                        savedFormat: info.referenceFormat,
                      ),
                    ],
                    const SizedBox(height: DSSpacing.s8),
                  ],
                ),
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
        // Always offered: a private person may choose Invoice too (CPR, no CVR).
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
