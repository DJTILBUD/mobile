# Guidelines

Conventions backed by **≥2** real, verbatim code examples. Anything with fewer is omitted below.

## Design-system widgets are named with a 'DS' prefix, implemented as StatelessWidget subclasses in their own ds_*.dart file under lib/core/design_system.

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

## Widgets and value classes expose const constructors (with super.key for widgets) so they can be instantiated as compile-time constants.

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

- `lib/core/design_system/ds_dropdown.dart`:

  ```
  const DSDropdownItem({required this.value, required this.label});
  ```

- `lib/core/design_system/ds_info_chip.dart`:

  ```
  const DSInfoChip({
  ```

- `lib/core/design_system/ds_navigation_bar.dart`:

  ```
  const DSNavigationItem({
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

## Import design-system tokens and components through the single components.dart export barrel rather than individual files; add new DS files to the barrel.

- `lib/core/design_system/components.dart`:

  ```
  export 'tokens.dart';
  ```

- `lib/core/design_system/components.dart`:

  ```
  export 'ds_button.dart';
  ```

## Model widget variants, sizes and states as small Dart enums named after the owning component (e.g. DSButtonVariant, DSInputState) instead of booleans or strings.

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

## Simple configuration data for DS components (dropdown items, navigation items) are plain immutable classes paired with the widget, named DS<Component>Item.

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

## Router gating state (auth, onboarding) is held in private ChangeNotifier subclasses in app.dart used as GoRouter refresh listenables.

- `lib/app.dart`:

  ```
  class _OnboardingNotifier extends ChangeNotifier {
  ```

- `lib/app.dart`:

  ```
  class _AuthNotifier extends ChangeNotifier {
  ```
