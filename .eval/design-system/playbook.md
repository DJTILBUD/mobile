# Design system playbook

A Flutter application (entry point @lib/app.dart::App) built on a dedicated design system housed under lib/core/design_system, with an older theme layer in lib/core/theme/app_theme.dart that contributes a set of named palette colors (t46–t56) and scheme colors (t3, t4, t22). The design system defines semantic token groups for backgrounds (t0–t2, t23–t24), text (t5–t8), brand (t9–t15), state (t16–t19), borders (t20–t21), radii (t25–t28), spacing (t29–t36), shadows (t37–t38), motion (t39–t42), and two domain-specific groups: availability (t43–t45) and trust/verification (t57–t58). Together with the presence of @lib/app.dart::ReserveKeyboardDismissBar and @lib/core/design_system/showcase_screen.dart::_MusicianCard, these tokens indicate a product whose UI presents musicians, signals their availability and verified status, and supports some form of reserving. The component set covers the standard primitives (buttons, inputs, selection controls, chips, badges, navigation, tabs, dialogs, surfaces) plus an in-app showcase screen that documents the foundation and each component family. The list does not state the product name or further domain detail.

## In one screen

- **Theme lives in:** constants in the code.
- **Tokens:** 59 in 10 group(s), folded from 86 declaration(s).
- **Themes:** light and dark.
- **Spent:** 44 token(s) are used somewhere; 15 are declared and never used.
- **Components:** 513 declared, 19 primitives, 34 with variants (110 variant value(s)).
- **Disagreements:** 829 instance(s) in 4 kind(s). See the last section.

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

19 primitive component(s) in 18 file(s) live under `lib/core/design_system` (a `lib/core/design_system` directory of 21 files), and 227 screen file(s) build from them. 494 application component(s) sit on top, of which 158 are rendered in exactly one other file and 166 in none.

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
| DSDropdown | `lib/core/design_system/ds_dropdown.dart` | 9 | 6 | 5 | 0 |
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

### 780 hardcoded colour literal(s) bypass the tokens

Written into a colour property or an arbitrary class value; 168 duplicate a token that already exists.

- `web-app/src/app/page.module.css`:32: `background-color: rgba(var(--callout-rgb), 0.5);`
- `web-app/src/app/page.module.css`:33: `border: 1px solid rgba(var(--callout-border-rgb), 0.3);`
- `web-app/src/app/page.module.css`:52: `background: rgba(var(--card-rgb), 0);`
- `web-app/src/app/page.module.css`:53: `border: 1px solid rgba(var(--card-border-rgb), 0);`
- `web-app/src/app/page.module.css`:115: `background: rgba(var(--card-rgb), 0.1);`
- `web-app/src/app/page.module.css`:116: `border: 1px solid rgba(var(--card-border-rgb), 0.15);`
- `web-app/src/app/page.module.css`:182: `border-bottom: 1px solid rgba(var(--callout-border-rgb), 0.25);`
- `web-app/src/app/page.module.css`:183: `background: linear-gradient(to bottom, rgba(var(--background-start-rgb), 1), rgba(var(--callout-rgb), 0.5));`
- `web-app/src/app/page.module.css`:194: `background: linear-gradient(to bottom, transparent 0%, rgb(var(--background-end-rgb)) 40%);`
- `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:80: `.nav .badge{margin-left:auto;background:var(--sky);color:#141627;font-size:11px;font-weight:700;`

### Every hardcoded colour, by file

| file | literal | duplicates |
| --- | --- | --- |
| `web-app/src/app/page.module.css`:32 | `rgba(var(--callout-rgb)` |  |
| `web-app/src/app/page.module.css`:33 | `rgba(var(--callout-border-rgb)` |  |
| `web-app/src/app/page.module.css`:52 | `rgba(var(--card-rgb)` |  |
| `web-app/src/app/page.module.css`:53 | `rgba(var(--card-border-rgb)` |  |
| `web-app/src/app/page.module.css`:115 | `rgba(var(--card-rgb)` |  |
| `web-app/src/app/page.module.css`:116 | `rgba(var(--card-border-rgb)` |  |
| `web-app/src/app/page.module.css`:182 | `rgba(var(--callout-border-rgb)` |  |
| `web-app/src/app/page.module.css`:183 | `rgba(var(--background-start-rgb)` |  |
| `web-app/src/app/page.module.css`:194 | `rgb(var(--background-end-rgb)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:80 | `#141627` | `--text-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:92 | `#2A3550` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:122 | `rgba(209,243,102,.7)` | `--brand-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:126 | `#F5F6F2` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:164 | `#2A3550` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:179 | `#1F6E8C` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:179 | `rgba(102,208,242,.18)` | `--brand-accent` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:211 | `rgba(90,115,26,.4)` | `--brand-primary-active` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:270 | `#8A6A00` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:270 | `rgba(255,211,101,.35)` | `--state-warning` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:271 | `#4C6216` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:271 | `rgba(209,243,102,.4)` | `--brand-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:272 | `#1F6E8C` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:272 | `rgba(102,208,242,.35)` | `--brand-accent` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:273 | `#FFD365` | `--state-warning` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:274 | `#D1F366` | `--brand-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:275 | `#66D0F2` | `--brand-accent` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:276 | `#FFD365` | `--state-warning` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:277 | `#D1F366` | `--brand-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:278 | `#66D0F2` | `--brand-accent` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:299 | `rgba(0,0,0,.4)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:301 | `#fff` | `--bg-elevated` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:304 | `#fff` | `--bg-elevated` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:354 | `rgba(255,253,248,.97)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:355 | `#b8904a` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:355 | `rgba(180,150,100,.4)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:356 | `rgba(0,0,0,.15)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:357 | `#8a6030` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:358 | `#6a5840` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:359 | `#8a7f6a` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:392 | `rgba(20,22,39,.55)` | `--text-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:407 | `rgba(20,22,39,.5)` | `--text-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:440 | `#F5F6F2` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:442 | `#2B2E44` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:447 | `#101322` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:447 | `#EDEBE4` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:449 | `rgba(16,19,34,.82)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:450 | `rgba(237,235,228,.13)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:451 | `#9EA2B5` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:452 | `#D1F366` | `--brand-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:453 | `#EDEBE4` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:453 | `rgba(237,235,228,.24)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:454 | `rgba(237,235,228,.1)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:457 | `rgba(209,243,102,.2)` | `--brand-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:460 | `#9EA2B5` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:463 | `#D1F366` | `--brand-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:464 | `rgba(237,235,228,.32)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:465 | `#C8CBD8` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:467 | `rgba(237,235,228,.045)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:467 | `rgba(237,235,228,.12)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:471 | `#D1F366` | `--brand-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:471 | `#141627` | `--text-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:473 | `#9EA2B5` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:474 | `#D1F366` | `--brand-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:474 | `#141627` | `--text-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:477 | `#C8CBD8` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:478 | `rgba(237,235,228,.12)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:481 | `#D1F366` | `--brand-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:484 | `rgba(209,243,102,.14)` | `--brand-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:484 | `rgba(237,235,228,.14)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:486 | `rgba(209,243,102,.1)` | `--brand-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:486 | `rgba(209,243,102,.22)` | `--brand-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:488 | `#EDEBE4` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:490 | `rgba(237,235,228,.08)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:492 | `#6E7288` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:494 | `#9EA2B5` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:495 | `#9EA2B5` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:496 | `#D1F366` | `--brand-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:500 | `#D1F366` | `--brand-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:500 | `#141627` | `--text-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:501 | `#B8DC4B` | `--brand-primary-hover` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:502 | `#EDEBE4` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:502 | `rgba(237,235,228,.26)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:503 | `rgba(237,235,228,.09)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:505 | `#6E7288` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:506 | `#9EA2B5` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:527 | `#D1F366` | `--brand-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:580 | `rgba(209,243,102,.22)` | `--brand-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:581 | `#D1F366` | `--brand-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:582 | `#D1F366` | `--brand-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:767 | `#5A731A` | `--brand-primary-active` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:908 | `#1F6E8C` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1011 | `#D1F366` | `--brand-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1048 | `#D1F366` | `--brand-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1092 | `#9EA2B5` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1095 | `#9EA2B5` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1108 | `#D1F366` | `--brand-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1137 | `#cc2200` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1137 | `#cc8800` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1137 | `#1144cc` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1137 | `#119933` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1138 | `#ff3a2f` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1138 | `#ffbe2e` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1138 | `#2d78ff` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1138 | `#30d768` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1174 | `#000` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1175 | `rgba(210,205,198,0.8)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1176 | `rgba(190,184,175,0.55)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1177 | `rgba(190,184,175,0.5)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1178 | `rgba(255,255,255,0.7)` | `--bg-elevated` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1186 | `rgba(210,205,198,0.85)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1187 | `rgba(190,184,175,0.45)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1188 | `rgba(190,184,175,0.45)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1189 | `rgba(190,184,175,0.45)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1197 | `rgba(0,0,0,0.13)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1199 | `#232629` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1200 | `#1a1c1f` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1201 | `#111315` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1207 | `#232629` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1208 | `#1a1c1f` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1209 | `#111315` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1210 | `#111315` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1217 | `rgba(0,0,0,0.13)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1219 | `#2f3339` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1220 | `#2f3339` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1221 | `#2f3339` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1222 | `#2f3339` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1223 | `#2f3339` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1226 | `#3a3f46` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1235 | `#2b2f35` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1237 | `#fff` | `--bg-elevated` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1246 | `#ded8cc` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1255 | `#2a2d33` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1256 | `#e8c9a8` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1257 | `#3a3128` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1258 | `#1f2227` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1259 | `#1f2227` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1260 | `#1f2227` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1264 | `rgba(0,0,0,0.12)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1268 | `rgba(210,205,198,0.8)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1271 | `#26292e` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1272 | `#3b4046` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1273 | `#3b4046` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1274 | `#3b4046` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1283 | `#f0ede8` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1283 | `#e8e2d8` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1284 | `#c8b898` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1284 | `#b8a888` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1285 | `#ffffff` | `--bg-elevated` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1285 | `#f1eee7` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1286 | `#f8f6f1` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1286 | `#e9e4d8` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1287 | `#fdfcfa` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1287 | `#efeae0` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1288 | `#ffffff` | `--bg-elevated` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1288 | `#f4f1ea` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1288 | `#e7e0d6` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1289 | `#555` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1289 | `#999` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1289 | `#444` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1290 | `#fff8e8` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1290 | `#fff8e8` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1291 | `#ffffff` | `--bg-elevated` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1291 | `#f1eee8` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1292 | `#d8d2c7` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1292 | `#b8ad9d` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1293 | `#e6dccb` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1293 | `#c8b89e` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1293 | `#a9967a` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1294 | `#fff9e8` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1294 | `#fff9e8` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1295 | `#9922cc` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1295 | `#9922cc` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1296 | `#cc2266` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1296 | `#cc2266` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1297 | `#e8eaf0` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1297 | `#d0d4e0` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1298 | `#8a8a8a` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1298 | `#9a9a9a` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1298 | `#707070` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1309 | `#bac` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1312 | `rgba(255,255,255,0.5)` | `--bg-elevated` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1313 | `rgba(184,173,157,0.28)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1317 | `rgba(210,205,198,0.7)` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1325 | `#b6aa96` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1333 | `#b9a889` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1335 | `#a8906f` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1341 | `#caa56d` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1342 | `#ffe6a8` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1346 | `#d8cec0` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1347 | `#fff6e2` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1355 | `#3a3f46` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1357 | `#3a3f46` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1368 | `#b9a889` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1369 | `#9aa3ad` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1372 | `#cfd6dd` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1374 | `#eef3f7` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1379 | `#5e6166` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1385 | `#3a3f46` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1386 | `#2f3339` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1387 | `#2e2e2e` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1388 | `#4a4a4a` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1389 | `#6e6e6e` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1593 | `#1F6E8C` |  |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1601 | `#141627` | `--text-primary` |
| `web-app/documentation/partner-portal-prototype/kokkedal-portal.html`:1686 | `#F5F6F2` |  |
| `web-app/src/app/_components/PostBookingSection.tsx`:325 | `rgba(20, 23, 38, 0.35)` |  |
| `web-app/src/app/_components/ProcessSteps.tsx`:22 | `rgba(184, 220, 75, 0.5)` | `--brand-primary-hover` |
| `web-app/src/app/_components/ProcessSteps.tsx`:23 | `rgba(184, 220, 75, 0)` | `--brand-primary-hover` |
| `web-app/src/app/_components/ProcessSteps.tsx`:24 | `rgba(184, 220, 75, 0)` | `--brand-primary-hover` |
| `web-app/src/app/_components/ProcessSteps.tsx`:122 | `#272A41` |  |
| `web-app/src/app/_components/ProcessSteps.tsx`:594 | `rgba(20, 23, 38, 0.5)` |  |
| `web-app/src/app/dj/_components/DjJobStatusBadge.tsx`:14 | `#DAF585` |  |
| `web-app/src/app/dj/_components/DjJobStatusBadge.tsx`:18 | `#FFDC4B` |  |
| `web-app/src/app/dj/_components/DjJobStatusBadge.tsx`:22 | `#57CD55` |  |
| `web-app/src/app/dj/_components/DjJobStatusBadge.tsx`:26 | `#FF3000` |  |
| `web-app/src/app/dj/_components/DjJobStatusBadge.tsx`:30 | `#666666` |  |
| `web-app/src/app/dj/_components/constants.ts`:1 | `#DDDDDD` | `--border-subtle` |
| `web-app/src/app/dj/faq/page.tsx`:126 | `#F8F8F8` | `--bg-canvas` |
| `web-app/src/app/dj/faq/page.tsx`:144 | `#626577` | `--text-secondary` |
| `web-app/src/app/dj/faq/page.tsx`:195 | `#ADD13B` |  |
| `web-app/src/app/dj/faq/page.tsx`:200 | `#ADD13B` |  |
| `web-app/src/app/dj/faq/page.tsx`:204 | `#ADD13B` |  |
| `web-app/src/app/dj/faq/page.tsx`:227 | `#F8F8F8` | `--bg-canvas` |
| `web-app/src/app/dj/faq/page.tsx`:238 | `#626577` | `--text-secondary` |
| `web-app/src/app/dj/faq/page.tsx`:245 | `#3E8CFF` |  |
| `web-app/src/app/dj/faq/page.tsx`:247 | `#3679DB` |  |
| `web-app/src/app/dj/jobs/[id]/_components/QuoteForm/JobCollissionNotificationBanner.tsx`:28 | `#FFF7F6` |  |
| `web-app/src/app/dj/jobs/[id]/_components/QuoteForm/JobCollissionNotificationBanner.tsx`:45 | `#FF5A47` |  |
| `web-app/src/app/dj/jobs/[id]/_components/QuoteForm/JobCollissionNotificationBanner.tsx`:57 | `#FF5A47` |  |
| `web-app/src/app/dj/jobs/[id]/_components/QuoteForm/JobCollissionNotificationBanner.tsx`:60 | `#2D2D2D` |  |
| `web-app/src/app/dj/jobs/[id]/_components/QuoteForm/JobCollissionNotificationBanner.tsx`:66 | `#FF5A47` |  |
| `web-app/src/app/dj/jobs/[id]/_components/QuoteForm/JobCollissionNotificationBanner.tsx`:94 | `#FFF7F6` |  |
| `web-app/src/app/dj/jobs/[id]/_components/QuoteForm/JobCollissionNotificationBanner.tsx`:111 | `#FF5A47` |  |
| `web-app/src/app/dj/jobs/[id]/_components/QuoteForm/JobCollissionNotificationBanner.tsx`:123 | `#FF5A47` |  |
| `web-app/src/app/dj/jobs/[id]/_components/QuoteForm/JobCollissionNotificationBanner.tsx`:126 | `#2D2D2D` |  |
| `web-app/src/app/dj/jobs/[id]/_components/QuoteForm/QuoteForm.tsx`:498 | `rgba(72,187,120,0.35)` |  |
| `web-app/src/app/dj/udvalgte-jobs/page.tsx`:214 | `#D69E2E` |  |
| `web-app/src/app/ext-job/[ext_job_id]/page.tsx`:129 | `rgba(0,0,0,0.55)` |  |
| `web-app/src/app/ext-job/[ext_job_id]/page.tsx`:145 | `rgba(0,0,0,0.8)` |  |
| `web-app/src/app/ext-job/[ext_job_id]/page.tsx`:148 | `rgba(0,0,0,0.5)` |  |
| `web-app/src/app/ext-job/[ext_job_id]/page.tsx`:259 | `rgba(0,0,0,0.55)` |  |
| `web-app/src/app/ext-job/[ext_job_id]/page.tsx`:275 | `rgba(0,0,0,0.8)` |  |
| `web-app/src/app/ext-job/[ext_job_id]/page.tsx`:278 | `rgba(0,0,0,0.5)` |  |
| `web-app/src/app/job/[job_id]/question/page.tsx`:29 | `#F8F8F8` | `--bg-canvas` |
| `web-app/src/app/job/[job_id]/question/page.tsx`:46 | `#F8F8F8` | `--bg-canvas` |
| `web-app/src/app/job/[job_id]/question/page.tsx`:63 | `#626577` | `--text-secondary` |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:55 | `rgba(255,253,248,0.97)` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:57 | `rgba(180,150,100,0.4)` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:58 | `#b8904a` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:63 | `rgba(0,0,0,0.15)` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:69 | `#8a6030` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:79 | `#6a5840` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:95 | `rgba(0,0,0,0.12)` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:97 | `#2a2a2a` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:99 | `#383838` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:101 | `#1e1e1e` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:109 | `#1a1a1a` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:109 | `#444` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:112 | `#111` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:112 | `#333` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:114 | `#1a1a1a` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:114 | `#333` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:115 | `#222` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:116 | `#222` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:118 | `#141414` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:119 | `#111` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:121 | `#222` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:124 | `#111` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:124 | `#333` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:140 | `rgba(0,0,0,0.10)` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:141 | `#2a2a2a` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:142 | `#383838` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:143 | `#1e1e1e` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:146 | `#111` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:146 | `#333` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:154 | `#111` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:155 | `#2a2a2a` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:161 | `#0d0d0d` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:165 | `#181818` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:174 | `#111` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:174 | `#333` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:177 | `#161616` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:178 | `#1a1a1a` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:178 | `#2e2e2e` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:179 | `#1e1e1e` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:180 | `#1e1e1e` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:181 | `#141414` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:182 | `#111` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:183 | `#1e1e1e` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:185 | `#111` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:225 | `#000` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:226 | `rgba(210,205,198,0.8)` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:232 | `rgba(190,184,175,0.55)` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:239 | `rgba(190,184,175,0.5)` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:248 | `rgba(255,255,255,0.7)` | `--bg-elevated` |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:280 | `rgba(210,205,198,0.85)` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:286 | `rgba(190,184,175,0.45)` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:292 | `rgba(190,184,175,0.45)` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:298 | `rgba(190,184,175,0.45)` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:314 | `#777` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:314 | `#666` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:341 | `rgba(0,0,0,${breathe})` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:345 | `#121419` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:346 | `#2b2f36` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:351 | `#0d0f14` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:352 | `#1f232a` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:357 | `#0a0c10` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:363 | `#e4e7ec` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:364 | `#c7ccd4` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:370 | `#10161f` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:373 | `#6a6f76` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:383 | `rgba(0,0,0,0.08)` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:384 | `#f7f5f0` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:390 | `#e2ddd0` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:406 | `#ff3a2f` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:406 | `#ffbe2e` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:406 | `#2d78ff` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:406 | `#30d768` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:411 | `rgba(0,0,0,0.13)` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:419 | `#2f3339` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:428 | `#2f3339` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:432 | `#2f3339` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:433 | `#2f3339` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:434 | `#2f3339` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:444 | `#62676f` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:445 | `#4e5259` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:456 | `#30343b` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:457 | `#4a4f57` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:460 | `#383d45` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:460 | `#4f555f` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:469 | `#343840` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:472 | `#1b1f24` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:473 | `#2d323a` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:476 | `#444a53` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:477 | `#444a53` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:486 | `#0f1216` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:487 | `#20252d` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:502 | `#0a0c10` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:549 | `rgba(0,0,0,0.12)` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:554 | `#2a2f36` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:555 | `#434952` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:560 | `#2a2f36` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:561 | `#434952` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:564 | `#2e333a` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:567 | `#1a1e24` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:567 | `#30353e` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:568 | `#15191e` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:571 | `#454b55` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:572 | `#454b55` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:575 | `#0d1116` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:575 | `#252b33` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:586 | `#090c10` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:596 | `rgba(255,255,255,0.12)` | `--bg-elevated` |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:613 | `rgba(0,0,0,0.12)` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:616 | `#444` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:619 | `#909090` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:619 | `#707070` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:621 | `#b0b0b0` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:623 | `#606060` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:631 | `#383838` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:632 | `#2a2a2a` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:635 | `#222` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:636 | `#111` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:641 | `#3a3a3a` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:652 | `#ddf0f2` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:653 | `#aacccc` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:663 | `#99ccdd` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:672 | `#bbb` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:673 | `#aaa` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:677 | `#111` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:677 | `#2a2a2a` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:678 | `#00dd44` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:686 | `#808080` | `--colors-gray` |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:705 | `#111` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:714 | `#1a1a1a` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:718 | `#111` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:727 | `#000` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:740 | `#888` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:744 | `#00ee55` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:748 | `#2a2a2a` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:748 | `#333` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:750 | `#1c1c1c` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:750 | `#2e2e2e` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:762 | `#2e2e2e` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:778 | `#2e2e2e` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:816 | `hsl(220,6%,${L}%)` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:825 | `#aaa` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:826 | `#999` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:827 | `#282828` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:846 | `rgba(0,0,0,0.09)` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:851 | `#262d38` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:855 | `#0f141d` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:860 | `#d7b296` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:863 | `#d2ab8d` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:864 | `#d2ab8d` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:867 | `#dfbda0` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:872 | `#2a221f` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:874 | `#2a221f` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:875 | `#2a221f` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:881 | `#161616` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:884 | `#111` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:885 | `#111` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:893 | `#3b2e28` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:902 | `#3b2e28` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:911 | `#b78f73` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:915 | `#b68769` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:919 | `#9e6f54` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:930 | `#d5af92` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:939 | `#d5af92` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:943 | `#d5af92` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:944 | `#d5af92` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1158 | `#cc2200` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1158 | `#cc8800` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1158 | `#1144cc` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1158 | `#119933` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1168 | `hsl(${i * 36 + discoAngle * 0.5},75%,55%)` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1194 | `#222` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1195 | `#3a3a3a` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1196 | `#2e2e2e` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1197 | `#181818` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1200 | `#666` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1201 | `#ccc` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1202 | `#888` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1205 | `#555` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1206 | `#999` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1207 | `#444` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1210 | `#8a8a8a` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1211 | `#9a9a9a` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1212 | `#707070` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1216 | `#f0ede8` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1217 | `#e8e2d8` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1221 | `#c8b898` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1222 | `#b8a888` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1226 | `#ffffff` | `--bg-elevated` |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1227 | `#f1eee7` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1230 | `#f8f6f1` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1231 | `#e9e4d8` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1236 | `#ffffff` | `--bg-elevated` |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1237 | `#f4f1ea` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1238 | `#e7e0d6` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1242 | `#fff8e8` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1243 | `#fff8e8` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1247 | `#ffffff` | `--bg-elevated` |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1248 | `#f1eee8` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1251 | `#d8d2c7` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1252 | `#b8ad9d` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1256 | `#e6dccb` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1257 | `#c8b89e` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1258 | `#a9967a` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1261 | `#fff9e8` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1262 | `#fff9e8` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1266 | `#9922cc` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1267 | `#9922cc` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1270 | `#cc2266` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1271 | `#cc2266` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1282 | `#e8eaf0` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1283 | `#d0d4e0` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1287 | `#000` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1288 | `#000` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1303 | `#b6aa96` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1362 | `#b9a889` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1371 | `#a8906f` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1392 | `#caa56d` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1395 | `#ffe6a8` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1410 | `#d8cec0` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1414 | `#fff8eb` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1423 | `#b0a080` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1438 | `#9922cc` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1611 | `#cc44ff` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1631 | `#d9d4c9` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1640 | `#d9d4c9` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1648 | `#d2ccbf` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1669 | `#d8d4cc` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1677 | `#ffffff` | `--bg-elevated` |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1696 | `#000` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DJBoothScene.tsx`:1732 | `#a09070` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DjImageCarousel.tsx`:251 | `#F8F8F8` | `--bg-canvas` |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/DjImageCarousel.tsx`:262 | `#F8F8F8` | `--bg-canvas` |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/EquipmentScene.tsx`:168 | `#f8fafc` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/EquipmentScene.tsx`:168 | `#eef2f7` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/EquipmentScene.tsx`:189 | `rgba(2,6,23,0.97)` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/PriceAndBookingSection.tsx`:84 | `#F2F2F2` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/PriceAndBookingSection.tsx`:259 | `rgba(0, 0, 0, 0.2)` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/PriceAndBookingSection.tsx`:263 | `#929292` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/QuoteMessageSection.tsx`:96 | `#007AFF` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/QuoteMessageSection.tsx`:136 | `#2A2E4A` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/QuoteNavigation.tsx`:53 | `rgba(28, 31, 55, 0.5)` | `--brand-accent-soft` |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/_components/ReviewList.tsx`:34 | `#1696BE` |  |
| `web-app/src/app/job/[job_id]/quote/[quote_id]/page.tsx`:291 | `rgba(20, 23, 38, 0.25)` |  |
| `web-app/src/app/job/[job_id]/quote/_components/StatusSentJobPage/ArthurBlockquote.tsx`:17 | `#626577` | `--text-secondary` |
| `web-app/src/app/job/[job_id]/quote/_components/StatusSentJobPage/ArthurBlockquote.tsx`:20 | `#1C1F37` | `--brand-accent-soft` |
| `web-app/src/app/job/[job_id]/quote/_components/StatusSentJobPage/ArthurMessages.tsx`:132 | `#007AFF` |  |
| `web-app/src/app/job/[job_id]/quote/_components/StatusSentJobPage/ArthurMessages.tsx`:218 | `#007AFF` |  |
| `web-app/src/app/job/[job_id]/quote/_components/StatusSentJobPage/InfoSection.tsx`:13 | `#626577` | `--text-secondary` |
| `web-app/src/app/job/[job_id]/quote/_components/StatusSentJobPage/InfoSection.tsx`:32 | `#626577` | `--text-secondary` |
| `web-app/src/app/job/[job_id]/quote/_components/StatusSentJobPage/InfoSection.tsx`:36 | `#626577` | `--text-secondary` |
| `web-app/src/app/job/[job_id]/quote/_components/StatusSentJobPage/InfoSection.tsx`:51 | `#626577` | `--text-secondary` |
| `web-app/src/app/job/[job_id]/quote/_components/StatusSentJobPage/InfoSection.tsx`:55 | `#626577` | `--text-secondary` |
| `web-app/src/app/job/[job_id]/quote/_components/StatusSentJobPage/InfoSection.tsx`:70 | `#626577` | `--text-secondary` |
| `web-app/src/app/job/[job_id]/quote/_components/StatusSentJobPage/InfoSection.tsx`:75 | `#626577` | `--text-secondary` |
| `web-app/src/app/job/[job_id]/quote/_components/StatusSentJobPage/MusicianOfferCard.tsx`:98 | `rgba(20, 23, 38, 0.35)` |  |
| `web-app/src/app/job/[job_id]/quote/_components/StatusSentJobPage/MusicianOfferCard.tsx`:129 | `rgba(0,0,0,0.8)` |  |
| `web-app/src/app/job/[job_id]/quote/_components/StatusSentJobPage/MusicianOfferCard.tsx`:140 | `rgba(0,0,0,0.55)` |  |
| `web-app/src/app/job/[job_id]/quote/_components/StatusSentJobPage/MusicianOfferCard.tsx`:154 | `rgba(0,0,0,0.5)` |  |
| `web-app/src/app/job/[job_id]/quote/_components/StatusSentJobPage/ProgressBar.tsx`:9 | `#F8F8F8` | `--bg-canvas` |
| `web-app/src/app/job/[job_id]/quote/_components/StatusSentJobPage/QuotesDisplay.tsx`:285 | `#929292` |  |
| `web-app/src/app/job/[job_id]/quote/_components/StatusSentJobPage/QuotesDisplay.tsx`:301 | `#929292` |  |
| `web-app/src/app/job/[job_id]/quote/_components/StatusSentJobPage/WelcomeSection.tsx`:18 | `#F7FFDF` |  |
| `web-app/src/app/job/[job_id]/quote/serviceoffer/[offer_id]/_components/ArthurMusicianMessage.tsx`:70 | `#007AFF` |  |
| `web-app/src/app/job/[job_id]/quote/serviceoffer/[offer_id]/_components/MusicianPriceSection.tsx`:89 | `#F2F2F2` |  |
| `web-app/src/app/job/[job_id]/quote/serviceoffer/[offer_id]/_components/ServiceOfferMessageSection.tsx`:54 | `#007AFF` |  |
| `web-app/src/app/job/[job_id]/quote/serviceoffer/[offer_id]/page.tsx`:389 | `rgba(0, 0, 0, 0.2)` |  |
| `web-app/src/app/job/[job_id]/quote/serviceoffer/[offer_id]/page.tsx`:393 | `#929292` |  |
| `web-app/src/app/layout.tsx`:71 | `#1C1F37` | `--brand-accent-soft` |
| `web-app/src/app/layout.tsx`:81 | `#5bbad5` |  |
| `web-app/src/app/preview/dj/[dj_id]/page.tsx`:35 | `#ADD13B` |  |
| `web-app/src/app/preview/musician/[musician_id]/page.tsx`:31 | `#ADD13B` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:56 | `#ff6ec7` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:56 | `#a855f7` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:56 | `#06b6d4` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:56 | `#fbbf24` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:56 | `#34d399` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:88 | `#ff6ec7` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:88 | `#a855f7` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:99 | `rgba(168,85,247,0.15)` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:100 | `rgba(168,85,247,0.3)` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:115 | `rgba(255,255,255,0.06)` | `--bg-elevated` |
| `web-app/src/app/song-request/[token]/page.tsx`:116 | `rgba(255,255,255,0.1)` | `--bg-elevated` |
| `web-app/src/app/song-request/[token]/page.tsx`:156 | `#a855f7` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:156 | `#ff6ec7` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:156 | `rgba(255,255,255,0.1)` | `--bg-elevated` |
| `web-app/src/app/song-request/[token]/page.tsx`:157 | `rgba(255,255,255,0.35)` | `--bg-elevated` |
| `web-app/src/app/song-request/[token]/page.tsx`:158 | `rgba(255,110,199,0.6)` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:180 | `#a855f7` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:180 | `#ff6ec7` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:180 | `rgba(255,255,255,0.15)` | `--bg-elevated` |
| `web-app/src/app/song-request/[token]/page.tsx`:277 | `#a855f780` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:277 | `#ff6ec740` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:278 | `#a855f7` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:278 | `#ff6ec780` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:285 | `rgba(255,255,255,0.06)` | `--bg-elevated` |
| `web-app/src/app/song-request/[token]/page.tsx`:286 | `rgba(168,85,247,0.4)` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:291 | `rgba(255,255,255,0.35)` | `--bg-elevated` |
| `web-app/src/app/song-request/[token]/page.tsx`:293 | `#ff6ec7` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:294 | `#ff6ec7` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:294 | `#ff6ec750` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:295 | `rgba(255,255,255,0.1)` | `--bg-elevated` |
| `web-app/src/app/song-request/[token]/page.tsx`:309 | `#0d0d1a` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:309 | `#1a0a2e` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:309 | `#0a1628` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:309 | `#1a0d2e` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:343 | `rgba(255,255,255,0.05)` | `--bg-elevated` |
| `web-app/src/app/song-request/[token]/page.tsx`:345 | `rgba(255,255,255,0.1)` | `--bg-elevated` |
| `web-app/src/app/song-request/[token]/page.tsx`:365 | `rgba(255,255,255,0.05)` | `--bg-elevated` |
| `web-app/src/app/song-request/[token]/page.tsx`:367 | `rgba(255,255,255,0.1)` | `--bg-elevated` |
| `web-app/src/app/song-request/[token]/page.tsx`:395 | `rgba(255,255,255,0.05)` | `--bg-elevated` |
| `web-app/src/app/song-request/[token]/page.tsx`:397 | `rgba(168,85,247,0.3)` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:410 | `rgba(168,85,247,0.3)` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:410 | `rgba(255,110,199,0.2)` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:411 | `rgba(168,85,247,0.2)` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:414 | `rgba(255,110,199,0.6)` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:482 | `rgba(255,255,255,0.1)` | `--bg-elevated` |
| `web-app/src/app/song-request/[token]/page.tsx`:483 | `rgba(168,85,247,0.5)` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:574 | `rgba(255,80,80,0.15)` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:575 | `rgba(255,80,80,0.4)` |  |
| `web-app/src/app/song-request/[token]/page.tsx`:612 | `rgba(255,255,255,0.1)` | `--bg-elevated` |
| `web-app/src/app/song-request/[token]/page.tsx`:613 | `rgba(168,85,247,0.5)` |  |
| `web-app/src/app/vaelg-din-dj/page.tsx`:83 | `rgba(0,0,0,0.75)` |  |
| `web-app/src/app/vaelg-din-dj/page.tsx`:131 | `rgba(20, 23, 38, 0.35)` |  |
| `web-app/src/app/vaelg-din-dj/page.tsx`:137 | `rgba(0,0,0,0.8)` |  |
| `web-app/src/app/vaelg-din-dj/page.tsx`:140 | `rgba(0,0,0,0.5)` |  |
| `web-app/src/app/vaelg-din-dj/page.tsx`:211 | `#007AFF` |  |
| `web-app/src/components/ArthurFromDJTilbud/ArthurFromDJTilbud.tsx`:7 | `rgba(45, 55, 72, 0.5)` |  |
| `web-app/src/components/ArthurFromDJTilbud/ArthurPreviewMessage.tsx`:39 | `#007AFF` |  |
| `web-app/src/components/BackButton.tsx`:40 | `#E2E8F0` |  |
| `web-app/src/components/BoogieBusterButton.tsx`:15 | `#D1F381` |  |
| `web-app/src/components/BoogieBusterButton.tsx`:15 | `#B8DC4B` | `--brand-primary-hover` |
| `web-app/src/components/CustomDatePicker.tsx`:93 | `#e2e8f0` |  |
| `web-app/src/components/CustomDatePicker.tsx`:95 | `rgba(0, 0, 0, 0.1)` |  |
| `web-app/src/components/CustomDatePicker.tsx`:117 | `#edf2f7` |  |
| `web-app/src/components/CustomDatePicker.tsx`:121 | `#02101c` |  |
| `web-app/src/components/CustomDatePicker.tsx`:126 | `#a0aec0` |  |
| `web-app/src/components/CustomDatePicker.tsx`:140 | `rgba(0, 0, 0, 0.1)` |  |
| `web-app/src/components/CustomDatePicker.tsx`:150 | `#edf2f7` |  |
| `web-app/src/components/CustomDatePicker.tsx`:154 | `#3182ce` |  |
| `web-app/src/components/CustomDatePicker.tsx`:164 | `#e2e8f0` |  |
| `web-app/src/components/CustomDatePicker.tsx`:178 | `#e2e8f0` |  |
| `web-app/src/components/CustomDatePicker.tsx`:198 | `#03111e` |  |
| `web-app/src/components/CustomerSideQuoteCard/CustomerSideQuoteCard.tsx`:186 | `rgba(20, 23, 38, 0.35)` |  |
| `web-app/src/components/CustomerSideQuoteCard/CustomerSideQuoteCard.tsx`:215 | `rgba(0,0,0,0.8)` |  |
| `web-app/src/components/CustomerSideQuoteCard/CustomerSideQuoteCard.tsx`:226 | `rgba(0,0,0,0.55)` |  |
| `web-app/src/components/CustomerSideQuoteCard/CustomerSideQuoteCard.tsx`:238 | `rgba(0,0,0,0.5)` |  |
| `web-app/src/components/CustomerSideQuoteCard/CustomerSideQuoteCardMobile.tsx`:188 | `rgba(20, 23, 38, 0.35)` |  |
| `web-app/src/components/CustomerSideQuoteCard/CustomerSideQuoteCardMobile.tsx`:213 | `rgba(0,0,0,0.8)` |  |
| `web-app/src/components/CustomerSideQuoteCard/CustomerSideQuoteCardMobile.tsx`:224 | `rgba(0,0,0,0.55)` |  |
| `web-app/src/components/CustomerSideQuoteCard/CustomerSideQuoteCardMobile.tsx`:236 | `rgba(0,0,0,0.5)` |  |
| `web-app/src/components/DitEvent.tsx`:19 | `#D1F366` | `--brand-primary` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:21 | `rgba(255, 211, 101, 0.35)` | `--state-warning` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:22 | `#FFD365` | `--state-warning` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:23 | `rgba(255, 255, 255, 0.3)` | `--bg-elevated` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:24 | `rgba(255, 211, 101, 0.4)` | `--state-warning` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:27 | `rgba(102, 208, 242, 0.35)` | `--brand-accent` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:28 | `#66D0F2` | `--brand-accent` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:29 | `rgba(255, 255, 255, 0.3)` | `--bg-elevated` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:30 | `rgba(102, 208, 242, 0.4)` | `--brand-accent` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:33 | `rgba(236, 80, 44, 0.35)` | `--state-danger` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:34 | `#EC502C` | `--state-danger` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:35 | `rgba(255, 255, 255, 0.3)` | `--bg-elevated` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:36 | `rgba(236, 80, 44, 0.4)` | `--state-danger` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:39 | `rgba(209, 243, 102, 0.35)` | `--brand-primary` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:40 | `#D1F366` | `--brand-primary` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:41 | `rgba(255, 255, 255, 0.3)` | `--bg-elevated` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:42 | `rgba(209, 243, 102, 0.4)` | `--brand-primary` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:45 | `rgba(155, 126, 222, 0.35)` |  |
| `web-app/src/components/DjBadge/DjBadge.tsx`:46 | `#9B7EDE` |  |
| `web-app/src/components/DjBadge/DjBadge.tsx`:47 | `rgba(255, 255, 255, 0.3)` | `--bg-elevated` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:48 | `rgba(155, 126, 222, 0.4)` |  |
| `web-app/src/components/DjBadge/DjBadge.tsx`:51 | `rgba(77, 184, 184, 0.35)` |  |
| `web-app/src/components/DjBadge/DjBadge.tsx`:52 | `#4DB8B8` |  |
| `web-app/src/components/DjBadge/DjBadge.tsx`:53 | `rgba(255, 255, 255, 0.3)` | `--bg-elevated` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:54 | `rgba(77, 184, 184, 0.4)` |  |
| `web-app/src/components/DjBadge/DjBadge.tsx`:57 | `rgba(255, 139, 139, 0.35)` | `--colors-peach-red` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:58 | `#FF8B8B` | `--colors-peach-red` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:59 | `rgba(255, 255, 255, 0.3)` | `--bg-elevated` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:60 | `rgba(255, 139, 139, 0.4)` | `--colors-peach-red` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:63 | `rgba(102, 208, 242, 0.35)` | `--brand-accent` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:64 | `#66D0F2` | `--brand-accent` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:65 | `rgba(255, 255, 255, 0.3)` | `--bg-elevated` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:66 | `rgba(102, 208, 242, 0.4)` | `--brand-accent` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:69 | `rgba(98, 101, 119, 0.35)` | `--text-secondary` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:70 | `#626577` | `--text-secondary` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:71 | `rgba(255, 255, 255, 0.2)` | `--bg-elevated` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:72 | `rgba(98, 101, 119, 0.4)` | `--text-secondary` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:134 | `rgba(0,0,0,0.1)` |  |
| `web-app/src/components/DjBadge/DjBadge.tsx`:153 | `rgba(255,255,255,0.6)` | `--bg-elevated` |
| `web-app/src/components/DjBadge/DjBadge.tsx`:175 | `rgba(0, 0, 0, 0.3)` |  |
| `web-app/src/components/DjContactCard.tsx`:51 | `#667eea` |  |
| `web-app/src/components/DjContactCard.tsx`:51 | `#764ba2` |  |
| `web-app/src/components/DjProfile/DjProfile.tsx`:72 | `#D5D5D5` |  |
| `web-app/src/components/DjProfile/DjProfile.tsx`:141 | `#ADD13B` |  |
| `web-app/src/components/DjProfile/DjProfile.tsx`:145 | `#ADD13B` |  |
| `web-app/src/components/DjProfile/DjProfile.tsx`:149 | `#ADD13B` |  |
| `web-app/src/components/DjProfile/DjProfile.tsx`:161 | `#A1A1A1` |  |
| `web-app/src/components/DjProfile/DjProfile.tsx`:171 | `#ADD13B` |  |
| `web-app/src/components/DjProfile/DjProfile.tsx`:175 | `#626577` | `--text-secondary` |
| `web-app/src/components/DjProfile/DjProfile.tsx`:180 | `#ADD13B` |  |
| `web-app/src/components/DjProfile/DjProfile.tsx`:184 | `#626577` | `--text-secondary` |
| `web-app/src/components/DjProfile/DjProfile.tsx`:189 | `#ADD13B` |  |
| `web-app/src/components/DjProfile/DjProfile.tsx`:193 | `#626577` | `--text-secondary` |
| `web-app/src/components/DjProfile/DjProfile.tsx`:205 | `#1C1F37` | `--brand-accent-soft` |
| `web-app/src/components/DjProfile/DjProfile.tsx`:211 | `#ADD13B` |  |
| `web-app/src/components/DjProfile/DjProfile.tsx`:215 | `#626577` | `--text-secondary` |
| `web-app/src/components/DjProfile/DjProfile.tsx`:220 | `#ADD13B` |  |
| `web-app/src/components/DjSideQuoteCard.tsx`:253 | `#D69E2E` |  |
| `web-app/src/components/DjUrgencyIndicator.tsx`:62 | `rgba(0, 0, 0, 0.25)` |  |
| `web-app/src/components/EditQuoteModal/EditQuoteModal.tsx`:587 | `rgba(72,187,120,0.35)` |  |
| `web-app/src/components/ExtDjContactCard.tsx`:47 | `#667eea` |  |
| `web-app/src/components/ExtDjContactCard.tsx`:47 | `#764ba2` |  |
| `web-app/src/components/FAQCard.tsx`:33 | `#626577` | `--text-secondary` |
| `web-app/src/components/FAQCard.tsx`:43 | `#ADD13B` |  |
| `web-app/src/components/FAQCard.tsx`:47 | `#ADD13B` |  |
| `web-app/src/components/FAQCard.tsx`:52 | `#ADD13B` |  |
| `web-app/src/components/FAQCard.tsx`:65 | `#626577` | `--text-secondary` |
| `web-app/src/components/Footer.tsx`:92 | `rgba(0, 0, 0, 0.2)` |  |
| `web-app/src/components/Footer.tsx`:102 | `#929292` |  |
| `web-app/src/components/FooterInfoInCard.tsx`:28 | `#626577` | `--text-secondary` |
| `web-app/src/components/FooterInfoInCard.tsx`:38 | `#626577` | `--text-secondary` |
| `web-app/src/components/FooterInfoInCard.tsx`:44 | `#626577` | `--text-secondary` |
| `web-app/src/components/FooterInfoInCard.tsx`:50 | `#626577` | `--text-secondary` |
| `web-app/src/components/FooterInfoInCard.tsx`:58 | `#007AFF` |  |
| `web-app/src/components/FooterInfoInCard.tsx`:71 | `rgba(0, 0, 0, 0.2)` |  |
| `web-app/src/components/FooterInfoInCard.tsx`:81 | `#929292` |  |
| `web-app/src/components/FormStarRating.tsx`:40 | `#ffc107` |  |
| `web-app/src/components/FormStarRating.tsx`:40 | `#e4e5e9` |  |
| `web-app/src/components/FormStarRating.tsx`:58 | `#ffc107` |  |
| `web-app/src/components/Gallery/Gallery.tsx`:62 | `rgba(0, 0, 0, 0.7)` |  |
| `web-app/src/components/Gallery/Gallery.tsx`:85 | `rgba(0, 0, 0, 0.5)` |  |
| `web-app/src/components/Gallery/Gallery.tsx`:92 | `rgba(0, 0, 0, 0.2)` |  |
| `web-app/src/components/GuaranteeModalBody.tsx`:56 | `#626577` | `--text-secondary` |
| `web-app/src/components/GuaranteeModalBody.tsx`:64 | `#626577` | `--text-secondary` |
| `web-app/src/components/GuaranteeModalBody.tsx`:73 | `#626577` | `--text-secondary` |
| `web-app/src/components/GuaranteeModalBody.tsx`:95 | `#D1F381` |  |
| `web-app/src/components/IOSPWAPrompt.tsx`:40 | `#F2F2F7` |  |
| `web-app/src/components/IOSPWAPrompt.tsx`:44 | `#C6C6C8` |  |
| `web-app/src/components/IOSPWAPrompt.tsx`:64 | `#007AFF` |  |
| `web-app/src/components/IOSPWAPrompt.tsx`:67 | `#007AFF` |  |
| `web-app/src/components/IOSPWAPrompt.tsx`:74 | `#3A3A3C` |  |
| `web-app/src/components/IOSPWAPrompt.tsx`:82 | `#007AFF` |  |
| `web-app/src/components/IOSPWAPrompt.tsx`:96 | `#E5E5EA` |  |
| `web-app/src/components/IOSPWAPrompt.tsx`:98 | `#3A3A3C` |  |
| `web-app/src/components/ImageLightbox/ImageLightbox.tsx`:59 | `rgba(0, 0, 0, 0.9)` |  |
| `web-app/src/components/ImageLightbox/LightboxIconButton.tsx`:28 | `rgba(0, 0, 0, 0.3)` |  |
| `web-app/src/components/ImageLightbox/LightboxIconButton.tsx`:32 | `rgba(0, 0, 0, 0.5)` |  |
| `web-app/src/components/ImageUploader/ImageUploader.tsx`:140 | `#08858630` |  |
| `web-app/src/components/ProfilePreview/ProfilePreview.tsx`:44 | `rgba(0,0,0,0.05)` |  |
| `web-app/src/components/Review/Modal/UpsertMusicianReviewModal.tsx`:351 | `#b54808` |  |
| `web-app/src/components/Review/Modal/UpsertMusicianReviewModal.tsx`:352 | `#b54808` |  |
| `web-app/src/components/Review/Modal/UpsertReviewModal.tsx`:273 | `#ffc107` |  |
| `web-app/src/components/Review/Modal/UpsertReviewModal.tsx`:413 | `#b54808` |  |
| `web-app/src/components/Review/Modal/UpsertReviewModal.tsx`:414 | `#b54808` |  |
| `web-app/src/components/Review/Modal/ViewReviewsModal.tsx`:39 | `rgba(0, 0, 0, 0.2)` |  |
| `web-app/src/components/Review/Modal/ViewReviewsModal.tsx`:75 | `#A1A1A1` |  |
| `web-app/src/components/Review/Modal/ViewReviewsModal.tsx`:82 | `#929292` |  |
| `web-app/src/components/Review/ReviewCard.tsx`:42 | `#017822` |  |
| `web-app/src/components/Review/ReviewCard.tsx`:43 | `#0797680D` |  |
| `web-app/src/components/ServiceOfferCard.tsx`:225 | `#D69E2E` |  |
| `web-app/src/components/Sidebar/NavItem.tsx`:67 | `rgba(62, 65, 85, 0.8)` |  |
| `web-app/src/components/Sidebar/Sidebar.tsx`:51 | `rgba(0, 0, 0, 0.1)` |  |
| `web-app/src/components/StarRating.tsx`:24 | `#ffc107` |  |
| `web-app/src/components/StarRating.tsx`:24 | `#e4e5e9` |  |
| `web-app/src/components/StarRating.tsx`:36 | `#ffc107` |  |
| `web-app/src/components/Trustpilot/TrustpilotRating.tsx`:12 | `rgba(45, 55, 72, 0.5)` |  |
| `web-app/src/components/Trustpilot/TrustpilotRating.tsx`:62 | `#909090` |  |
| `web-app/src/components/VerifiedBookings.tsx`:16 | `#017822` |  |
| `web-app/src/components/VerifiedBookings.tsx`:17 | `#0797680D` |  |
| `web-app/src/components/VideoUploader/VideoUploader.tsx`:146 | `#08858630` |  |
| `web-app/src/components/chat/ChatMessages.tsx`:324 | `rgba(0,0,0,0.18)` |  |
| `web-app/src/components/chat/ChatMessages.tsx`:329 | `rgba(0,0,0,0.28)` |  |
| `web-app/src/components/chat/ChatMessages.tsx`:610 | `#f6e05e` |  |
| `web-app/src/components/chat/FloatingChatButton.tsx`:69 | `#3182CE` |  |
| `web-app/src/useTheme.ts`:5 | `#66D0F2` | `--brand-accent` |
| `web-app/src/useTheme.ts`:11 | `#FFD365` | `--state-warning` |
| `web-app/src/useTheme.ts`:17 | `#D1F366` | `--brand-primary` |
| `web-app/src/useTheme.ts`:24 | `#FF8B8B` | `--colors-peach-red` |
| `web-app/src/useTheme.ts`:31 | `#f8fbe7` |  |
| `web-app/src/useTheme.ts`:32 | `#f0f8c2` |  |
| `web-app/src/useTheme.ts`:33 | `#e6f399` |  |
| `web-app/src/useTheme.ts`:34 | `#dbed6d` |  |
| `web-app/src/useTheme.ts`:35 | `#d1f366` | `--brand-primary` |
| `web-app/src/useTheme.ts`:36 | `#b8dc4b` | `--brand-primary-hover` |
| `web-app/src/useTheme.ts`:37 | `#a0c53a` |  |
| `web-app/src/useTheme.ts`:38 | `#7e9e2a` |  |
| `web-app/src/useTheme.ts`:39 | `#5a731a` | `--brand-primary-active` |
| `web-app/src/useTheme.ts`:40 | `#36480a` |  |
| `web-app/src/useTheme.ts`:49 | `#EC502C` | `--state-danger` |
| `web-app/src/useTheme.ts`:50 | `#141627` | `--text-primary` |
| `web-app/src/useTheme.ts`:51 | `#1C1F37` | `--brand-accent-soft` |
| `web-app/src/useTheme.ts`:52 | `#D1F366` | `--brand-primary` |
| `web-app/src/useTheme.ts`:53 | `#D0D4E7` | `--brand-accent-soft` |
| `web-app/src/useTheme.ts`:54 | `#F5F5F5` |  |
| `web-app/src/useTheme.ts`:55 | `#F3F3F3` | `--bg-input-bg` |
| `web-app/src/useTheme.ts`:58 | `#000000` |  |
| `web-app/src/useTheme.ts`:60 | `#626577` | `--text-secondary` |
| `web-app/src/useTheme.ts`:61 | `#B1B1B1` | `--colors-border-line-gray` |
| `web-app/src/useTheme.ts`:289 | `#F8F8F8` | `--bg-canvas` |
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
