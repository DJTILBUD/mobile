import 'package:flutter/material.dart';

/// Design tokens — exact mirror of ../design-system/tokens.ts
/// Role-based naming, light + dark themes.

class DSColors {
  const DSColors._({
    required this.brand,
    required this.bg,
    required this.text,
    required this.border,
    required this.state,
    required this.trust,
    required this.availability,
  });

  final DSBrandColors brand;
  final DSBgColors bg;
  final DSTextColors text;
  final DSBorderColors border;
  final DSStateColors state;
  final DSTrustColors trust;
  final DSAvailabilityColors availability;
}

class DSBrandColors {
  const DSBrandColors({
    required this.primary,
    required this.primaryHover,
    required this.primaryActive,
    required this.onPrimary,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
  });

  final Color primary;
  final Color primaryHover;
  final Color primaryActive;
  final Color onPrimary;
  final Color accent;
  final Color accentSoft;
  final Color onAccent;
}

class DSBgColors {
  const DSBgColors({
    required this.canvas,
    required this.surface,
    required this.elevated,
    required this.inputBg,
    required this.inputBgHover,
  });

  final Color canvas;
  final Color surface;
  final Color elevated;
  final Color inputBg;       // filled input background (#F1F5F9)
  final Color inputBgHover;  // input hovered (#E2E8F0)
}

class DSTextColors {
  const DSTextColors({
    required this.primary,
    required this.secondary,
    required this.muted,
    required this.onDark,
  });

  final Color primary;
  final Color secondary;
  final Color muted;
  final Color onDark;
}

class DSBorderColors {
  const DSBorderColors({
    required this.subtle,
    required this.strong,
  });

  final Color subtle;
  final Color strong;
}

class DSStateColors {
  const DSStateColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
  });

  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
}

class DSTrustColors {
  const DSTrustColors({
    required this.verified,
    required this.verifiedSoft,
  });

  final Color verified;
  final Color verifiedSoft;
}

class DSAvailabilityColors {
  const DSAvailabilityColors({
    required this.available,
    required this.limited,
    required this.unavailable,
  });

  final Color available;
  final Color limited;
  final Color unavailable;
}

class DSRadius {
  const DSRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 9999;
}

class DSShadow {
  const DSShadow._();

  static List<BoxShadow> get sm => [
        BoxShadow(
          offset: const Offset(0, 1),
          blurRadius: 2,
          color: const Color(0xFF0F172A).withValues(alpha: 0.06),
        ),
      ];

  static List<BoxShadow> get md => [
        BoxShadow(
          offset: const Offset(0, 8),
          blurRadius: 24,
          color: const Color(0xFF0F172A).withValues(alpha: 0.10),
        ),
      ];
}

class DSMotion {
  const DSMotion._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 180);
  static const Duration slow = Duration(milliseconds: 260);
  static const Curve ease = Cubic(0.2, 0.8, 0.2, 1);
}

class DSSpacing {
  const DSSpacing._();

  static const double s0 = 0;
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s12 = 48;
}

// ── Light theme tokens ──

const lightColors = DSColors._(
  brand: DSBrandColors(
    primary: Color(0xFFD1F366),       // BoogieBuster — web app primary
    primaryHover: Color(0xFFB8DC4B),  // BoogieBusterDark
    primaryActive: Color(0xFF5A731A), // SpringGreenDark — text on tinted bg
    onPrimary: Color(0xFF141627),     // EerieBlack — dark text on lime button
    accent: Color(0xFF66D0F2),        // BlueSky — secondary interactive
    accentSoft: Color(0xFFD0D4E7),    // ColumbiaBlue — soft accent bg
    onAccent: Color(0xFF141627),      // EerieBlack — text on blue
  ),
  bg: DSBgColors(
    canvas: Color(0xFFF8F8F8),        // web app page background
    surface: Color(0xFFFFFFFF),
    elevated: Color(0xFFFFFFFF),
    inputBg: Color(0xFFF3F3F3),       // OffWhite — filled input bg
    inputBgHover: Color(0xFFDDDDDD),  // border gray — hover
  ),
  text: DSTextColors(
    primary: Color(0xFF141627),       // EerieBlack
    secondary: Color(0xFF626577),     // DarkElectricBlue
    muted: Color(0xFF9A9CAB),         // lighter DarkElectricBlue
    onDark: Color(0xFFFFFFFF),
  ),
  border: DSBorderColors(
    subtle: Color(0xFFDDDDDD),        // BorderLineGray
    strong: Color(0xFF626577),        // DarkElectricBlue
  ),
  state: DSStateColors(
    success: Color(0xFF5A731A),       // SpringGreenDark
    warning: Color(0xFFFFD365),       // SunsetOrange
    danger: Color(0xFFEC502C),        // Flame
    info: Color(0xFF66D0F2),          // BlueSky
  ),
  trust: DSTrustColors(
    verified: Color(0xFF66D0F2),      // BlueSky
    verifiedSoft: Color(0xFFD0D4E7), // ColumbiaBlue soft
  ),
  availability: DSAvailabilityColors(
    available: Color(0xFF5A731A),
    limited: Color(0xFFFFD365),
    unavailable: Color(0xFF9A9CAB),
  ),
);

// ── Dark theme tokens ──

const darkColors = DSColors._(
  brand: DSBrandColors(
    primary: Color(0xFFD1F366),       // BoogieBuster — same on dark
    primaryHover: Color(0xFFB8DC4B),
    primaryActive: Color(0xFFD1F366), // on dark bg, full lime is readable
    onPrimary: Color(0xFF141627),     // EerieBlack
    accent: Color(0xFF66D0F2),        // BlueSky
    accentSoft: Color(0xFF1C1F37),    // YankeesBlue — dark accent bg
    onAccent: Color(0xFF141627),
  ),
  bg: DSBgColors(
    canvas: Color(0xFF111827),
    surface: Color(0xFF1F2937),
    elevated: Color(0xFF374151),
    inputBg: Color(0xFF1F2937),
    inputBgHover: Color(0xFF374151),
  ),
  text: DSTextColors(
    primary: Color(0xFFF9FAFB),
    secondary: Color(0xFFD1D5DB),
    muted: Color(0xFF9CA3AF),
    onDark: Color(0xFFF9FAFB),
  ),
  border: DSBorderColors(
    subtle: Color(0xFF374151),
    strong: Color(0xFF4B5563),
  ),
  state: DSStateColors(
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFEF4444),
    info: Color(0xFF3B82F6),
  ),
  trust: DSTrustColors(
    verified: Color(0xFF2DD4BF),
    verifiedSoft: Color(0xFF134E4A),
  ),
  availability: DSAvailabilityColors(
    available: Color(0xFF22C55E),
    limited: Color(0xFFF59E0B),
    unavailable: Color(0xFF6B7280),
  ),
);

// ── Typography tokens ──

class DSTextStyle {
  const DSTextStyle._();

  // Display — hero headings
  static const TextStyle displayLg = TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.2);
  static const TextStyle displayMd = TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.25);

  // Heading — section and card titles
  static const TextStyle headingLg = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.2, height: 1.3);
  static const TextStyle headingMd = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3);
  static const TextStyle headingSm = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4);

  // Body — primary readable content
  static const TextStyle bodyLg = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
  static const TextStyle bodyMd = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  static const TextStyle bodySm = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.5);

  // Label — form labels, captions, chips
  static const TextStyle labelLg = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4);
  static const TextStyle labelMd = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.4);
  static const TextStyle labelSm = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.4);
}

// ── DSTheme — InheritedWidget for propagating DSColors down the widget tree ──
//
// Wrap a subtree in [DSTheme] to switch between light and dark palettes.
// All DS components call [DSTheme.of(context)]; they fall back to [lightColors]
// when no ancestor [DSTheme] is present (safe default for existing usage).
//
// Example:
//   DSTheme(
//     colors: isDark ? darkColors : lightColors,
//     child: MyScreen(),
//   )

class DSTheme extends InheritedWidget {
  const DSTheme({
    super.key,
    required this.colors,
    required super.child,
  });

  final DSColors colors;

  /// Nearest [DSTheme] palette, or [lightColors] when no ancestor is present.
  static DSColors of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<DSTheme>()
            ?.colors ??
        lightColors;
  }

  @override
  bool updateShouldNotify(DSTheme old) => colors != old.colors;
}
