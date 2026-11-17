import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/error/app_exception.dart';
import 'package:dj_tilbud_app/core/error/error_messages.dart';
import 'package:dj_tilbud_app/features/jobs/domain/equipment_delivery.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/equipment_delivery_fields.dart';

/// The logistics form inside "Levering af udstyr". Saves only the changed keys via
/// `PUT /api/deliveries/job/{job_id}` (the route writes only sent keys). Read-only when the
/// delivery is cancelled. Kept alive (`AutomaticKeepAliveClientMixin`) because it sits in the
/// quote detail's lazy ListView: scrolled out of view, its State (and the typed text) would
/// otherwise be disposed. Values are checked directly, never via `Form.validate()`.
// @uxid lib/features/jobs/presentation/widgets/equipment_delivery_form.dart::EquipmentDeliveryForm
class EquipmentDeliveryForm extends ConsumerStatefulWidget {
  const EquipmentDeliveryForm({super.key, required this.delivery});

  final EquipmentDelivery delivery;

  @override
  ConsumerState<EquipmentDeliveryForm> createState() =>
      _EquipmentDeliveryFormState();
}

/// Text fields: wire key -> (label, hint, keyboard).
const _textFields = <String, (String, String?, TextInputType?)>{
  'venue_address': ('Adresse', null, TextInputType.streetAddress),
  'setup_window': ('Tidsrum for opsætning', 'fx 14.00-16.00', null),
  'teardown_window': ('Tidsrum for nedtagning', 'fx 01.00-02.00', null),
  'hard_deadline': ('Hårdt sluttidspunkt', 'Kun hvis stedet har et', null),
  'parking': ('Parkering', 'Hvor kan bilen holde?', null),
  'placement': ('Placering af udstyret', 'Hvor i lokalet?', null),
  'onsite_contact_name': ('Kontaktperson på dagen', null, TextInputType.name),
  'onsite_contact_phone': ('Telefon', null, TextInputType.phone),
  'notes': ('Noter', null, TextInputType.multiline),
};

class _EquipmentDeliveryFormState extends ConsumerState<EquipmentDeliveryForm>
    with AutomaticKeepAliveClientMixin {
  late DeliveryLogistics _saved;
  late final Map<String, TextEditingController> _text;
  late final TextEditingController _guests;
  DeliveryAccess? _access;
  DeliverySetupDay? _setupDay;
  DeliveryTeardownDay? _teardownDay;
  DateTime? _collectOn;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _text = {for (final k in _textFields.keys) k: TextEditingController()};
    _guests = TextEditingController();
    _load(widget.delivery.logistics);
    for (final c in [..._text.values, _guests]) {
      c.addListener(_onChanged);
    }
  }

  void _load(DeliveryLogistics l) {
    _saved = l;
    final json = l.toJson();
    for (final e in _text.entries) {
      e.value.text = (json[e.key] as String?) ?? '';
    }
    _guests.text = l.guestsAmount?.toString() ?? '';
    _access = l.access;
    _setupDay = l.setupDay;
    _teardownDay = l.teardownDay;
    _collectOn = l.collectOn;
  }

  @override
  void didUpdateWidget(EquipmentDeliveryForm old) {
    super.didUpdateWidget(old);
    // A refetch (after our own save, or a reopen) brings the server's values. Adopt them only
    // while nothing is typed, so an in-progress edit is never overwritten.
    if (!identical(old.delivery, widget.delivery) && _changes().isEmpty) {
      _load(widget.delivery.logistics);
    }
  }

  @override
  void dispose() {
    for (final c in [..._text.values, _guests]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onChanged() => setState(() {});

  DeliveryLogistics _current() {
    String? t(String key) => _text[key]!.text;
    return DeliveryLogistics(
      venueAddress: t('venue_address'),
      guestsAmount: int.tryParse(_guests.text.trim()),
      access: _access,
      setupDay: _setupDay,
      setupWindow: t('setup_window'),
      teardownDay: _teardownDay,
      teardownWindow: t('teardown_window'),
      hardDeadline: t('hard_deadline'),
      parking: t('parking'),
      placement: t('placement'),
      onsiteContactName: t('onsite_contact_name'),
      onsiteContactPhone: t('onsite_contact_phone'),
      notes: t('notes'),
      collectOn: _collectOn,
    );
  }

  Map<String, dynamic> _changes() => _current().changesSince(_saved);

  static String? _serverMessage(Object err) {
    if (err is! DatabaseException) return null;
    final m = err.message.trim();
    // 401/500 bodies are English developer text; only the Danish rejections are user-facing.
    if (m.isEmpty || m == 'Unauthorized.' || m == 'Internal Server Error.') {
      return null;
    }
    return m;
  }

  Future<void> _save() async {
    final guestsError = validateDeliveryGuests(_guests.text);
    if (guestsError != null) {
      DSToast.show(context, variant: DSToastVariant.error, title: guestsError);
      return;
    }
    final changes = _changes();
    if (changes.isEmpty) return;
    FocusScope.of(context).unfocus();
    try {
      final updated = await ref
          .read(saveEquipmentDeliveryProvider.notifier)
          .save(widget.delivery.jobId, changes);
      if (!mounted) return;
      setState(() => _saved = updated?.logistics ?? _current());
      DSToast.show(
        context,
        variant: DSToastVariant.success,
        title: 'Oplysningerne er gemt',
      );
    } catch (e) {
      if (!mounted) return;
      DSToast.show(
        context,
        variant: DSToastVariant.error,
        title: _serverMessage(e) ?? friendlyErrorMessage(e),
      );
    }
  }

  Widget _input(String key, {bool enabled = true}) {
    final (label, hint, keyboard) = _textFields[key]!;
    final multiline = key == 'notes';
    return Padding(
      padding: const EdgeInsets.only(bottom: DSSpacing.s3),
      child: DSInput(
        controller: _text[key],
        label: label,
        hint: hint,
        keyboardType: keyboard,
        enabled: enabled,
        maxLength: deliveryTextMaxLength[key],
        minLines: multiline ? 3 : null,
        maxLines: multiline ? 6 : 1,
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final editable = !widget.delivery.isCanceled;
    final saving = ref.watch(saveEquipmentDeliveryProvider) is AsyncLoading;
    final dirty = _changes().isNotEmpty;
    const gap = SizedBox(height: DSSpacing.s3);

    final d = widget.delivery;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DeliveryCollectDateField(
          value: _collectOn,
          lastDate: d.eventDate,
          enabled: editable,
          onChanged: (v) => setState(() => _collectOn = v),
        ),
        _GroupHeader(
          title: 'Skal udfyldes',
          dueDate: editable ? d.dueDate : null,
          done: d.missing.isEmpty,
        ),
        _input('venue_address', enabled: editable),
        Padding(
          padding: const EdgeInsets.only(bottom: DSSpacing.s3),
          child: DSInput(
            controller: _guests,
            label: 'Antal gæster',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            enabled: editable,
          ),
        ),
        DeliveryChoiceField<DeliveryAccess>(
          label: 'Adgang',
          options: deliveryAccessLabels,
          value: _access,
          enabled: editable,
          onChanged: (v) => setState(() => _access = v),
        ),
        gap,
        DeliveryChoiceField<DeliverySetupDay>(
          label: 'Opsætning',
          options: deliverySetupDayLabels,
          value: _setupDay,
          enabled: editable,
          onChanged: (v) => setState(() => _setupDay = v),
        ),
        gap,
        _input('setup_window', enabled: editable),
        DeliveryChoiceField<DeliveryTeardownDay>(
          label: 'Nedtagning',
          options: deliveryTeardownDayLabels,
          value: _teardownDay,
          enabled: editable,
          onChanged: (v) => setState(() => _teardownDay = v),
        ),
        gap,
        _input('teardown_window', enabled: editable),
        _input('parking', enabled: editable),
        _input('onsite_contact_name', enabled: editable),
        _input('onsite_contact_phone', enabled: editable),
        const _GroupHeader(title: 'Valgfrit'),
        _input('placement', enabled: editable),
        _input('hard_deadline', enabled: editable),
        _input('notes', enabled: editable),
        if (editable)
          DSButton(
            label: 'Gem',
            expand: true,
            isLoading: saving,
            enabled: dirty && !saving,
            onTap: dirty && !saving ? _save : null,
          ),
      ],
    );
  }
}

/// A field group's heading: its name, and the deadline (or a check once the saved data is complete).
// @uxid lib/features/jobs/presentation/widgets/equipment_delivery_form.dart::_GroupHeader
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title, this.dueDate, this.done = false});

  final String title;
  final DateTime? dueDate;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: DSSpacing.s4, bottom: DSSpacing.s3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: DSTextStyle.labelLg.copyWith(
                fontWeight: FontWeight.w700,
                color: c.text.primary,
              ),
            ),
          ),
          if (done && dueDate != null)
            Icon(LucideIcons.checkCircle, size: 16, color: c.state.success)
          else if (dueDate != null)
            Text(
              'senest ${DateFormat('EEE d. MMM', 'da_DK').format(dueDate!)}',
              style: DSTextStyle.labelMd.copyWith(color: c.text.muted),
            ),
        ],
      ),
    );
  }
}
