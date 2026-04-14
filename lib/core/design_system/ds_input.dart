import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dj_tilbud_app/core/design_system/tokens.dart';

enum DSInputState { normal, success, error }

/// Design-system text input — matches web marketplace `Input`.
/// Label is positioned ABOVE the field (never floating inside the border).
/// Pill-shaped, filled with inputBg, no visible border by default.
class DSInput extends StatelessWidget {
  const DSInput({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.state = DSInputState.normal,
    this.iconLeft,
    this.iconRight,
    this.isLoading = false,
    this.showCounter = false,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.controller,
    this.focusNode,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.initialValue,
    this.textInputAction,
    this.inputFormatters,
    this.suffixText,
  });

  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final DSInputState state;
  final IconData? iconLeft;
  final IconData? iconRight;
  final bool isLoading;
  final bool showCounter;
  final int? maxLength;
  final int maxLines;
  final int? minLines;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final String? initialValue;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final String? suffixText;

  BorderRadius get _radius => maxLines > 1
      ? BorderRadius.circular(DSRadius.md)
      : BorderRadius.circular(DSRadius.pill);

  OutlineInputBorder _border({Color? color, double width = 1}) =>
      OutlineInputBorder(
        borderRadius: _radius,
        borderSide: color != null
            ? BorderSide(color: color, width: width)
            : BorderSide.none,
      );

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    final displayHelper = errorText ?? helperText;

    final focusBorderColor = switch (state) {
      DSInputState.success => c.state.success,
      DSInputState.error => c.state.danger,
      DSInputState.normal => c.brand.primary,
    };

    final stateBorderColor = switch (state) {
      DSInputState.success => c.state.success,
      DSInputState.error => c.state.danger,
      DSInputState.normal => null,
    };

    final helperColor = switch (state) {
      DSInputState.success => c.state.success,
      DSInputState.error => c.state.danger,
      DSInputState.normal => c.text.muted,
    };

    final iconColor = switch (state) {
      DSInputState.success => c.state.success,
      DSInputState.error => c.state.danger,
      DSInputState.normal => c.text.muted,
    };

    final suffixIcon = isLoading
        ? Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: c.brand.primary),
            ),
          )
        : iconRight != null
            ? Icon(iconRight, color: iconColor, size: 20)
            : null;

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
          const SizedBox(height: 6), // gap-1.5
        ],

        // The input field itself
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          initialValue: initialValue,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          maxLength: showCounter ? maxLength : null,
          maxLines: maxLines,
          minLines: minLines,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          style: TextStyle(fontSize: 14, color: enabled ? c.text.primary : c.text.muted),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: c.text.muted, fontSize: 14),
            suffixText: suffixText,
            suffixStyle: TextStyle(color: c.text.muted, fontSize: 14),
            // No errorText here — we render it ourselves below
            counterText: '', // hide built-in counter
            filled: true,
            fillColor: enabled ? c.bg.inputBg : c.border.subtle,
            prefixIcon: iconLeft != null
                ? Icon(iconLeft, color: iconColor, size: 20)
                : null,
            suffixIcon: suffixIcon,
            contentPadding: maxLines > 1
                ? const EdgeInsets.symmetric(
                    horizontal: DSSpacing.s4, vertical: DSSpacing.s3)
                : const EdgeInsets.symmetric(
                    horizontal: DSSpacing.s4, vertical: 0),
            // Default: no visible border (web: border-transparent)
            border: _border(),
            enabledBorder: _border(color: stateBorderColor),
            focusedBorder: _border(color: focusBorderColor, width: 2),
            errorBorder: _border(color: c.state.danger, width: 2),
            focusedErrorBorder: _border(color: c.state.danger, width: 2),
            disabledBorder: _border(),
          ),
        ),

        // Helper / error text row below the field
        if (displayHelper != null) ...[
          const SizedBox(height: 4),
          Text(
            displayHelper,
            style: TextStyle(fontSize: 12, color: helperColor),
          ),
        ],
      ],
    );
  }
}
