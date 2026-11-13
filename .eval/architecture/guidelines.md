# Guidelines

Conventions backed by **≥2** real, verbatim code examples. Anything with fewer is omitted below.

## Design system widgets live in lib/core/design_system, are prefixed with `DS`, and extend StatelessWidget; feature code should compose these rather than raw Material widgets.

- `lib/core/design_system/ds_avatar.dart`:

  ```
  class DSAvatar extends StatelessWidget {
  ```

- `lib/core/design_system/ds_checkbox.dart`:

  ```
  class DSCheckbox extends StatelessWidget {
  ```

- `lib/core/design_system/ds_chip.dart`:

  ```
  class DSChip extends StatelessWidget {
  ```

- `lib/core/design_system/ds_dialog.dart`:

  ```
  class DSDialog extends StatelessWidget {
  ```

- `lib/core/design_system/ds_info_chip.dart`:

  ```
  class DSInfoChip extends StatelessWidget {
  ```

- `lib/core/design_system/ds_input.dart`:

  ```
  class DSInput extends StatelessWidget {
  ```

- `lib/core/design_system/ds_radio.dart`:

  ```
  class DSRadio extends StatelessWidget {
  ```

- `lib/core/design_system/ds_range_slider.dart`:

  ```
  class DSRangeSlider extends StatelessWidget {
  ```

- `lib/core/design_system/ds_segmented_control.dart`:

  ```
  class DSSegmentedControl extends StatelessWidget {
  ```

- `lib/core/design_system/ds_slider.dart`:

  ```
  class DSSlider extends StatelessWidget {
  ```

- `lib/core/design_system/ds_status_badge.dart`:

  ```
  class DSStatusBadge extends StatelessWidget {
  ```

- `lib/core/design_system/ds_surface.dart`:

  ```
  class DSSurface extends StatelessWidget {
  ```

## Widgets expose `const` constructors with named parameters (passing `super.key`) and sensible defaults so they can be used in const widget trees.

- `lib/core/design_system/ds_avatar.dart`:

  ```
  const DSAvatar({super.key, this.imageUrl, this.size = 40});
  ```

- `lib/core/design_system/ds_checkbox.dart`:

  ```
  const DSCheckbox({
  ```

- `lib/core/design_system/ds_chip.dart`:

  ```
  const DSChip({
  ```

- `lib/core/design_system/ds_dialog.dart`:

  ```
  const DSDialog({
  ```

- `lib/core/design_system/ds_info_chip.dart`:

  ```
  const DSInfoChip({
  ```

- `lib/core/design_system/ds_radio.dart`:

  ```
  const DSRadio({
  ```

- `lib/core/design_system/ds_range_slider.dart`:

  ```
  const DSRangeSlider({
  ```

- `lib/core/design_system/ds_segmented_control.dart`:

  ```
  const DSSegmentedControl({
  ```

- `lib/core/design_system/ds_slider.dart`:

  ```
  const DSSlider({
  ```

- `lib/core/design_system/ds_status_badge.dart`:

  ```
  const DSStatusBadge({
  ```

## Model visual variants, sizes and validation states as dedicated enums colocated with the widget instead of booleans or strings.

- `lib/core/design_system/ds_button.dart`:

  ```
  enum DSButtonVariant { primary, secondary, tertiary, ghost }
  ```

- `lib/core/design_system/ds_button.dart`:

  ```
  enum DSButtonSize { sm, md, lg }
  ```

- `lib/core/design_system/ds_input.dart`:

  ```
  enum DSInputState { normal, success, error }
  ```

## Expose the design system through a single barrel file (`components.dart`) that re-exports tokens and every component; import the barrel, not individual files.

- `lib/core/design_system/components.dart`:

  ```
  export 'tokens.dart';
  ```

- `lib/core/design_system/components.dart`:

  ```
  export 'ds_button.dart';
  ```

## Cross-cutting core services (analytics, environment config, role cache) are plain classes with static APIs rather than instantiated objects, keeping bootstrapping in main() simple.

- `lib/core/analytics/analytics_service.dart`:

  ```
  class AnalyticsService {
  ```

- `lib/core/config/env_config.dart`:

  ```
  class EnvConfig {
  ```

- `lib/core/config/role_cache.dart`:

  ```
  class RoleCache {
  ```

## App-level routing/auth/onboarding state uses small private ChangeNotifier classes in app.dart that GoRouter listens to for redirects.

- `lib/app.dart`:

  ```
  class _OnboardingNotifier extends ChangeNotifier {
  ```

- `lib/app.dart`:

  ```
  class _AuthNotifier extends ChangeNotifier {
  ```

## Small value/configuration classes (dropdown items, navigation items) are immutable with `const` constructors and `required` named fields.

- `lib/core/design_system/ds_dropdown.dart`:

  ```
  class DSDropdownItem<T> {
  ```

- `lib/core/design_system/ds_dropdown.dart`:

  ```
  const DSDropdownItem({required this.value, required this.label});
  ```

- `lib/core/design_system/ds_navigation_bar.dart`:

  ```
  class DSNavigationItem {
  ```

- `lib/core/design_system/ds_navigation_bar.dart`:

  ```
  const DSNavigationItem({
  ```

## The Figma plugin is written as compact plain-JS helper functions that convert design tokens into Figma primitives; keep token constants in sync with lib/core/design_system/tokens.dart.

- `design-system/figma-plugin/code.js`:

  ```
  function hex(h) {
  ```

- `design-system/figma-plugin/code.js`:

  ```
  const n = parseInt(h.replace('#',''), 16);
  ```
