# Design system playbook

A Flutter mobile app for gigging musicians, specifically DJs and instrumentalists. They use it to browse incoming event jobs, submit and manage quotes and service offers, and track won gigs on a calendar. It also covers chat with customers and admin support, notifications, and their own profile, media, reviews, filters, payment/self-billing details, stats and referrals. A shared DS-prefixed design system provides the core controls, alongside AI assistant bottom sheets, onboarding and auth flows.

## In one screen

- **Theme lives in:** no theme file this extraction recognises.
- **Tokens:** 0 in 0 group(s), folded from 0 declaration(s).
- **Themes:** light only.
- **Spent:** 0 token(s) are used somewhere; 0 are declared and never used.
- **Components:** 0 declared, 0 primitives, 0 with variants (0 variant value(s)).
- **Disagreements:** 200 instance(s) in 1 kind(s). See the last section.

## Where the design is declared

| file | what it declares |
| --- | --- |
| _none found_ | |

## Palette

0 colour token(s) are re-declared for dark mode; 0 keep their light value.

## Scales

### Spacing

No spacing tokens are declared, so the framework default scale is in use. 0 arbitrary value(s) step off it.

### Typography

No font families or type steps are declared in the stylesheets.

## States the UI actually targets

| state | class occurrences |
| --- | --- |
| `active` | 8 |

## Composition

No primitives directory was found, so every component is an application component: there is an inventory here but no shared kit to build from.

## Where the app disagrees with itself

### 200 hardcoded colour literal(s) bypass the tokens

Written into a colour property or an arbitrary class value.

- `design-system/figma-plugin/code.js`:15: `'Brand/Primary':             '#D1F366',`
- `design-system/figma-plugin/code.js`:16: `'Brand/Primary Hover':       '#B8DC4B',`
- `design-system/figma-plugin/code.js`:17: `'Brand/Primary Active':      '#5A731A',`
- `design-system/figma-plugin/code.js`:18: `'Brand/On Primary':          '#141627',`
- `design-system/figma-plugin/code.js`:19: `'Brand/Accent':              '#66D0F2',`
- `design-system/figma-plugin/code.js`:20: `'Brand/Accent Soft':         '#D0D4E7',`
- `design-system/figma-plugin/code.js`:21: `'Brand/On Accent':           '#141627',`
- `design-system/figma-plugin/code.js`:22: `'Background/Canvas':         '#F8F8F8',`
- `design-system/figma-plugin/code.js`:23: `'Background/Surface':        '#FFFFFF',`
- `design-system/figma-plugin/code.js`:24: `'Background/Elevated':       '#FFFFFF',`

### Every hardcoded colour, by file

| file | literal | duplicates |
| --- | --- | --- |
| `design-system/figma-plugin/code.js`:15 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:16 | `#B8DC4B` |  |
| `design-system/figma-plugin/code.js`:17 | `#5A731A` |  |
| `design-system/figma-plugin/code.js`:18 | `#141627` |  |
| `design-system/figma-plugin/code.js`:19 | `#66D0F2` |  |
| `design-system/figma-plugin/code.js`:20 | `#D0D4E7` |  |
| `design-system/figma-plugin/code.js`:21 | `#141627` |  |
| `design-system/figma-plugin/code.js`:22 | `#F8F8F8` |  |
| `design-system/figma-plugin/code.js`:23 | `#FFFFFF` |  |
| `design-system/figma-plugin/code.js`:24 | `#FFFFFF` |  |
| `design-system/figma-plugin/code.js`:25 | `#F3F3F3` |  |
| `design-system/figma-plugin/code.js`:26 | `#DDDDDD` |  |
| `design-system/figma-plugin/code.js`:27 | `#141627` |  |
| `design-system/figma-plugin/code.js`:28 | `#626577` |  |
| `design-system/figma-plugin/code.js`:29 | `#9A9CAB` |  |
| `design-system/figma-plugin/code.js`:30 | `#FFFFFF` |  |
| `design-system/figma-plugin/code.js`:31 | `#DDDDDD` |  |
| `design-system/figma-plugin/code.js`:32 | `#626577` |  |
| `design-system/figma-plugin/code.js`:33 | `#5A731A` |  |
| `design-system/figma-plugin/code.js`:34 | `#FFD365` |  |
| `design-system/figma-plugin/code.js`:35 | `#EC502C` |  |
| `design-system/figma-plugin/code.js`:36 | `#66D0F2` |  |
| `design-system/figma-plugin/code.js`:37 | `#66D0F2` |  |
| `design-system/figma-plugin/code.js`:38 | `#D0D4E7` |  |
| `design-system/figma-plugin/code.js`:39 | `#5A731A` |  |
| `design-system/figma-plugin/code.js`:40 | `#FFD365` |  |
| `design-system/figma-plugin/code.js`:41 | `#9A9CAB` |  |
| `design-system/figma-plugin/code.js`:45 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:46 | `#B8DC4B` |  |
| `design-system/figma-plugin/code.js`:47 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:48 | `#141627` |  |
| `design-system/figma-plugin/code.js`:49 | `#66D0F2` |  |
| `design-system/figma-plugin/code.js`:50 | `#1C1F37` |  |
| `design-system/figma-plugin/code.js`:51 | `#141627` |  |
| `design-system/figma-plugin/code.js`:52 | `#111827` |  |
| `design-system/figma-plugin/code.js`:53 | `#1F2937` |  |
| `design-system/figma-plugin/code.js`:54 | `#374151` |  |
| `design-system/figma-plugin/code.js`:55 | `#1F2937` |  |
| `design-system/figma-plugin/code.js`:56 | `#374151` |  |
| `design-system/figma-plugin/code.js`:57 | `#F9FAFB` |  |
| `design-system/figma-plugin/code.js`:58 | `#D1D5DB` |  |
| `design-system/figma-plugin/code.js`:59 | `#9CA3AF` |  |
| `design-system/figma-plugin/code.js`:60 | `#F9FAFB` |  |
| `design-system/figma-plugin/code.js`:61 | `#374151` |  |
| `design-system/figma-plugin/code.js`:62 | `#4B5563` |  |
| `design-system/figma-plugin/code.js`:63 | `#22C55E` |  |
| `design-system/figma-plugin/code.js`:64 | `#F59E0B` |  |
| `design-system/figma-plugin/code.js`:65 | `#EF4444` |  |
| `design-system/figma-plugin/code.js`:66 | `#3B82F6` |  |
| `design-system/figma-plugin/code.js`:67 | `#2DD4BF` |  |
| `design-system/figma-plugin/code.js`:68 | `#134E4A` |  |
| `design-system/figma-plugin/code.js`:69 | `#22C55E` |  |
| `design-system/figma-plugin/code.js`:70 | `#F59E0B` |  |
| `design-system/figma-plugin/code.js`:71 | `#6B7280` |  |
| `design-system/figma-plugin/code.js`:109 | `#0F172A` |  |
| `design-system/figma-plugin/code.js`:157 | `#141627` |  |
| `design-system/figma-plugin/code.js`:158 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:164 | `#FFFFFF` |  |
| `design-system/figma-plugin/code.js`:164 | `#DDDDDD` |  |
| `design-system/figma-plugin/code.js`:166 | `#F8F8F8` |  |
| `design-system/figma-plugin/code.js`:167 | `#141627` |  |
| `design-system/figma-plugin/code.js`:168 | `#9A9CAB` |  |
| `design-system/figma-plugin/code.js`:177 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:178 | `#141627` |  |
| `design-system/figma-plugin/code.js`:181 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:182 | `#5A731A` |  |
| `design-system/figma-plugin/code.js`:185 | `#FFFFFF` |  |
| `design-system/figma-plugin/code.js`:185 | `#626577` |  |
| `design-system/figma-plugin/code.js`:186 | `#141627` |  |
| `design-system/figma-plugin/code.js`:190 | `#626577` |  |
| `design-system/figma-plugin/code.js`:193 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:194 | `#141627` |  |
| `design-system/figma-plugin/code.js`:196 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:197 | `#141627` |  |
| `design-system/figma-plugin/code.js`:199 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:200 | `#141627` |  |
| `design-system/figma-plugin/code.js`:203 | `#DDDDDD` |  |
| `design-system/figma-plugin/code.js`:204 | `#9A9CAB` |  |
| `design-system/figma-plugin/code.js`:211 | `#141627` |  |
| `design-system/figma-plugin/code.js`:213 | `#F3F3F3` |  |
| `design-system/figma-plugin/code.js`:214 | `#9A9CAB` |  |
| `design-system/figma-plugin/code.js`:217 | `#141627` |  |
| `design-system/figma-plugin/code.js`:218 | `#F3F3F3` |  |
| `design-system/figma-plugin/code.js`:218 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:219 | `#141627` |  |
| `design-system/figma-plugin/code.js`:222 | `#141627` |  |
| `design-system/figma-plugin/code.js`:223 | `#F3F3F3` |  |
| `design-system/figma-plugin/code.js`:223 | `#EC502C` |  |
| `design-system/figma-plugin/code.js`:224 | `#EC502C` |  |
| `design-system/figma-plugin/code.js`:231 | `#FFFFFF` |  |
| `design-system/figma-plugin/code.js`:231 | `#626577` |  |
| `design-system/figma-plugin/code.js`:232 | `#141627` |  |
| `design-system/figma-plugin/code.js`:235 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:235 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:236 | `#141627` |  |
| `design-system/figma-plugin/code.js`:239 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:240 | `#5A731A` |  |
| `design-system/figma-plugin/code.js`:242 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:243 | `#5A731A` |  |
| `design-system/figma-plugin/code.js`:246 | `#FFFFFF` |  |
| `design-system/figma-plugin/code.js`:246 | `#626577` |  |
| `design-system/figma-plugin/code.js`:247 | `#141627` |  |
| `design-system/figma-plugin/code.js`:254 | `#FFD365` |  |
| `design-system/figma-plugin/code.js`:255 | `#5A731A` |  |
| `design-system/figma-plugin/code.js`:256 | `#EC502C` |  |
| `design-system/figma-plugin/code.js`:257 | `#66D0F2` |  |
| `design-system/figma-plugin/code.js`:268 | `#5A731A` |  |
| `design-system/figma-plugin/code.js`:268 | `#5A731A` |  |
| `design-system/figma-plugin/code.js`:269 | `#5A731A` |  |
| `design-system/figma-plugin/code.js`:276 | `#FFFFFF` |  |
| `design-system/figma-plugin/code.js`:276 | `#DDDDDD` |  |
| `design-system/figma-plugin/code.js`:277 | `#0F172A` |  |
| `design-system/figma-plugin/code.js`:278 | `#141627` |  |
| `design-system/figma-plugin/code.js`:279 | `#626577` |  |
| `design-system/figma-plugin/code.js`:280 | `#9A9CAB` |  |
| `design-system/figma-plugin/code.js`:290 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:293 | `#5A731A` |  |
| `design-system/figma-plugin/code.js`:295 | `#5A731A` |  |
| `design-system/figma-plugin/code.js`:296 | `#9A9CAB` |  |
| `design-system/figma-plugin/code.js`:304 | `#DDDDDD` |  |
| `design-system/figma-plugin/code.js`:305 | `#FFFFFF` |  |
| `design-system/figma-plugin/code.js`:308 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:309 | `#FFFFFF` |  |
| `design-system/figma-plugin/code.js`:312 | `#141627` |  |
| `design-system/figma-plugin/code.js`:313 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:314 | `#FFFFFF` |  |
| `design-system/figma-plugin/code.js`:316 | `#141627` |  |
| `design-system/figma-plugin/code.js`:317 | `#DDDDDD` |  |
| `design-system/figma-plugin/code.js`:318 | `#FFFFFF` |  |
| `design-system/figma-plugin/code.js`:325 | `#626577` |  |
| `design-system/figma-plugin/code.js`:326 | `#141627` |  |
| `design-system/figma-plugin/code.js`:329 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:329 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:330 | `#141627` |  |
| `design-system/figma-plugin/code.js`:331 | `#141627` |  |
| `design-system/figma-plugin/code.js`:334 | `#DDDDDD` |  |
| `design-system/figma-plugin/code.js`:335 | `#9A9CAB` |  |
| `design-system/figma-plugin/code.js`:342 | `#626577` |  |
| `design-system/figma-plugin/code.js`:343 | `#141627` |  |
| `design-system/figma-plugin/code.js`:346 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:347 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:348 | `#141627` |  |
| `design-system/figma-plugin/code.js`:351 | `#DDDDDD` |  |
| `design-system/figma-plugin/code.js`:352 | `#9A9CAB` |  |
| `design-system/figma-plugin/code.js`:359 | `#141627` |  |
| `design-system/figma-plugin/code.js`:360 | `#F3F3F3` |  |
| `design-system/figma-plugin/code.js`:361 | `#9A9CAB` |  |
| `design-system/figma-plugin/code.js`:362 | `#626577` |  |
| `design-system/figma-plugin/code.js`:365 | `#141627` |  |
| `design-system/figma-plugin/code.js`:366 | `#F3F3F3` |  |
| `design-system/figma-plugin/code.js`:367 | `#141627` |  |
| `design-system/figma-plugin/code.js`:368 | `#626577` |  |
| `design-system/figma-plugin/code.js`:375 | `#DDDDDD` |  |
| `design-system/figma-plugin/code.js`:376 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:378 | `#FFFFFF` |  |
| `design-system/figma-plugin/code.js`:378 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:380 | `#141627` |  |
| `design-system/figma-plugin/code.js`:381 | `#9A9CAB` |  |
| `design-system/figma-plugin/code.js`:382 | `#141627` |  |
| `design-system/figma-plugin/code.js`:389 | `#DDDDDD` |  |
| `design-system/figma-plugin/code.js`:390 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:392 | `#FFFFFF` |  |
| `design-system/figma-plugin/code.js`:392 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:394 | `#FFFFFF` |  |
| `design-system/figma-plugin/code.js`:394 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:396 | `#141627` |  |
| `design-system/figma-plugin/code.js`:397 | `#9A9CAB` |  |
| `design-system/figma-plugin/code.js`:398 | `#141627` |  |
| `design-system/figma-plugin/code.js`:407 | `#F3F3F3` |  |
| `design-system/figma-plugin/code.js`:411 | `#FFFFFF` |  |
| `design-system/figma-plugin/code.js`:412 | `#141627` |  |
| `design-system/figma-plugin/code.js`:414 | `#9A9CAB` |  |
| `design-system/figma-plugin/code.js`:422 | `#FFFFFF` |  |
| `design-system/figma-plugin/code.js`:422 | `#DDDDDD` |  |
| `design-system/figma-plugin/code.js`:432 | `#141627` |  |
| `design-system/figma-plugin/code.js`:432 | `#9A9CAB` |  |
| `design-system/figma-plugin/code.js`:434 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:441 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:449 | `#FFFFFF` |  |
| `design-system/figma-plugin/code.js`:449 | `#DDDDDD` |  |
| `design-system/figma-plugin/code.js`:460 | `#141627` |  |
| `design-system/figma-plugin/code.js`:460 | `#9A9CAB` |  |
| `design-system/figma-plugin/code.js`:461 | `#141627` |  |
| `design-system/figma-plugin/code.js`:461 | `#9A9CAB` |  |
| `design-system/figma-plugin/code.js`:469 | `#5A731A` |  |
| `design-system/figma-plugin/code.js`:470 | `#EC502C` |  |
| `design-system/figma-plugin/code.js`:471 | `#66D0F2` |  |
| `design-system/figma-plugin/code.js`:475 | `#141627` |  |
| `design-system/figma-plugin/code.js`:477 | `#F9FAFB` |  |
| `design-system/figma-plugin/code.js`:496 | `#F3F3F3` |  |
| `design-system/figma-plugin/code.js`:497 | `#626577` |  |
| `design-system/figma-plugin/code.js`:586 | `#141627` |  |
| `design-system/figma-plugin/code.js`:587 | `#626577` |  |
| `design-system/figma-plugin/code.js`:588 | `#DDDDDD` |  |
| `design-system/figma-plugin/code.js`:589 | `#D1F366` |  |
| `design-system/figma-plugin/code.js`:632 | `#FFFFFF` |  |
| `design-system/figma-plugin/code.js`:637 | `#FFFFFF` |  |
| `design-system/figma-plugin/code.js`:662 | `#FFFFFF` |  |
| `design-system/figma-plugin/code.js`:665 | `#F8F8F8` |  |
| `lib/core/design_system/ds_segmented_control.dart`:26 | `#F1F5F9` |  |
