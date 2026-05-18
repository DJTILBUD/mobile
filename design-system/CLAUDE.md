# Design System

The design system lives in `lib/core/design_system/`. It is the single source of truth for all UI decisions — colors, spacing, typography, motion, and components.

## How to use it

Always import via the barrel file — never import individual component files directly:

```dart
import 'package:dj_tilbud_app/core/design_system/components.dart';
```

This gives you all DS widgets and tokens in one import.

## Tokens — `tokens.dart`

All design decisions are encoded as tokens. Never use raw values (hex colors, magic numbers) in widget code.

| Token class | What it covers |
|---|---|
| `DSColors` | Role-based colors — brand, bg, text, border, state, trust, availability |
| `DSSpacing` | Spacing scale — s0 (0), s1 (4), s2 (8), s3 (12), s4 (16), s6 (24), s8 (32), s12 (48) |
| `DSRadius` | Corner radii — sm (8), md (12), lg (16), pill (9999) |
| `DSShadow` | Elevation shadows — sm, md |
| `DSMotion` | Animation durations (fast 120ms, normal 180ms, slow 260ms) and easing curve |
| `DSTextStyle` | Typography scale — display, heading, body, label (lg/md/sm each) |

**Light and dark themes** are both defined: `lightColors` and `darkColors`. Components read the active palette via `DSTheme.of(context)`.

**Getting colors in a widget:**
```dart
final c = DSTheme.of(context);
// c.brand.primary, c.bg.surface, c.text.secondary, c.state.danger, etc.
```

## Components

| File | Widget |
|---|---|
| `ds_button.dart` | Primary, secondary, ghost, destructive buttons |
| `ds_input.dart` | Text fields with label, hint, validation |
| `ds_chip.dart` | Filter and selection chips |
| `ds_info_chip.dart` | Read-only info display chips |
| `ds_status_badge.dart` | Status indicators (won, lost, pending, etc.) |
| `ds_surface.dart` | Card/surface container with elevation |
| `ds_avatar.dart` | User/DJ avatar with fallback initials |
| `ds_switch.dart` | Toggle switch |
| `ds_checkbox.dart` | Checkbox |
| `ds_radio.dart` | Radio button |
| `ds_dropdown.dart` | Dropdown selector |
| `ds_slider.dart` | Single value slider |
| `ds_range_slider.dart` | Range slider (min/max) |
| `ds_segmented_control.dart` | Segmented control / tab switcher |
| `ds_tab_bar.dart` | Tab bar |
| `ds_navigation_bar.dart` | Bottom navigation bar |
| `ds_toast.dart` | Toast/snackbar notifications |

## Playbook (showcase screen)

`lib/core/design_system/showcase_screen.dart` renders every component in both light and dark mode with all variants. **Before building a new UI element, check the showcase first** — if a DS component covers the use case, use it. If you build something new that should become reusable, add it to the design system and showcase.

## Rules

- Always use DS tokens — never raw hex, magic spacing numbers, or inline font sizes
- Always use DS components — never Flutter's raw `ElevatedButton`, `TextField`, etc. when a DS equivalent exists
- To toggle dark mode, wrap a subtree in `DSTheme(colors: darkColors, child: ...)` — individual components handle the rest
- Icons: use `lucide_icons` package, not Material icons
- Images: use `cached_network_image`, never `Image.network()` directly
- SVGs: use `flutter_svg`
