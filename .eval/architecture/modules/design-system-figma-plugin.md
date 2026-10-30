# Module: design-system/figma-plugin

A Figma plugin script that programmatically generates visual mockups of the app's design system (color tokens, text styles, spacing, and UI components like buttons) inside Figma, intended to visually mirror the actual Flutter widgets used in the app.

## Key files
- `design-system/figma-plugin/code.js`: Main Figma plugin script defining design tokens (LIGHT/DARK color palettes, spacing, radius, motion, text styles) and helper functions (rect, ellipse, text, frame, sectionHeader, componentCard, renderButton) that draw design system elements onto a Figma page.

## Public interface
- _none_

## Dependencies
- Figma Plugin API (global `figma` object)

## Open questions
- The file is truncated after renderButton, so it's unclear what other components (e.g., job cards, quote cards, profile elements) are rendered by this script.
- No explicit plugin manifest (manifest.json) was provided, so how this script is loaded/invoked within Figma is not shown.
- It's unclear whether this generated design system output is used to keep the Flutter app in sync or is purely a documentation/reference artifact.
