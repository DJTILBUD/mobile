# Module: design-system/figma-plugin

A Figma generator plugin script (v2.0) that programmatically renders the DJTilbud design system design tokens (colors for light/dark themes, typography styles, spacing, radius, motion) and visual UI components (matching Flutter widgets) inside Figma.

## Key files
- `design-system/figma-plugin/code.js`: Figma plugin implementation defining design system constants (LIGHT, DARK, SPACING, RADIUS, MOTION, TEXT_STYLES), Figma node primitive helpers (rect, ellipse, text, frame), and visual component renderers.

## Public interface
- LIGHT: object containing light theme token hex color definitions
- DARK: object containing dark theme token hex color definitions
- SPACING: object defining spacing scale tokens
- RADIUS: object defining border-radius scale tokens
- MOTION: object defining animation duration tokens
- TEXT_STYLES: array of typographic style configurations
- hex(h: string): RGB
- hexA(h: string, a: number): RGBA
- rect(parent, w, h, x, y, fillColor, opts): RectangleNode
- ellipse(parent, w, h, x, y, fillColor, opts): EllipseNode
- text(parent, chars, size, weight, color, x, y, opts): TextNode
- frame(parent, w, h, x, y, fillColor, opts): FrameNode
- sectionHeader(page, title, y): number
- componentCard(page, title, subtitle, x, y, w, h): FrameNode
- renderButton(card, cx, cy): void

## Dependencies
- Figma Plugin API (figma global namespace)

## Open questions
- The full list of rendered components in code.js was truncated in the provided file snippet.
