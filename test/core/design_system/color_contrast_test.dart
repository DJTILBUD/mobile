import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Reported as "yellow/green on yellow/green": pale SunsetOrange `state.warning`
/// was rendered as text/icon colour on its own tint, and lime `brand.primary`
/// was used as text on light surfaces. The yellow stays as a fill; text on it
/// goes through `fg()` / `warningText` (black in light mode).
void main() {
  const white = Color(0xFFFFFFFF);

  group('light theme foreground tokens are readable on white', () {
    test('state.warning stays the yellow SunsetOrange fill', () {
      expect(lightColors.state.warning, const Color(0xFFFFD365));
    });

    test('state.warningText is readable on the solid yellow', () {
      expect(
        _contrast(lightColors.state.warningText, lightColors.state.warning),
        greaterThan(4.5),
      );
    });

    test('state.success', () {
      expect(_contrast(lightColors.state.success, white), greaterThan(4.5));
    });

    test('brand.primaryActive (text token for lime)', () {
      expect(
        _contrast(lightColors.brand.primaryActive, white),
        greaterThan(4.5),
      );
    });

    test('warning text on its own 22% tint (status badges, tags)', () {
      final tint = Color.alphaBlend(
        lightColors.state.warning.withValues(alpha: 0.22),
        white,
      );
      final fg = lightColors.fg(lightColors.state.warning);
      expect(fg, lightColors.state.warningText);
      expect(_contrast(fg, tint), greaterThan(4.5));
    });

    test('fg leaves every other colour untouched', () {
      expect(
        lightColors.fg(lightColors.state.success),
        lightColors.state.success,
      );
      expect(
        lightColors.fg(lightColors.state.danger),
        lightColors.state.danger,
      );
      expect(darkColors.fg(darkColors.state.warning), darkColors.state.warning);
    });
  });

  group('dsContentOn', () {
    test('dark text on lime and light fills', () {
      expect(dsContentOn(lightColors.brand.primary), const Color(0xFF141627));
      expect(dsContentOn(lightColors.brand.accent), const Color(0xFF141627));
      expect(dsContentOn(darkColors.state.warning), const Color(0xFF141627));
    });

    test('black text on the yellow warning fill', () {
      expect(dsContentOn(lightColors.state.warning), const Color(0xFF141627));
    });

    test('always picks a readable colour for every status fill', () {
      for (final fill in [
        lightColors.state.warning,
        lightColors.state.success,
        lightColors.state.danger,
        lightColors.brand.primary,
        lightColors.brand.accent,
        lightColors.text.muted,
        darkColors.state.warning,
        darkColors.brand.primary,
      ]) {
        expect(_contrast(dsContentOn(fill), fill), greaterThan(3.0));
      }
    });
  });
}
