# Module: design-system/figma-plugin

Generates visual design system components, typography styles, and design tokens (light and dark mode colors, spacing, radius) inside Figma to match the DJTILBUD mobile Flutter widgets.

## Key files
- `design-system/figma-plugin/code.js`: Figma plugin script defining token constants and helper functions to render primitives and UI component mockups (such as buttons and component cards) on a Figma page.

## Public interface
- hex(h)
- hexA(h, a)
- rect(parent, w, h, x, y, fillColor, opts)
- ellipse(parent, w, h, x, y, fillColor, opts)
- text(parent, chars, size, weight, color, x, y, opts)
- frame(parent, w, h, x, y, fillColor, opts)
- sectionHeader(page, title, y)
- componentCard(page, title, subtitle, x, y, w, h)
- renderButton(card, cx, cy)
- LIGHT
- DARK
- SPACING
- RADIUS
- MOTION
- TEXT_STYLES

## Dependencies
- Figma Plugin API

## Open questions
- What additional component renderers and entry-point executions exist in the truncated portion of code.js?
- Does the plugin include a manifest.json or HTML UI file (e.g., ui.html) for user interaction?
