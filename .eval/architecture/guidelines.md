# Guidelines

Conventions backed by **≥2** real, verbatim code examples. Anything with fewer is omitted below.

## Build design-system components as DS-prefixed StatelessWidgets with const constructors. Use named parameters, and give optional parameters sensible defaults.

- `lib/core/design_system/ds_avatar.dart`:

  ```
  class DSAvatar extends StatelessWidget {
  ```

- `lib/core/design_system/ds_avatar.dart`:

  ```
  const DSAvatar({super.key, this.imageUrl, this.size = 40});
  ```

- `lib/core/design_system/ds_checkbox.dart`:

  ```
  class DSCheckbox extends StatelessWidget {
  ```

- `lib/core/design_system/ds_checkbox.dart`:

  ```
  const DSCheckbox({
  ```

- `lib/core/design_system/ds_chip.dart`:

  ```
  class DSChip extends StatelessWidget {
  ```

- `lib/core/design_system/ds_chip.dart`:

  ```
  const DSChip({
  ```

- `lib/core/design_system/ds_dialog.dart`:

  ```
  class DSDialog extends StatelessWidget {
  ```

- `lib/core/design_system/ds_dialog.dart`:

  ```
  const DSDialog({
  ```

- `lib/core/design_system/ds_info_chip.dart`:

  ```
  class DSInfoChip extends StatelessWidget {
  ```

- `lib/core/design_system/ds_info_chip.dart`:

  ```
  const DSInfoChip({
  ```

- `lib/core/design_system/ds_radio.dart`:

  ```
  class DSRadio extends StatelessWidget {
  ```

- `lib/core/design_system/ds_radio.dart`:

  ```
  const DSRadio({
  ```

- `lib/core/design_system/ds_range_slider.dart`:

  ```
  class DSRangeSlider extends StatelessWidget {
  ```

- `lib/core/design_system/ds_range_slider.dart`:

  ```
  const DSRangeSlider({
  ```

- `lib/core/design_system/ds_segmented_control.dart`:

  ```
  class DSSegmentedControl extends StatelessWidget {
  ```

- `lib/core/design_system/ds_segmented_control.dart`:

  ```
  const DSSegmentedControl({
  ```

- `lib/core/design_system/ds_slider.dart`:

  ```
  class DSSlider extends StatelessWidget {
  ```

- `lib/core/design_system/ds_slider.dart`:

  ```
  const DSSlider({
  ```

- `lib/core/design_system/ds_status_badge.dart`:

  ```
  class DSStatusBadge extends StatelessWidget {
  ```

- `lib/core/design_system/ds_status_badge.dart`:

  ```
  const DSStatusBadge({
  ```

- `lib/core/design_system/ds_surface.dart`:

  ```
  class DSSurface extends StatelessWidget {
  ```

## Model component variants, sizes and visual states as small dedicated enums rather than booleans or strings.

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

## Pass items into DS list/selection widgets as lightweight immutable const data classes with required fields (e.g. DSDropdownItem, DSNavigationItem).

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

## Export every design-system token and widget through the single components.dart barrel, and import that barrel rather than individual DS files.

- `lib/core/design_system/components.dart`:

  ```
  export 'tokens.dart';
  ```

- `lib/core/design_system/components.dart`:

  ```
  export 'ds_button.dart';
  ```

## Expose app-wide configuration as a non-instantiable holder class with a private const constructor.

- `lib/core/config/env_config.dart`:

  ```
  class EnvConfig {
  ```

- `lib/core/config/env_config.dart`:

  ```
  const EnvConfig._();
  ```

## Drive router re-evaluation (auth and onboarding gating) through private ChangeNotifier subclasses in app.dart.

- `lib/app.dart`:

  ```
  class _OnboardingNotifier extends ChangeNotifier {
  ```

- `lib/app.dart`:

  ```
  class _AuthNotifier extends ChangeNotifier {
  ```
