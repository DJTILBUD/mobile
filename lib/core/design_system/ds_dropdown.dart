import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/tokens.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// A single item in a [DSDropdown].
class DSDropdownItem<T> {
  const DSDropdownItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// Design-system dropdown — visually consistent with [DSInput].
/// Label is positioned ABOVE the field, pill-shaped, filled with inputBg,
/// no visible border by default, 2px primary ring on focus/open.
class DSDropdown<T> extends StatelessWidget {
  const DSDropdown({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    required this.items,
    required this.value,
    required this.onChanged,
    this.validator,
    this.enabled = true,
  });

  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final List<DSDropdownItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final bool enabled;

  OutlineInputBorder _border({Color? color, double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(DSRadius.pill),
        borderSide: color != null
            ? BorderSide(color: color, width: width)
            : BorderSide.none,
      );

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    final displayHelper = errorText ?? helperText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label — always above, never floating inside the border
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: c.text.primary,
            ),
          ),
          const SizedBox(height: 6),
        ],

        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          onChanged: enabled ? onChanged : null,
          validator: validator,
          icon: Icon(
            LucideIcons.chevronDown,
            color: c.text.muted,
            size: 20,
          ),
          dropdownColor: c.bg.surface,
          hint: hint != null
              ? Text(hint!, style: TextStyle(color: c.text.muted, fontSize: 14))
              : null,
          style: TextStyle(fontSize: 14, color: c.text.primary),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item.value,
                  child: Text(
                    item.label,
                    style: TextStyle(fontSize: 14, color: c.text.primary),
                  ),
                ),
              )
              .toList(),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? c.bg.inputBg : c.border.subtle,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: DSSpacing.s4,
              vertical: 0,
            ),
            border: _border(),
            enabledBorder: _border(),
            focusedBorder: _border(color: c.brand.primary, width: 2),
            errorBorder: _border(color: c.state.danger, width: 2),
            focusedErrorBorder: _border(color: c.state.danger, width: 2),
            disabledBorder: _border(),
          ),
        ),

        // Helper / error text
        if (displayHelper != null) ...[
          const SizedBox(height: 4),
          Text(
            displayHelper,
            style: TextStyle(
              fontSize: 12,
              color: errorText != null ? c.state.danger : c.text.muted,
            ),
          ),
        ],
      ],
    );
  }
}
