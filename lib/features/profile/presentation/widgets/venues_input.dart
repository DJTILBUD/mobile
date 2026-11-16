import 'package:flutter/material.dart';

import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/profile/domain/venues.dart';

/// "Erfaring og tidligere spillesteder". Typed text is never lost: it is added on "Færdig" on the
/// keyboard, a comma, "Tilføj" and when the field loses focus. The screen owns [controller] so it
/// can also add what is left in the field when the performer taps Gem.
/// 1:1 MIRROR of web-app `VenuesTagInput.tsx`.
class VenuesInput extends StatefulWidget {
  const VenuesInput({
    super.key,
    required this.venues,
    required this.controller,
    required this.onChanged,
    this.isDj = true,
  });

  final List<String> venues;
  final TextEditingController controller;
  final ValueChanged<List<String>> onChanged;
  final bool isDj;

  @override
  State<VenuesInput> createState() => _VenuesInputState();
}

class _VenuesInputState extends State<VenuesInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _commitAll();
    });
    widget.controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    _focus.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _commit(String text) {
    final next = addVenues(widget.venues, text);
    if (next.length != widget.venues.length) widget.onChanged(next);
  }

  void _commitAll() {
    if (!mounted) return;
    final text = widget.controller.text;
    if (text.trim().isEmpty) return;
    _commit(text);
    widget.controller.clear();
  }

  // A comma (typed or pasted) finishes every name before it; the rest stays in the field.
  void _onChanged(String value) {
    final last = lastVenueSeparator(value);
    if (last < 0) return;
    _commit(value.substring(0, last));
    final rest = value.substring(last + 1).trimLeft();
    widget.controller.value = TextEditingValue(
      text: rest,
      selection: TextSelection.collapsed(offset: rest.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    final text = widget.controller.text;
    final current = text.split(RegExp(r'[,;\n]')).last.trim();
    final remaining = maxVenueLength - current.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DSInput(
                hint: "Fx Hvedholm Slot, Kokkedal Slot",
                controller: widget.controller,
                focusNode: _focus,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.sentences,
                onChanged: _onChanged,
                onSubmitted: (_) => _commitAll(),
              ),
            ),
            const SizedBox(width: DSSpacing.s2),
            DSButton(
              label: 'Tilføj',
              variant: DSButtonVariant.secondary,
              size: DSButtonSize.sm,
              enabled: text.trim().isNotEmpty,
              onTap: _commitAll,
            ),
          ],
        ),
        if (remaining <= 10)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: DSSpacing.s1),
              child: Text(
                remaining < 0
                    ? 'Navnet bliver forkortet til $maxVenueLength tegn'
                    : '$remaining tegn tilbage',
                style: DSTextStyle.labelSm.copyWith(
                  color: remaining < 0 ? c.state.danger : c.state.warning,
                ),
              ),
            ),
          ),
        const SizedBox(height: DSSpacing.s2),
        Text(
          'Skriv et navn og tryk Tilføj. Flere på én gang? Adskil dem med komma.'
          '${widget.isDj ? ' Fx Tivoli, Vega, Distortion.' : ' Fx Copenhagen Jazz Festival, La Fontaine, Distortion.'}',
          style: DSTextStyle.labelSm.copyWith(color: c.text.muted),
        ),
        if (widget.venues.isNotEmpty) ...[
          const SizedBox(height: DSSpacing.s3),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < widget.venues.length; i++)
                DSChip(
                  key: ValueKey('$i-${widget.venues[i]}'),
                  label: widget.venues[i],
                  onDelete:
                      () =>
                          widget.onChanged(List.of(widget.venues)..removeAt(i)),
                ),
            ],
          ),
          const SizedBox(height: DSSpacing.s2),
          Text(
            'Kunden ser dem på dine tilbud under "Erfaring og tidligere spillesteder".',
            style: DSTextStyle.labelSm.copyWith(color: c.text.muted),
          ),
        ],
      ],
    );
  }
}
