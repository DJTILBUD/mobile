# Design system playbook

A Flutter mobile app for performing musicians — DJs and instrumentalists — to find and respond to event jobs. Its main areas are browsing jobs and submitting quotes or service offers, then tracking won, pending and expired bids. Around that sit a calendar with availability, chat with customers and admin support, notifications, and AI agent helpers for drafting text and coaching the profile. The app also covers profile and media management, onboarding, payment and self-billing settings, stats, and referrals. A shared design system (the DS* components plus tokens for surfaces, text, brand, state, availability and trust colors, radii, spacing, shadows and motion) gives the screens a consistent card-based, mobile-first UI, and a built-in showcase documents it.

## In one screen

- **Theme lives in:** constants in the code.
- **Tokens:** 59 in 10 group(s), folded from 86 declaration(s).
- **Themes:** light and dark.
- **Spent:** 44 token(s) are used somewhere; 15 are declared and never used.
- **Components:** 113 declared, 19 primitives, 3 with variants (18 variant value(s)).
- **Disagreements:** 84 instance(s) in 4 kind(s). See the last section.

## Where the design is declared

| file | what it declares |
| --- | --- |
| `lib/core/design_system/tokens.dart`:119 | 83 token(s) declared in code |
| `lib/core/theme/app_theme.dart`:9 | 16 token(s) declared in code |

## Palette

Colour is written in hex (41 token(s)). 29 colour token(s) are re-declared for dark mode; 12 keep their light value.

### Surfaces (5)

#### bg

| token | utility name | light | dark | uses | defined at |
| --- | --- | --- | --- | --- | --- |
| `--bg-canvas` |  | `#f8f8f8` | `#111827` | 67 | `lib/core/design_system/tokens.dart`:180 |
| `--bg-elevated` |  | `#ffffff` | `#374151` | 3 | `lib/core/design_system/tokens.dart`:182 |

#### surface

| token | utility name | light | dark | uses | defined at |
| --- | --- | --- | --- | --- | --- |
| `--bg-surface` |  | `#ffffff` | `#1f2937` | 186 | `lib/core/design_system/tokens.dart`:181 |
| `--scheme-on-surface` |  | _none_ | `#f9fafb` | 0 | `lib/core/theme/app_theme.dart`:38 |
| `--scheme-surface` |  | _none_ | `#1f2937` | 0 | `lib/core/theme/app_theme.dart`:37 |

### Text (4)

| token | utility name | light | dark | uses | defined at |
| --- | --- | --- | --- | --- | --- |
| `--text-muted` |  | `#9a9cab` | `#9ca3af` | 293 | `lib/core/design_system/tokens.dart`:189 |
| `--text-on-dark` |  | `#ffffff` | `#f9fafb` | 6 | `lib/core/design_system/tokens.dart`:190 |
| `--text-primary` |  | `#141627` | `#f9fafb` | 328 | `lib/core/design_system/tokens.dart`:187 |
| `--text-secondary` |  | `#626577` | `#d1d5db` | 276 | `lib/core/design_system/tokens.dart`:188 |

### Brand (7)

#### accent

| token | utility name | light | dark | uses | defined at |
| --- | --- | --- | --- | --- | --- |
| `--brand-accent` |  | `#66d0f2` | (same) | 15 | `lib/core/design_system/tokens.dart`:175 |
| `--brand-accent-soft` |  | `#d0d4e7` | `#1c1f37` | 2 | `lib/core/design_system/tokens.dart`:176 |
| `--brand-on-accent` |  | `#141627` | (same) | 2 | `lib/core/design_system/tokens.dart`:177 |

#### primary

| token | utility name | light | dark | uses | defined at |
| --- | --- | --- | --- | --- | --- |
| `--brand-on-primary` |  | `#141627` | (same) | 37 | `lib/core/design_system/tokens.dart`:174 |
| `--brand-primary` |  | `#d1f366` | (same) | 144 | `lib/core/design_system/tokens.dart`:171 |
| `--brand-primary-active` |  | `#5a731a` | `#d1f366` | 101 | `lib/core/design_system/tokens.dart`:173 |
| `--brand-primary-hover` |  | `#b8dc4b` | (same) | 1 | `lib/core/design_system/tokens.dart`:172 |

### Status (4)

| token | utility name | light | dark | uses | defined at |
| --- | --- | --- | --- | --- | --- |
| `--state-danger` |  | `#ec502c` | `#ef4444` | 136 | `lib/core/design_system/tokens.dart`:199 |
| `--state-info` |  | `#66d0f2` | `#3b82f6` | 45 | `lib/core/design_system/tokens.dart`:200 |
| `--state-success` |  | `#5a731a` | `#22c55e` | 78 | `lib/core/design_system/tokens.dart`:197 |
| `--state-warning` |  | `#ffd365` | `#f59e0b` | 88 | `lib/core/design_system/tokens.dart`:198 |

### Controls (border, input, ring) (5)

#### border

| token | utility name | light | dark | uses | defined at |
| --- | --- | --- | --- | --- | --- |
| `--border-strong` |  | `#626577` | `#4b5563` | 10 | `lib/core/design_system/tokens.dart`:194 |
| `--border-subtle` |  | `#dddddd` | `#374151` | 181 | `lib/core/design_system/tokens.dart`:193 |
| `--colors-border-line-gray` |  | `#b1b1b1` | (same) | 0 | `lib/core/theme/app_theme.dart`:16 |

#### input

| token | utility name | light | dark | uses | defined at |
| --- | --- | --- | --- | --- | --- |
| `--bg-input-bg` |  | `#f3f3f3` | `#1f2937` | 50 | `lib/core/design_system/tokens.dart`:183 |
| `--bg-input-bg-hover` |  | `#dddddd` | `#374151` | 1 | `lib/core/design_system/tokens.dart`:184 |

### Elevation (2)

| token | utility name | light | dark | uses | defined at |
| --- | --- | --- | --- | --- | --- |
| `--shadow-md` |  | `0px 8px 24px #0f172a` | (same) | 7 | `lib/core/design_system/tokens.dart`:136 |
| `--shadow-sm` |  | `0px 1px 2px #0f172a` | (same) | 31 | `lib/core/design_system/tokens.dart`:128 |

### Motion (4)

| token | utility name | light | dark | uses | defined at |
| --- | --- | --- | --- | --- | --- |
| `--duration-fast` |  | `120ms` | (same) | 4 | `lib/core/design_system/tokens.dart`:148 |
| `--duration-normal` |  | `180ms` | (same) | 10 | `lib/core/design_system/tokens.dart`:149 |
| `--duration-slow` |  | `260ms` | (same) | 1 | `lib/core/design_system/tokens.dart`:150 |
| `--ease-ease` |  | `cubic-bezier(0.2, 0.8, 0.2, 1)` | (same) | 4 | `lib/core/design_system/tokens.dart`:151 |

### Unclassified (16)

| token | utility name | light | dark | uses | defined at |
| --- | --- | --- | --- | --- | --- |
| `--availability-available` |  | `#5a731a` | `#22c55e` | 1 | `lib/core/design_system/tokens.dart`:207 |
| `--availability-limited` |  | `#ffd365` | `#f59e0b` | 1 | `lib/core/design_system/tokens.dart`:208 |
| `--availability-unavailable` |  | `#9a9cab` | `#6b7280` | 1 | `lib/core/design_system/tokens.dart`:209 |
| `--colors-blue-sky` |  | `#66d0f2` | (same) | 0 | `lib/core/theme/app_theme.dart`:21 |
| `--colors-boogie-buster` |  | `#d1f366` | (same) | 0 | `lib/core/theme/app_theme.dart`:9 |
| `--colors-boogie-buster-dark` |  | `#b8dc4b` | (same) | 0 | `lib/core/theme/app_theme.dart`:10 |
| `--colors-dark-electric-blue` |  | `#626577` | (same) | 0 | `lib/core/theme/app_theme.dart`:15 |
| `--colors-eerie-black` |  | `#141627` | (same) | 0 | `lib/core/theme/app_theme.dart`:13 |
| `--colors-gray` |  | `#808080` | (same) | 0 | `lib/core/theme/app_theme.dart`:17 |
| `--colors-off-white` |  | `#f3f3f3` | (same) | 0 | `lib/core/theme/app_theme.dart`:18 |
| `--colors-peach-red` |  | `#ff8b8b` | (same) | 0 | `lib/core/theme/app_theme.dart`:24 |
| `--colors-spring-green` |  | `#d1f366` | (same) | 0 | `lib/core/theme/app_theme.dart`:23 |
| `--colors-sunset-orange` |  | `#ffd365` | (same) | 0 | `lib/core/theme/app_theme.dart`:22 |
| `--colors-yankees-blue` |  | `#1c1f37` | (same) | 0 | `lib/core/theme/app_theme.dart`:14 |
| `--trust-verified` |  | `#66d0f2` | `#2dd4bf` | 2 | `lib/core/design_system/tokens.dart`:203 |
| `--trust-verified-soft` |  | `#d0d4e7` | `#134e4a` | 2 | `lib/core/design_system/tokens.dart`:204 |

## Scales

### Radius

| step | expression | computed | uses | defined at |
| --- | --- | --- | --- | --- |
| `--radius-sm` | `8px` | 8px | 50 | `lib/core/design_system/tokens.dart`:119 |
| `--radius-md` | `12px` | 12px | 92 | `lib/core/design_system/tokens.dart`:120 |
| `--radius-lg` | `16px` | 16px | 53 | `lib/core/design_system/tokens.dart`:121 |
| `--radius-pill` | `9999px` | 9999px | 50 | `lib/core/design_system/tokens.dart`:122 |

### Spacing

| step | expression | computed | uses | defined at |
| --- | --- | --- | --- | --- |
| `--spacing-s0` | `0px` | 0px | 0 | `lib/core/design_system/tokens.dart`:157 |
| `--spacing-s1` | `4px` | 4px | 119 | `lib/core/design_system/tokens.dart`:158 |
| `--spacing-s2` | `8px` | 8px | 433 | `lib/core/design_system/tokens.dart`:159 |
| `--spacing-s3` | `12px` | 12px | 475 | `lib/core/design_system/tokens.dart`:160 |
| `--spacing-s4` | `16px` | 16px | 494 | `lib/core/design_system/tokens.dart`:161 |
| `--spacing-s6` | `24px` | 24px | 147 | `lib/core/design_system/tokens.dart`:162 |
| `--spacing-s8` | `32px` | 32px | 49 | `lib/core/design_system/tokens.dart`:163 |
| `--spacing-s12` | `48px` | 48px | 1 | `lib/core/design_system/tokens.dart`:164 |

### Typography

| family | declared at |
| --- | --- |
| `'Prompt', sans-serif` | `lib/core/theme/app_theme.dart`:51 |

| step | size | weight | declared at |
| --- | --- | --- | --- |
| `display-lg` | `32px` | 700 | `lib/core/design_system/tokens.dart`:262 |
| `display-md` | `24px` | 700 | `lib/core/design_system/tokens.dart`:268 |
| `heading-lg` | `20px` | 600 | `lib/core/design_system/tokens.dart`:276 |
| `heading-md` | `18px` | 600 | `lib/core/design_system/tokens.dart`:282 |
| `heading-sm` | `16px` | 600 | `lib/core/design_system/tokens.dart`:287 |
| `body-lg` | `16px` | 400 | `lib/core/design_system/tokens.dart`:294 |
| `body-md` | `14px` | 400 | `lib/core/design_system/tokens.dart`:299 |
| `body-sm` | `12px` | 400 | `lib/core/design_system/tokens.dart`:304 |
| `label-lg` | `14px` | 500 | `lib/core/design_system/tokens.dart`:311 |
| `label-md` | `13px` | 500 | `lib/core/design_system/tokens.dart`:316 |
| `label-sm` | `12px` | 500 | `lib/core/design_system/tokens.dart`:321 |

## States the UI actually targets

| state | class occurrences |
| --- | --- |
| `active` | 8 |

## Composition

19 primitive component(s) in 18 file(s) live under `lib/core/design_system` (a `lib/core/design_system` directory of 21 files), and 42 screen file(s) build from them. 94 application component(s) sit on top, of which 53 are rendered in exactly one other file and 5 in none.

| primitive | file | renders | files | screens | variant axes |
| --- | --- | --- | --- | --- | --- |
| DSButton | `lib/core/design_system/ds_button.dart` | 153 | 53 | 30 | 2 |
| DSInput | `lib/core/design_system/ds_input.dart` | 78 | 25 | 17 | 1 |
| DSSurface | `lib/core/design_system/ds_surface.dart` | 44 | 9 | 6 | 0 |
| DSIconButton | `lib/core/design_system/ds_button.dart` | 34 | 13 | 8 | 2 |
| DSStatusBadge | `lib/core/design_system/ds_status_badge.dart` | 27 | 12 | 5 | 0 |
| DSCheckbox | `lib/core/design_system/ds_checkbox.dart` | 15 | 4 | 2 | 0 |
| DSChip | `lib/core/design_system/ds_chip.dart` | 11 | 5 | 4 | 0 |
| DSRadio | `lib/core/design_system/ds_radio.dart` | 10 | 2 | 0 | 0 |
| DSSwitch | `lib/core/design_system/ds_switch.dart` | 9 | 5 | 4 | 0 |
| DSInfoChip | `lib/core/design_system/ds_info_chip.dart` | 8 | 1 | 0 | 0 |
| DSRangeSlider | `lib/core/design_system/ds_range_slider.dart` | 5 | 2 | 2 | 0 |
| DSSlider | `lib/core/design_system/ds_slider.dart` | 4 | 1 | 0 | 0 |
| DSTabBar | `lib/core/design_system/ds_tab_bar.dart` | 4 | 4 | 4 | 0 |
| DSDialog | `lib/core/design_system/ds_dialog.dart` | 2 | 2 | 0 | 0 |
| DSSegmentedControl | `lib/core/design_system/ds_segmented_control.dart` | 2 | 1 | 0 | 0 |
| DesignSystemShowcase | `lib/core/design_system/showcase_screen.dart` | 1 | 1 | 0 | 0 |
| DSAvatar | `lib/core/design_system/ds_avatar.dart` | 1 | 1 | 1 | 0 |
| DSNavigationBar | `lib/core/design_system/ds_navigation_bar.dart` | 1 | 1 | 0 | 0 |
| DSDropdown | `lib/core/design_system/ds_dropdown.dart` | 0 | 0 | 0 | 0 |

Primitives nothing outside their own file renders: DSDropdown.

## Where the app disagrees with itself

### 33 colour tokens share only 12 distinct value(s) in light mode

39 colour token(s) resolve to 18 distinct light value(s). Where two names always carry the same value, a reader cannot tell which one a screen should use:
- #ffffff: --bg-elevated, --bg-surface, --text-on-dark
- #9a9cab: --text-muted, --availability-unavailable
- #141627: --text-primary, --brand-on-accent, --brand-on-primary, --colors-eerie-black
- #626577: --text-secondary, --border-strong, --colors-dark-electric-blue
- #66d0f2: --brand-accent, --state-info, --colors-blue-sky, --trust-verified
- #d0d4e7: --brand-accent-soft, --trust-verified-soft
- #d1f366: --brand-primary, --colors-boogie-buster, --colors-spring-green
- #5a731a: --brand-primary-active, --state-success, --availability-available
- #b8dc4b: --brand-primary-hover, --colors-boogie-buster-dark
- #ffd365: --state-warning, --availability-limited, --colors-sunset-orange
- #dddddd: --border-subtle, --bg-input-bg-hover
- #f3f3f3: --bg-input-bg, --colors-off-white

- `lib/core/design_system/tokens.dart`:182: `--bg-elevated: #ffffff`
- `lib/core/design_system/tokens.dart`:181: `--bg-surface: #ffffff`
- `lib/core/design_system/tokens.dart`:190: `--text-on-dark: #ffffff`
- `lib/core/design_system/tokens.dart`:189: `--text-muted: #9a9cab`
- `lib/core/design_system/tokens.dart`:209: `--availability-unavailable: #9a9cab`
- `lib/core/design_system/tokens.dart`:187: `--text-primary: #141627`

### 1 colour token(s) have no dark value

They keep their light value in dark mode: --colors-border-line-gray.

- `lib/core/theme/app_theme.dart`:16: `--colors-border-line-gray: #b1b1b1`

### 15 token(s) are declared and never used

No utility class and no `var()` reference spends them: --scheme-on-surface, --scheme-surface, --colors-border-line-gray, --spacing-s0, --colors-blue-sky, --colors-boogie-buster-dark, --colors-boogie-buster, --colors-dark-electric-blue, --colors-eerie-black, --colors-gray, --colors-off-white, --colors-peach-red, --colors-spring-green, --colors-sunset-orange, --colors-yankees-blue.

- `lib/core/theme/app_theme.dart`:38: `--scheme-on-surface: #f9fafb`
- `lib/core/theme/app_theme.dart`:37: `--scheme-surface: #1f2937`
- `lib/core/theme/app_theme.dart`:16: `--colors-border-line-gray: #b1b1b1`
- `lib/core/design_system/tokens.dart`:157: `--spacing-s0: 0px`
- `lib/core/theme/app_theme.dart`:21: `--colors-blue-sky: #66d0f2`
- `lib/core/theme/app_theme.dart`:10: `--colors-boogie-buster-dark: #b8dc4b`

### 35 hardcoded colour literal(s) bypass the tokens

Written into a colour property or an arbitrary class value; 11 duplicate a token that already exists.

- `lib/core/design_system/ds_navigation_bar.dart`:188: `color: Color(0xFFE53935),`
- `lib/core/design_system/ds_tab_bar.dart`:169: `color: Color(0xFFE53935),`
- `lib/core/design_system/showcase_screen.dart`:2125: `gradientStart: const Color(0xFF8B5CF6),`
- `lib/core/design_system/showcase_screen.dart`:2126: `gradientEnd: const Color(0xFFEC4899),`
- `lib/core/design_system/showcase_screen.dart`:2142: `gradientStart: const Color(0xFFF59E0B),`
- `lib/core/design_system/showcase_screen.dart`:2143: `gradientEnd: const Color(0xFFF97316),`
- `lib/core/design_system/showcase_screen.dart`:2158: `gradientStart: const Color(0xFF3B82F6),`
- `lib/core/design_system/showcase_screen.dart`:2159: `gradientEnd: const Color(0xFF6366F1),`
- `lib/core/theme/app_theme.dart`:41: `scaffoldBackgroundColor: const Color(0xFF111827),`
- `lib/core/theme/app_theme.dart`:43: `backgroundColor: Color(0xFF1F2937),`

### Every hardcoded colour, by file

| file | literal | duplicates |
| --- | --- | --- |
| `lib/core/design_system/ds_navigation_bar.dart`:188 | `#e53935` |  |
| `lib/core/design_system/ds_tab_bar.dart`:169 | `#e53935` |  |
| `lib/core/design_system/showcase_screen.dart`:2125 | `#8b5cf6` |  |
| `lib/core/design_system/showcase_screen.dart`:2126 | `#ec4899` |  |
| `lib/core/design_system/showcase_screen.dart`:2142 | `#f59e0b` | `--state-warning` |
| `lib/core/design_system/showcase_screen.dart`:2143 | `#f97316` |  |
| `lib/core/design_system/showcase_screen.dart`:2158 | `#3b82f6` | `--state-info` |
| `lib/core/design_system/showcase_screen.dart`:2159 | `#6366f1` |  |
| `lib/core/theme/app_theme.dart`:41 | `#111827` | `--bg-canvas` |
| `lib/core/theme/app_theme.dart`:43 | `#1f2937` | `--bg-surface` |
| `lib/core/theme/app_theme.dart`:44 | `#f9fafb` | `--scheme-on-surface` |
| `lib/core/theme/app_theme.dart`:45 | `#1f2937` | `--bg-surface` |
| `lib/core/widgets/dev_env_banner.dart`:37 | `#ff8c00` |  |
| `lib/core/widgets/dev_env_banner.dart`:38 | `#2563eb` |  |
| `lib/core/widgets/dev_env_banner.dart`:39 | `#dc2626` |  |
| `lib/core/widgets/dev_env_banner.dart`:40 | `#6b7280` | `--availability-unavailable` |
| `lib/core/widgets/dev_env_banner.dart`:79 | `#6b7280` | `--availability-unavailable` |
| `lib/core/widgets/dev_env_banner.dart`:188 | `#6b7280` | `--availability-unavailable` |
| `lib/core/widgets/dev_env_banner.dart`:199 | `#111827` | `--bg-canvas` |
| `lib/core/widgets/dev_env_banner.dart`:207 | `#374151` | `--bg-elevated` |
| `lib/core/widgets/dev_env_banner.dart`:216 | `#7c3aed` |  |
| `lib/core/widgets/skeleton_loading.dart`:43 | `#e8e8e8` |  |
| `lib/core/widgets/skeleton_loading.dart`:44 | `#f5f5f5` |  |
| `lib/core/widgets/skeleton_loading.dart`:45 | `#e8e8e8` |  |
| `lib/features/chat/presentation/screens/admin_support_thread_screen.dart`:836 | `#ffb300` |  |
| `lib/features/chat/presentation/screens/admin_support_thread_screen.dart`:973 | `#ffe082` |  |
| `lib/features/chat/presentation/screens/chat_screen.dart`:651 | `#ffe082` |  |
| `lib/features/chat/presentation/screens/conversation_detail_screen.dart`:311 | `#00000033` |  |
| `lib/features/chat/presentation/screens/conversation_detail_screen.dart`:1705 | `#00000022` |  |
| `lib/features/chat/presentation/screens/conversation_detail_screen.dart`:1995 | `#ffe082` |  |
| `lib/features/featured_jobs/presentation/screens/featured_jobs_screen.dart`:214 | `#000000` |  |
| `lib/features/jobs/presentation/widgets/job_card.dart`:112 | `#000000` |  |
| `lib/features/jobs/presentation/widgets/quote_card.dart`:55 | `#000000` |  |
| `lib/features/jobs/presentation/widgets/service_offer_card.dart`:56 | `#000000` |  |
| `lib/features/notifications/presentation/widgets/notification_bell.dart`:34 | `#e53935` |  |
