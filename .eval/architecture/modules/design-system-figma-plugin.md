# Module: design-system/figma-plugin

Provides a Figma generator plugin script to programmatically render the DJTilbud design system tokens (colors, typography, spacing, radius) and UI components (such as buttons, frames, and cards) in Figma to match the application's Flutter widgets.

## Key files
- `design-system/figma-plugin/code.js`: Defines light and dark design tokens, typography styles, Figma node creation helper functions, and component renderers for design system generation.

## Public interface
- LIGHT: Design token palette for light mode
- DARK: Design token palette for dark mode
- SPACING: Spacing scale constants
- RADIUS: Corner radius constants
- MOTION: Animation duration constants
- TEXT_STYLES: Typography style definitions
- hex(h: string): Object
- hexA(h: string, a: number): Object
- rect(parent, w, h, x, y, fillColor, opts): RectangleNode
- ellipse(parent, w, h, x, y, fillColor, opts): EllipseNode
- text(parent, chars, size, weight, color, x, y, opts): TextNode
- frame(parent, w, h, x, y, fillColor, opts): FrameNode
- sectionHeader(page, title, y): number
- componentCard(page, title, subtitle, x, y, w, h): FrameNode
- renderButton(card, cx, cy): void

## Dependencies
- Figma Plugin API (figma)

## Open questions
- How is the plugin manifest configured and which entry point executes the component rendering flow across Figma pages?
