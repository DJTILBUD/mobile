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
    this.textCapitalization,
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

  /// Auto-capitalisation. Leave null to get the sensible default: sentences
  /// (capital first letter, and after `.` / `!` / `?`) for ordinary text, and
  /// none where a capital would be wrong (passwords, email/url/phone/number
  /// keyboards). Pass explicitly to override, e.g. [TextCapitalization.words]
  /// for a name field.
  final TextCapitalization? textCapitalization;

  /// Keyboards where the first character must NOT be auto-capitalised.
  /// Compared by `index` so `numberWithOptions(...)` variants match too.
  static final _noAutoCapitalKeyboards = <int>{
    TextInputType.emailAddress.index,
    TextInputType.url.index,
    TextInputType.phone.index,
    TextInputType.number.index,
    TextInputType.datetime.index,
    TextInputType.visiblePassword.index,
  };

  TextCapitalization get _effectiveCapitalization {
    if (textCapitalization != null) return textCapitalization!;
    if (obscureText) return TextCapitalization.none;
    if (keyboardType != null &&
        _noAutoCapitalKeyboards.contains(keyboardType!.index)) {
      return TextCapitalization.none;
    }
    return TextCapitalization.sentences;
  }

  /// How much room to keep below the caret when the framework scrolls the focused field into
  /// view (`TextField.scrollPadding`, default `EdgeInsets.all(20)`).
  ///
  /// ⚠️ WHY THIS IS NOT THE DEFAULT 20 FOR A TEXTAREA. The framework scrolls only far enough to
  /// reveal the CARET plus this padding. On a tall field that is the first line, so a `minLines: 8`
  /// box (~200px, e.g. "Salgstale" on the quote form) came to rest with ~50px of itself peeking
  /// above the keyboard: the DJ wrote a 450-character sales pitch through a one-line slot at the
  /// very bottom edge of the screen. Reserving roughly the field's own height below the caret
  /// lifts the whole box clear of the keyboard instead. `ensureVisible` clamps to the scroll
  /// extent, so asking for more room than exists simply parks the field at the top of the
  /// viewport — it can never scroll the caret out of sight.
  ///
  /// Single-line fields keep the framework default: they already fit, and lifting them would just
  /// leave a dead gap.
  EdgeInsets get _scrollPadding {
    if (maxLines <= 1) return const EdgeInsets.all(20);
    // ~22 logical px per line at fontSize 14, capped so a maxLines-15 field does not demand more
    // room than any phone has above the keyboard.
    final lines = (minLines ?? maxLines).clamp(1, 8);
    return EdgeInsets.only(left: 20, top: 20, right: 20, bottom: 20 + lines * 22.0);
  }

  BorderRadius get _radius =>
      maxLines > 1
          ? BorderRadius.circular(DSRadius.md)
          : BorderRadius.circular(DSRadius.pill);

  OutlineInputBorder _border({Color? color, double width = 1}) =>
      OutlineInputBorder(
        borderRadius: _radius,
        borderSide:
            color != null
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
      DSInputState.normal => c.border.subtle,
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

    final suffixIcon =
        isLoading
            ? Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.brand.primary,
                ),
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
          textCapitalization: _effectiveCapitalization,
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          maxLength: showCounter ? maxLength : null,
          maxLines: maxLines,
          minLines: minLines,
          scrollPadding: _scrollPadding,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          style: TextStyle(
            fontSize: 14,
            color: enabled ? c.text.primary : c.text.muted,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: c.text.muted, fontSize: 14),
            suffixText: suffixText,
            suffixStyle: TextStyle(color: c.text.muted, fontSize: 14),
            // No errorText here — we render it ourselves below
            counterText: '', // hide built-in counter
            filled: true,
            fillColor: enabled ? c.bg.inputBg : c.border.subtle,
            focusColor: Colors.transparent,
            prefixIcon:
                iconLeft != null
                    ? Icon(iconLeft, color: iconColor, size: 20)
                    : null,
            suffixIcon: suffixIcon,
            contentPadding:
                maxLines > 1
                    ? const EdgeInsets.symmetric(
                      horizontal: DSSpacing.s4,
                      vertical: DSSpacing.s3,
                    )
                    : const EdgeInsets.symmetric(
                      horizontal: DSSpacing.s4,
                      vertical: 0,
                    ),
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
