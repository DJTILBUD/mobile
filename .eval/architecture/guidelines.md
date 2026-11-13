# Guidelines

Conventions backed by **≥2** real, verbatim code examples. Anything with fewer is omitted below.

## Design system widgets live in lib/core/design_system, carry the DS prefix, and are StatelessWidgets that read semantic tokens rather than hardcoding colors; prefer them over raw Material widgets in feature screens.

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

- `lib/core/design_system/ds_input.dart`:

  ```
  class DSInput extends StatelessWidget {
  ```

- `lib/core/design_system/ds_status_badge.dart`:

  ```
  class DSStatusBadge extends StatelessWidget {
  ```

- `lib/core/design_system/ds_surface.dart`:

  ```
  class DSSurface extends StatelessWidget {
  ```

## Give widgets and data classes const constructors with named parameters (super.key for widgets, required for mandatory fields, sensible defaults for the rest).

- `lib/core/design_system/ds_avatar.dart`:

  ```
  const DSAvatar({super.key, this.imageUrl, this.size = 40});
  ```

- `lib/core/design_system/ds_checkbox.dart`:

  ```
  const DSCheckbox({
  ```

- `lib/core/design_system/ds_dropdown.dart`:

  ```
  const DSDropdownItem({required this.value, required this.label});
  ```

- `lib/core/design_system/ds_navigation_bar.dart`:

  ```
  const DSNavigationItem({
  ```

- `lib/core/design_system/ds_status_badge.dart`:

  ```
  const DSStatusBadge({
  ```

## Model finite variants and states as small enums (e.g. button variant/size, input state) instead of booleans or strings so callers and the Figma mirror stay in sync.

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

## Expose the design system through the single components.dart barrel; features import that barrel instead of individual ds_*.dart files.

- `lib/core/design_system/components.dart`:

  ```
  export 'tokens.dart';
  ```

- `lib/core/design_system/components.dart`:

  ```
  export 'ds_button.dart';
  ```

## Cross-cutting services and caches (analytics, env config, role cache) are static-member classes with a private const constructor; never instantiate them, call the static API.

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

## Router refresh signals are driven by small private ChangeNotifier classes in app.dart (auth, onboarding) rather than rebuilding the router; add new gates the same way.

- `lib/app.dart`:

  ```
  class _OnboardingNotifier extends ChangeNotifier {
  ```

- `lib/app.dart`:

  ```
  class _AuthNotifier extends ChangeNotifier {
  ```

## Composite DS components take typed item/value objects (e.g. dropdown items, navigation items) rather than parallel lists, each defined as a const value class next to the widget.

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
