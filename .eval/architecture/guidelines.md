# Guidelines

Conventions backed by **≥2** real, verbatim code examples. Anything with fewer is omitted below.

## Design-system widgets are DS-prefixed StatelessWidgets in lib/core/design_system, one widget per file. Build screens from these components rather than raw Material widgets.

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

## DS widgets expose const constructors with named parameters, so they can be instantiated as const where possible.

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

## Express widget variants, sizes, and states as small enums (e.g. primary/secondary, sm/md/lg, normal/success/error) rather than booleans or strings.

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

## Import design-system tokens and widgets through the single components.dart export barrel instead of importing individual DS files.

- `lib/core/design_system/components.dart`:

  ```
  export 'tokens.dart';
  ```

- `lib/core/design_system/components.dart`:

  ```
  export 'ds_button.dart';
  ```

## Model list and selection items for DS controls as small immutable data classes with const constructors and required fields (e.g. DSDropdownItem, DSNavigationItem).

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

## Expose app-wide services and config (analytics, env config, role cache, Firebase options) as dedicated classes under lib/core. Static-only holders such as EnvConfig use a private const constructor so they cannot be instantiated.

- `lib/firebase_options.dart`:

  ```
  class DefaultFirebaseOptions {
  ```

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

## Drive GoRouter redirect and refresh with private ChangeNotifier subclasses that hold global auth and onboarding state.

- `lib/app.dart`:

  ```
  class _OnboardingNotifier extends ChangeNotifier {
  ```

- `lib/app.dart`:

  ```
  class _AuthNotifier extends ChangeNotifier {
  ```
