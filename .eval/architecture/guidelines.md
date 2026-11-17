# Guidelines

Conventions backed by **≥2** real, verbatim code examples. Anything with fewer is omitted below.

## Design-system widgets live in lib/core/design_system, are prefixed with `DS`, and extend StatelessWidget; build new UI from these primitives rather than raw Material widgets so theming and tokens stay consistent across roles.

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

- `lib/core/design_system/ds_status_badge.dart`:

  ```
  class DSStatusBadge extends StatelessWidget {
  ```

- `lib/core/design_system/ds_surface.dart`:

  ```
  class DSSurface extends StatelessWidget {
  ```

## Give every widget a `const` constructor that forwards `super.key` and exposes configuration through named parameters with sensible defaults, so widgets can be used in const trees and are cheap to rebuild.

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

- `lib/core/design_system/ds_segmented_control.dart`:

  ```
  const DSSegmentedControl({
  ```

- `lib/core/design_system/ds_status_badge.dart`:

  ```
  const DSStatusBadge({
  ```

## Model finite UI variants, sizes and states as Dart enums (not strings or booleans) so switch statements over them are exhaustive and the showcase screen can enumerate them.

- `lib/core/design_system/ds_button.dart`:

  ```
  enum DSButtonVariant {
  ```

- `lib/core/design_system/ds_button.dart`:

  ```
  enum DSButtonSize { sm, md, lg }
  ```

- `lib/core/design_system/ds_input.dart`:

  ```
  enum DSInputState { normal, success, error }
  ```

## Import the design system only through the `components.dart` barrel file; add an `export` line there when creating a new DS widget or token file instead of deep-importing individual files from features.

- `lib/core/design_system/components.dart`:

  ```
  export 'tokens.dart';
  ```

- `lib/core/design_system/components.dart`:

  ```
  export 'ds_button.dart';
  ```

## App-wide infrastructure helpers (environment config, role cache, analytics) are static-only classes with a private constructor and static methods/getters; do not instantiate them or inject them, call them directly from features and keep platform SDK calls inside them.

- `lib/core/analytics/analytics_service.dart`:

  ```
  class AnalyticsService {
  ```

- `lib/core/config/env_config.dart`:

  ```
  class EnvConfig {
  ```

- `lib/core/config/env_config.dart`:

  ```
  const EnvConfig._();
  ```

- `lib/core/config/role_cache.dart`:

  ```
  class RoleCache {
  ```

## Root application state that must drive GoRouter redirects (auth session, onboarding completion) is implemented as private `ChangeNotifier`s in lib/app.dart that the router listens to; feature-level state should use Riverpod providers instead.

- `lib/app.dart`:

  ```
  class _OnboardingNotifier extends ChangeNotifier {
  ```

- `lib/app.dart`:

  ```
  class _AuthNotifier extends ChangeNotifier {
  ```

## Represent items passed into design-system collections (dropdown options, navigation destinations) as small immutable data classes with const constructors and required fields, generic over the value type where applicable, rather than maps or tuples.

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

## Keep design tokens as hex strings that are converted at the boundary (Figma `hex()` helper, Flutter `DSColors`); when changing a colour update both the Flutter tokens and the Figma plugin constants so the generated Figma file and the app do not drift.

- `design-system/figma-plugin/code.js`:

  ```
  function hex(h) {
  ```

- `design-system/figma-plugin/code.js`:

  ```
  const n = parseInt(h.replace('#',''), 16);
  ```

- `lib/core/design_system/components.dart`:

  ```
  export 'tokens.dart';
  ```
