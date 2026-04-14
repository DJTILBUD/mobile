import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DesignSystemShowcase extends StatefulWidget {
  const DesignSystemShowcase({super.key});

  @override
  State<DesignSystemShowcase> createState() => _DesignSystemShowcaseState();
}

class _DesignSystemShowcaseState extends State<DesignSystemShowcase>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isDark = false;

  DSColors get c => _isDark ? darkColors : lightColors;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _buildTheme(),
      child: Scaffold(
        backgroundColor: c.bg.canvas,
        appBar: AppBar(
          backgroundColor: c.bg.surface,
          surfaceTintColor: c.bg.surface,
          leading: IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: c.text.primary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text('DJTILBUD', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.text.primary)),
          actions: [
            IconButton(
              icon: Icon(_isDark ? LucideIcons.sun : LucideIcons.moon, color: c.text.secondary),
              onPressed: () => setState(() => _isDark = !_isDark),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: c.text.primary,
            unselectedLabelColor: c.text.muted,
            indicatorColor: c.brand.primary,
            indicatorWeight: 2,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'Foundation'),
              Tab(text: 'Buttons'),
              Tab(text: 'Inputs'),
              Tab(text: 'Forms'),
              Tab(text: 'Controls'),
              Tab(text: 'Cards & Toasts'),
            ],
          ),
        ),
        body: DSTheme(
          colors: c,
          child: TabBarView(
            controller: _tabController,
            children: [
              _FoundationPage(c: c),
              _ButtonsPage(c: c),
              _InputsPage(c: c),
              _FormsPage(c: c),
              _ControlsPage(c: c),
              _CardsToastsPage(c: c),
            ],
          ),
        ),
      ),
    );
  }

  ThemeData _buildTheme() {
    final base = _isDark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: c.bg.canvas,
      appBarTheme: AppBarTheme(backgroundColor: c.bg.surface, foregroundColor: c.text.primary),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FOUNDATION PAGE — colors, typography, spacing, radius, shadows
// ═══════════════════════════════════════════════════════════════

class _FoundationPage extends StatelessWidget {
  const _FoundationPage({required this.c});
  final DSColors c;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(DSSpacing.s4),
      children: [
        _PageHeader(c: c, title: 'Foundation', subtitle: 'Color tokens, typography, spacing, radius, and shadows.'),

        // ── Colors ──────────────────────────────────────────────
        _SectionHeader(c: c, title: 'Colors', subtitle: 'Role-based semantic tokens — use these, never raw hex.'),
        const SizedBox(height: DSSpacing.s3),

        _ColorGroup(c: c, title: 'Brand', swatches: [
          (c.brand.primary, 'primary'),
          (c.brand.primaryHover, 'primaryHover'),
          (c.brand.primaryActive, 'primaryActive'),
          (c.brand.onPrimary, 'onPrimary'),
          (c.brand.accent, 'accent'),
          (c.brand.accentSoft, 'accentSoft'),
          (c.brand.onAccent, 'onAccent'),
        ]),
        const SizedBox(height: DSSpacing.s3),

        _ColorGroup(c: c, title: 'Background', swatches: [
          (c.bg.canvas, 'canvas'),
          (c.bg.surface, 'surface'),
          (c.bg.elevated, 'elevated'),
          (c.bg.inputBg, 'inputBg'),
          (c.bg.inputBgHover, 'inputBgHover'),
        ]),
        const SizedBox(height: DSSpacing.s3),

        _ColorGroup(c: c, title: 'Text', swatches: [
          (c.text.primary, 'primary'),
          (c.text.secondary, 'secondary'),
          (c.text.muted, 'muted'),
          (c.text.onDark, 'onDark'),
        ]),
        const SizedBox(height: DSSpacing.s3),

        _ColorGroup(c: c, title: 'State', swatches: [
          (c.state.success, 'success'),
          (c.state.warning, 'warning'),
          (c.state.danger, 'danger'),
          (c.state.info, 'info'),
        ]),
        const SizedBox(height: DSSpacing.s3),

        _ColorGroup(c: c, title: 'Border', swatches: [
          (c.border.subtle, 'subtle'),
          (c.border.strong, 'strong'),
        ]),
        const SizedBox(height: DSSpacing.s3),

        _ColorGroup(c: c, title: 'Trust & Availability', swatches: [
          (c.trust.verified, 'verified'),
          (c.trust.verifiedSoft, 'verifiedSoft'),
          (c.availability.available, 'available'),
          (c.availability.limited, 'limited'),
          (c.availability.unavailable, 'unavailable'),
        ]),
        const SizedBox(height: DSSpacing.s8),

        // ── Typography ──────────────────────────────────────────
        _SectionHeader(c: c, title: 'Typography', subtitle: 'Use DSTextStyle constants — no magic fontSize numbers.'),
        const SizedBox(height: DSSpacing.s3),
        DSSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _TypeRow(c: c, style: DSTextStyle.displayLg, name: 'displayLg', spec: '32 / bold'),
          _TypeRow(c: c, style: DSTextStyle.displayMd, name: 'displayMd', spec: '24 / bold'),
          const SizedBox(height: DSSpacing.s2),
          _TypeRow(c: c, style: DSTextStyle.headingLg, name: 'headingLg', spec: '20 / semibold'),
          _TypeRow(c: c, style: DSTextStyle.headingMd, name: 'headingMd', spec: '18 / semibold'),
          _TypeRow(c: c, style: DSTextStyle.headingSm, name: 'headingSm', spec: '16 / semibold'),
          const SizedBox(height: DSSpacing.s2),
          _TypeRow(c: c, style: DSTextStyle.bodyLg, name: 'bodyLg', spec: '16 / regular'),
          _TypeRow(c: c, style: DSTextStyle.bodyMd, name: 'bodyMd', spec: '14 / regular'),
          _TypeRow(c: c, style: DSTextStyle.bodySm, name: 'bodySm', spec: '12 / regular'),
          const SizedBox(height: DSSpacing.s2),
          _TypeRow(c: c, style: DSTextStyle.labelLg, name: 'labelLg', spec: '14 / medium'),
          _TypeRow(c: c, style: DSTextStyle.labelMd, name: 'labelMd', spec: '13 / medium'),
          _TypeRow(c: c, style: DSTextStyle.labelSm, name: 'labelSm', spec: '12 / medium'),
        ])),
        const SizedBox(height: DSSpacing.s8),

        // ── Spacing ─────────────────────────────────────────────
        _SectionHeader(c: c, title: 'Spacing', subtitle: 'DSSpacing.s* — 4pt base grid.'),
        const SizedBox(height: DSSpacing.s3),
        DSSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final (name, value) in [
            ('s1', DSSpacing.s1),
            ('s2', DSSpacing.s2),
            ('s3', DSSpacing.s3),
            ('s4', DSSpacing.s4),
            ('s6', DSSpacing.s6),
            ('s8', DSSpacing.s8),
            ('s12', DSSpacing.s12),
          ]) ...[
            Row(children: [
              SizedBox(
                width: 48,
                child: Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c.text.secondary)),
              ),
              Container(
                height: 20,
                width: value * 2,
                decoration: BoxDecoration(
                  color: c.brand.primary,
                  borderRadius: BorderRadius.circular(DSRadius.sm),
                ),
              ),
              const SizedBox(width: DSSpacing.s2),
              Text('${value.toInt()}px', style: TextStyle(fontSize: 12, color: c.text.muted)),
            ]),
            const SizedBox(height: DSSpacing.s2),
          ],
        ])),
        const SizedBox(height: DSSpacing.s8),

        // ── Radius ──────────────────────────────────────────────
        _SectionHeader(c: c, title: 'Radius', subtitle: 'DSRadius — corner rounding constants.'),
        const SizedBox(height: DSSpacing.s3),
        DSSurface(child: Row(children: [
          for (final (name, value) in [
            ('sm\n8px', DSRadius.sm),
            ('md\n12px', DSRadius.md),
            ('lg\n16px', DSRadius.lg),
            ('pill', DSRadius.pill),
          ]) ...[
            Expanded(child: Column(children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: c.brand.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(value),
                  border: Border.all(color: c.brand.primary),
                ),
              ),
              const SizedBox(height: DSSpacing.s2),
              Text(name, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: c.text.secondary)),
            ])),
          ],
        ])),
        const SizedBox(height: DSSpacing.s8),

        // ── Shadows ─────────────────────────────────────────────
        _SectionHeader(c: c, title: 'Shadows', subtitle: 'DSShadow.sm / DSShadow.md'),
        const SizedBox(height: DSSpacing.s3),
        Row(children: [
          Expanded(child: Column(children: [
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: c.bg.surface,
                borderRadius: BorderRadius.circular(DSRadius.lg),
                boxShadow: DSShadow.sm,
              ),
              child: Center(child: Text('DSShadow.sm', style: TextStyle(fontSize: 13, color: c.text.secondary))),
            ),
          ])),
          const SizedBox(width: DSSpacing.s4),
          Expanded(child: Column(children: [
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: c.bg.surface,
                borderRadius: BorderRadius.circular(DSRadius.lg),
                boxShadow: DSShadow.md,
              ),
              child: Center(child: Text('DSShadow.md', style: TextStyle(fontSize: 13, color: c.text.secondary))),
            ),
          ])),
        ]),
        const SizedBox(height: DSSpacing.s8),
      ],
    );
  }
}

class _ColorGroup extends StatelessWidget {
  const _ColorGroup({required this.c, required this.title, required this.swatches});
  final DSColors c;
  final String title;
  final List<(Color, String)> swatches;

  static String _hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    return DSSurface(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text.secondary, letterSpacing: 0.5)),
        const SizedBox(height: DSSpacing.s3),
        Wrap(
          spacing: DSSpacing.s2,
          runSpacing: DSSpacing.s2,
          children: swatches.map((s) {
            final (color, name) = s;
            final isDark = ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
            return Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 72,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(DSRadius.sm),
                  border: Border.all(color: c.border.subtle),
                ),
                child: Center(
                  child: Text(
                    _hex(color),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                width: 72,
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: c.text.muted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]);
          }).toList(),
        ),
      ]),
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({required this.c, required this.style, required this.name, required this.spec});
  final DSColors c;
  final TextStyle style;
  final String name;
  final String spec;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DSSpacing.s3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(child: Text('Aa', style: style.copyWith(color: c.text.primary))),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.brand.primaryActive)),
          Text(spec, style: TextStyle(fontSize: 10, color: c.text.muted)),
        ]),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BUTTONS PAGE
// ═══════════════════════════════════════════════════════════════

class _ButtonsPage extends StatefulWidget {
  const _ButtonsPage({required this.c});
  final DSColors c;

  @override
  State<_ButtonsPage> createState() => _ButtonsPageState();
}

class _ButtonsPageState extends State<_ButtonsPage> {
  DSColors get c => widget.c;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(DSSpacing.s4),
      children: [
        _PageHeader(c: c, title: 'Buttons', subtitle: 'Primary, Secondary, Tertiary, Ghost — default/hover/loading/disabled.'),

        // Button variants matrix
        DSSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _VariantLabels(c: c, labels: const ['Primary', 'Secondary', 'Tertiary', 'Ghost']),
              const SizedBox(height: DSSpacing.s4),

              // DEFAULT
              _RowLabel(c: c, label: 'DEFAULT'),
              const SizedBox(height: DSSpacing.s2),
              const Row(children: [
                Expanded(child: DSButton(label: 'Button', variant: DSButtonVariant.primary)),
                SizedBox(width: 6),
                Expanded(child: DSButton(label: 'Button', variant: DSButtonVariant.secondary)),
                SizedBox(width: 6),
                Expanded(child: DSButton(label: 'Button', variant: DSButtonVariant.tertiary)),
                SizedBox(width: 6),
                Expanded(child: DSButton(label: 'Button', variant: DSButtonVariant.ghost)),
              ]),
              const SizedBox(height: DSSpacing.s4),

              // LOADING
              _RowLabel(c: c, label: 'LOADING'),
              const SizedBox(height: DSSpacing.s2),
              const Row(children: [
                Expanded(child: DSButton(label: 'Button', variant: DSButtonVariant.primary, isLoading: true)),
                SizedBox(width: 6),
                Expanded(child: DSButton(label: 'Button', variant: DSButtonVariant.secondary, isLoading: true)),
                SizedBox(width: 6),
                Expanded(child: DSButton(label: 'Button', variant: DSButtonVariant.tertiary, isLoading: true)),
                SizedBox(width: 6),
                Expanded(child: DSButton(label: 'Button', variant: DSButtonVariant.ghost, isLoading: true)),
              ]),
              const SizedBox(height: DSSpacing.s4),

              // DISABLED
              _RowLabel(c: c, label: 'DISABLED'),
              const SizedBox(height: DSSpacing.s2),
              const Row(children: [
                Expanded(child: DSButton(label: 'Button', variant: DSButtonVariant.primary, enabled: false)),
                SizedBox(width: 6),
                Expanded(child: DSButton(label: 'Button', variant: DSButtonVariant.secondary, enabled: false)),
                SizedBox(width: 6),
                Expanded(child: DSButton(label: 'Button', variant: DSButtonVariant.tertiary, enabled: false)),
                SizedBox(width: 6),
                Expanded(child: DSButton(label: 'Button', variant: DSButtonVariant.ghost, enabled: false)),
              ]),
              const SizedBox(height: DSSpacing.s4),

              // WITH ICONS
              _RowLabel(c: c, label: 'WITH ICONS'),
              const SizedBox(height: DSSpacing.s2),
              const Row(children: [
                Expanded(child: DSButton(label: 'Save', variant: DSButtonVariant.primary, iconLeft: LucideIcons.check)),
                SizedBox(width: 6),
                Expanded(child: DSButton(label: 'Next', variant: DSButtonVariant.secondary, iconRight: LucideIcons.arrowRight)),
                SizedBox(width: 6),
                Expanded(child: DSButton(label: 'Edit', variant: DSButtonVariant.tertiary, iconLeft: LucideIcons.pencil)),
                SizedBox(width: 6),
                Expanded(child: DSButton(label: 'More', variant: DSButtonVariant.ghost, iconRight: LucideIcons.chevronDown)),
              ]),
              const SizedBox(height: DSSpacing.s4),

              // SIZES
              _RowLabel(c: c, label: 'SIZES'),
              const SizedBox(height: DSSpacing.s2),
              const Row(children: [
                Expanded(child: DSButton(label: 'Small', size: DSButtonSize.sm)),
                SizedBox(width: 6),
                Expanded(child: DSButton(label: 'Medium', size: DSButtonSize.md)),
                SizedBox(width: 6),
                Expanded(child: DSButton(label: 'Large', size: DSButtonSize.lg)),
              ]),
            ],
          ),
        ),
        const SizedBox(height: DSSpacing.s6),

        // Icon Buttons
        _SectionHeader(c: c, title: 'Icon Buttons', subtitle: 'Circular buttons for icon-only actions'),
        const SizedBox(height: DSSpacing.s2),
        DSSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _VariantLabels(c: c, labels: const ['Primary', 'Secondary', 'Tertiary', 'Ghost', 'Brand']),
              const SizedBox(height: DSSpacing.s4),

              _RowLabel(c: c, label: 'DEFAULT'),
              const SizedBox(height: DSSpacing.s2),
              const Row(children: [
                DSIconButton(icon: LucideIcons.play, variant: DSIconButtonVariant.primary),
                SizedBox(width: DSSpacing.s3),
                DSIconButton(icon: LucideIcons.play, variant: DSIconButtonVariant.secondary),
                SizedBox(width: DSSpacing.s3),
                DSIconButton(icon: LucideIcons.play, variant: DSIconButtonVariant.tertiary),
                SizedBox(width: DSSpacing.s3),
                DSIconButton(icon: LucideIcons.play, variant: DSIconButtonVariant.ghost),
                SizedBox(width: DSSpacing.s3),
                DSIconButton(icon: LucideIcons.play, variant: DSIconButtonVariant.brand),
              ]),
              const SizedBox(height: DSSpacing.s4),

              _RowLabel(c: c, label: 'SMALL'),
              const SizedBox(height: DSSpacing.s2),
              const Row(children: [
                DSIconButton(icon: LucideIcons.play, variant: DSIconButtonVariant.primary, size: DSButtonSize.sm),
                SizedBox(width: DSSpacing.s3),
                DSIconButton(icon: LucideIcons.play, variant: DSIconButtonVariant.secondary, size: DSButtonSize.sm),
                SizedBox(width: DSSpacing.s3),
                DSIconButton(icon: LucideIcons.play, variant: DSIconButtonVariant.tertiary, size: DSButtonSize.sm),
                SizedBox(width: DSSpacing.s3),
                DSIconButton(icon: LucideIcons.play, variant: DSIconButtonVariant.ghost, size: DSButtonSize.sm),
                SizedBox(width: DSSpacing.s3),
                DSIconButton(icon: LucideIcons.play, variant: DSIconButtonVariant.brand, size: DSButtonSize.sm),
              ]),
              const SizedBox(height: DSSpacing.s4),

              _RowLabel(c: c, label: 'LARGE'),
              const SizedBox(height: DSSpacing.s2),
              const Row(children: [
                DSIconButton(icon: LucideIcons.play, variant: DSIconButtonVariant.primary, size: DSButtonSize.lg),
                SizedBox(width: DSSpacing.s3),
                DSIconButton(icon: LucideIcons.play, variant: DSIconButtonVariant.secondary, size: DSButtonSize.lg),
                SizedBox(width: DSSpacing.s3),
                DSIconButton(icon: LucideIcons.play, variant: DSIconButtonVariant.tertiary, size: DSButtonSize.lg),
                SizedBox(width: DSSpacing.s3),
                DSIconButton(icon: LucideIcons.play, variant: DSIconButtonVariant.ghost, size: DSButtonSize.lg),
                SizedBox(width: DSSpacing.s3),
                DSIconButton(icon: LucideIcons.play, variant: DSIconButtonVariant.brand, size: DSButtonSize.lg),
              ]),
              const SizedBox(height: DSSpacing.s4),

              _RowLabel(c: c, label: 'DISABLED'),
              const SizedBox(height: DSSpacing.s2),
              const Row(children: [
                DSIconButton(icon: LucideIcons.play, variant: DSIconButtonVariant.primary, enabled: false),
                SizedBox(width: DSSpacing.s3),
                DSIconButton(icon: LucideIcons.play, variant: DSIconButtonVariant.secondary, enabled: false),
                SizedBox(width: DSSpacing.s3),
                DSIconButton(icon: LucideIcons.play, variant: DSIconButtonVariant.tertiary, enabled: false),
                SizedBox(width: DSSpacing.s3),
                DSIconButton(icon: LucideIcons.play, variant: DSIconButtonVariant.ghost, enabled: false),
                SizedBox(width: DSSpacing.s3),
                DSIconButton(icon: LucideIcons.play, variant: DSIconButtonVariant.brand, enabled: false),
              ]),
            ],
          ),
        ),
        const SizedBox(height: DSSpacing.s6),

        // Dialog
        _SectionHeader(c: c, title: 'Dialog Examples', subtitle: 'Modals triggered by buttons'),
        const SizedBox(height: DSSpacing.s2),
        Row(children: [
          Expanded(child: DSSurface(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Single Action', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text.primary)),
              const SizedBox(height: DSSpacing.s3),
              DSButton(label: 'Open Dialog', variant: DSButtonVariant.primary, onTap: () => _showDialog(context, singleAction: true)),
            ],
          ))),
          const SizedBox(width: DSSpacing.s3),
          Expanded(child: DSSurface(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Two Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text.primary)),
              const SizedBox(height: DSSpacing.s3),
              DSButton(label: 'Open', variant: DSButtonVariant.secondary, onTap: () => _showDialog(context, singleAction: false)),
            ],
          ))),
        ]),
        const SizedBox(height: DSSpacing.s8),
      ],
    );
  }

  void _showDialog(BuildContext context, {required bool singleAction}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: c.bg.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DSRadius.lg),
          side: BorderSide(color: c.border.subtle),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DSSpacing.s6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                singleAction ? 'Welcome to DJTILBUD' : 'Confirm Your Booking',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: c.text.primary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: DSSpacing.s2),
              // Description
              Text(
                singleAction
                    ? 'Find the perfect musician for your event. Browse our marketplace of verified DJs, saxophonists, violinists, and bands.'
                    : 'Are you sure you want to book this musician? A confirmation email will be sent to both parties.',
                style: TextStyle(
                  fontSize: 15,
                  color: c.text.secondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: DSSpacing.s6),
              // Action buttons — web: single = full-width; two = side-by-side flex row
              if (singleAction)
                DSButton(
                  label: 'Get Started',
                  variant: DSButtonVariant.primary,
                  expand: true,
                  onTap: () => Navigator.of(ctx).pop(),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: DSButton(
                        label: 'Cancel',
                        variant: DSButtonVariant.tertiary,
                        expand: true,
                        onTap: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                    const SizedBox(width: DSSpacing.s3),
                    Expanded(
                      child: DSButton(
                        label: 'Confirm Booking',
                        variant: DSButtonVariant.primary,
                        expand: true,
                        onTap: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// INPUTS PAGE
// ═══════════════════════════════════════════════════════════════

class _InputsPage extends StatelessWidget {
  const _InputsPage({required this.c});
  final DSColors c;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(DSSpacing.s4),
      children: [
        _PageHeader(c: c, title: 'Inputs', subtitle: 'Text fields with labels, icons, states, and validation feedback.'),

        DSSurface(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RowLabel(c: c, label: 'BASIC'),
            const SizedBox(height: DSSpacing.s3),
            const DSInput(hint: 'Enter text...'),
            const SizedBox(height: DSSpacing.s3),
            const DSInput(label: 'Email', hint: 'you@example.com'),
            const SizedBox(height: DSSpacing.s3),
            const DSInput(label: 'With helper text', hint: 'Username', helperText: 'Choose a unique username'),
            const SizedBox(height: DSSpacing.s6),

            _RowLabel(c: c, label: 'WITH ICONS'),
            const SizedBox(height: DSSpacing.s3),
            const DSInput(label: 'Search', hint: 'Search musicians...', iconLeft: LucideIcons.search),
            const SizedBox(height: DSSpacing.s3),
            const DSInput(label: 'Email', hint: 'you@example.com', iconLeft: LucideIcons.mail),
            const SizedBox(height: DSSpacing.s3),
            const DSInput(hint: 'With both icons', iconLeft: LucideIcons.search, iconRight: LucideIcons.check, state: DSInputState.success),
            const SizedBox(height: DSSpacing.s6),

            _RowLabel(c: c, label: 'STATES - SUCCESS'),
            const SizedBox(height: DSSpacing.s3),
            DSInput(
              label: 'Valid email',
              hint: 'you@example.com',
              helperText: 'Email is available',
              state: DSInputState.success,
              iconRight: LucideIcons.check,
              controller: TextEditingController(text: 'john@example.com'),
            ),
            const SizedBox(height: DSSpacing.s6),

            _RowLabel(c: c, label: 'STATES - ERROR'),
            const SizedBox(height: DSSpacing.s3),
            DSInput(
              label: 'Invalid email',
              hint: 'you@example.com',
              errorText: 'This email is already taken',
              state: DSInputState.error,
              iconRight: LucideIcons.alertCircle,
              controller: TextEditingController(text: 'admin@example.com'),
            ),
            const SizedBox(height: DSSpacing.s6),

            _RowLabel(c: c, label: 'LOADING'),
            const SizedBox(height: DSSpacing.s3),
            DSInput(
              label: 'Checking availability',
              hint: 'Username',
              helperText: 'Verifying username...',
              isLoading: true,
              controller: TextEditingController(text: 'johndoe'),
            ),
            const SizedBox(height: DSSpacing.s6),

            _RowLabel(c: c, label: 'DISABLED'),
            const SizedBox(height: DSSpacing.s3),
            DSInput(
              label: 'Disabled field',
              hint: "Can't edit this",
              enabled: false,
              controller: TextEditingController(text: 'Locked value'),
            ),
            const SizedBox(height: DSSpacing.s6),

            _RowLabel(c: c, label: 'WITH CHARACTER COUNTER'),
            const SizedBox(height: DSSpacing.s3),
            const DSInput(label: 'Bio', hint: 'Tell us about yourself...', helperText: 'Brief description for your profile', maxLength: 150, showCounter: true),
            const SizedBox(height: DSSpacing.s3),
            DSInput(
              label: 'Headline',
              hint: 'Your tagline',
              maxLength: 60,
              showCounter: true,
              state: DSInputState.success,
              controller: TextEditingController(text: 'Professional DJ & Music Producer'),
            ),
            const SizedBox(height: DSSpacing.s6),

            _RowLabel(c: c, label: 'INPUT TYPES'),
            const SizedBox(height: DSSpacing.s3),
            const DSInput(label: 'Password', hint: 'Enter password', obscureText: true),
            const SizedBox(height: DSSpacing.s3),
            DSInput(label: 'Number', hint: 'Price', keyboardType: TextInputType.number, controller: TextEditingController(text: '5000')),
          ],
        )),
        const SizedBox(height: DSSpacing.s8),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FORMS PAGE (Radio + Checkbox)
// ═══════════════════════════════════════════════════════════════

class _FormsPage extends StatefulWidget {
  const _FormsPage({required this.c});
  final DSColors c;

  @override
  State<_FormsPage> createState() => _FormsPageState();
}

class _FormsPageState extends State<_FormsPage> {
  DSColors get c => widget.c;
  String _selectedRadio = 'option1';
  final _checks = {'email': true, 'sms': false, 'push': false};

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(DSSpacing.s4),
      children: [
        _PageHeader(c: c, title: 'Forms', subtitle: 'Radio buttons and checkboxes with warm backstage styling.'),

        // Radio Buttons
        _SectionHeader(c: c, title: 'Radio Buttons', subtitle: 'Single selection from a group of options.'),
        const SizedBox(height: DSSpacing.s3),

        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: DSSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Basic', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text.primary)),
            const SizedBox(height: DSSpacing.s3),
            DSRadio(label: 'First option', value: 'option1', groupValue: _selectedRadio, onChanged: (v) => setState(() => _selectedRadio = v)),
            DSRadio(label: 'Second option', value: 'option2', groupValue: _selectedRadio, onChanged: (v) => setState(() => _selectedRadio = v)),
            DSRadio(label: 'Third option', value: 'option3', groupValue: _selectedRadio, onChanged: (v) => setState(() => _selectedRadio = v)),
          ]))),
          const SizedBox(width: DSSpacing.s3),
          Expanded(child: DSSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('With Hints', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text.primary)),
            const SizedBox(height: DSSpacing.s3),
            DSRadio(label: 'Basic Plan', hint: 'Free forever, perfect for getting started', value: 'basic', groupValue: _selectedRadio, onChanged: (v) => setState(() => _selectedRadio = v)),
            DSRadio(label: 'Pro Plan', hint: '\$29/month with advanced features', value: 'pro', groupValue: _selectedRadio, onChanged: (v) => setState(() => _selectedRadio = v)),
            DSRadio(label: 'Enterprise Plan', hint: 'Custom pricing for large teams', value: 'enterprise', groupValue: _selectedRadio, onChanged: (v) => setState(() => _selectedRadio = v)),
          ]))),
        ]),
        const SizedBox(height: DSSpacing.s3),
        DSSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Disabled', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text.primary)),
          const SizedBox(height: DSSpacing.s3),
          const DSRadio(label: 'Active option', value: 'a', groupValue: '', onChanged: null),
          const DSRadio(label: 'Disabled option', value: 'b', groupValue: '', onChanged: null, disabled: true),
          const DSRadio(label: 'Disabled & selected', hint: "Can't change this selection", value: 'c', groupValue: 'c', onChanged: null, disabled: true),
        ])),
        const SizedBox(height: DSSpacing.s6),

        // Checkboxes
        _SectionHeader(c: c, title: 'Checkboxes', subtitle: 'Multiple selections from a group of options.'),
        const SizedBox(height: DSSpacing.s3),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: DSSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Basic', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text.primary)),
            const SizedBox(height: DSSpacing.s3),
            DSCheckbox(label: 'Email notifications', value: _checks['email']!, onChanged: (v) => setState(() => _checks['email'] = v)),
            DSCheckbox(label: 'SMS notifications', value: _checks['sms']!, onChanged: (v) => setState(() => _checks['sms'] = v)),
            DSCheckbox(label: 'Push notifications', value: _checks['push']!, onChanged: (v) => setState(() => _checks['push'] = v)),
          ]))),
          const SizedBox(width: DSSpacing.s3),
          Expanded(child: DSSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('With Hints', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text.primary)),
            const SizedBox(height: DSSpacing.s3),
            DSCheckbox(label: 'Marketing emails', hint: 'Receive updates about new features', value: true, onChanged: (_) {}),
            DSCheckbox(label: 'Product updates', hint: 'Important announcements', value: false, onChanged: (_) {}),
            DSCheckbox(label: 'Event invitations', hint: 'Get notified about upcoming events', value: true, onChanged: (_) {}),
          ]))),
        ]),
        const SizedBox(height: DSSpacing.s3),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: DSSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Disabled', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text.primary)),
            const SizedBox(height: DSSpacing.s3),
            DSCheckbox(label: 'Disabled unchecked', value: false, disabled: true, onChanged: (_) {}),
            DSCheckbox(label: 'Disabled & checked', hint: 'This setting is required', value: true, disabled: true, onChanged: (_) {}),
          ]))),
          const SizedBox(width: DSSpacing.s3),
          Expanded(child: DSSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('All States', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text.primary)),
            const SizedBox(height: DSSpacing.s3),
            DSCheckbox(label: 'Unchecked', value: false, onChanged: (_) {}),
            DSCheckbox(label: 'Checked', value: true, onChanged: (_) {}),
            DSCheckbox(label: 'Disabled unchecked', value: false, disabled: true, onChanged: (_) {}),
            DSCheckbox(label: 'Disabled checked', value: true, disabled: true, onChanged: (_) {}),
          ]))),
        ]),
        const SizedBox(height: DSSpacing.s8),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CONTROLS PAGE (Segmented + Slider + Switch + Section Titles)
// ═══════════════════════════════════════════════════════════════

class _ControlsPage extends StatefulWidget {
  const _ControlsPage({required this.c});
  final DSColors c;

  @override
  State<_ControlsPage> createState() => _ControlsPageState();
}

class _ControlsPageState extends State<_ControlsPage> {
  DSColors get c => widget.c;
  int _seg1 = 0;
  int _seg2 = 0;
  double _slider1 = 50;
  double _slider2 = 300;
  bool _switch1 = true;
  bool _switch2 = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(DSSpacing.s4),
      children: [
        _PageHeader(c: c, title: 'Controls', subtitle: 'Segmented controls, sliders, switches, and section titles.'),

        // Section Titles
        _SectionHeader(c: c, title: 'Section Titles', subtitle: 'Heading components for organizing content sections.'),
        const SizedBox(height: DSSpacing.s3),
        DSSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Large with Subtitle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text.primary)),
          const SizedBox(height: DSSpacing.s3),
          Text('Available Musicians', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.text.primary)),
          const SizedBox(height: 2),
          Text('This is a subtitle explaining more about this section', style: TextStyle(fontSize: 14, color: c.text.muted)),
        ])),
        const SizedBox(height: DSSpacing.s3),
        DSSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Tones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text.primary)),
          const SizedBox(height: DSSpacing.s3),
          Text('Default Tone', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.text.primary)),
          const SizedBox(height: DSSpacing.s2),
          Text('Muted Tone', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.text.muted)),
          const SizedBox(height: DSSpacing.s2),
          Text('Accent Tone', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.brand.accent)),
        ])),
        const SizedBox(height: DSSpacing.s6),

        // Segmented Control
        _SectionHeader(c: c, title: 'Segmented Control', subtitle: 'Tab-like controls for switching between views.'),
        const SizedBox(height: DSSpacing.s3),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: DSSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Two Options', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text.primary)),
            const SizedBox(height: DSSpacing.s3),
            DSSegmentedControl(labels: const ['First', 'Second'], selected: _seg1, onChanged: (i) => setState(() => _seg1 = i)),
            const SizedBox(height: DSSpacing.s2),
            Text('Selected: ${_seg1 == 0 ? "First" : "Second"}', style: TextStyle(fontSize: 13, color: c.text.muted)),
          ]))),
          const SizedBox(width: DSSpacing.s3),
          Expanded(child: DSSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Three Options', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text.primary)),
            const SizedBox(height: DSSpacing.s3),
            DSSegmentedControl(labels: const ['Day', 'Week', 'Month'], selected: _seg2, onChanged: (i) => setState(() => _seg2 = i)),
            const SizedBox(height: DSSpacing.s2),
            Text('Selected: ${['Day', 'Week', 'Month'][_seg2]}', style: TextStyle(fontSize: 13, color: c.text.muted)),
          ]))),
        ]),
        const SizedBox(height: DSSpacing.s6),

        // Sliders
        _SectionHeader(c: c, title: 'Slider', subtitle: 'Range input for selecting numeric values.'),
        const SizedBox(height: DSSpacing.s3),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: DSSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Basic', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text.primary)),
            const SizedBox(height: DSSpacing.s3),
            DSSlider(label: 'Volume', value: _slider1, onChanged: (v) => setState(() => _slider1 = v)),
            Text('Value: ${_slider1.toInt()}', style: TextStyle(fontSize: 13, color: c.text.muted)),
          ]))),
          const SizedBox(width: DSSpacing.s3),
          Expanded(child: DSSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Price Range', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text.primary)),
            const SizedBox(height: DSSpacing.s3),
            DSSlider(label: 'Max Price (DKK)', value: _slider2, max: 1000, divisions: 20, onChanged: (v) => setState(() => _slider2 = v)),
            Text('Max: ${_slider2.toInt()} DKK', style: TextStyle(fontSize: 13, color: c.text.muted)),
          ]))),
        ]),
        const SizedBox(height: DSSpacing.s3),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: DSSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Without Label', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text.primary)),
            const SizedBox(height: DSSpacing.s3),
            const DSSlider(value: 5, max: 10),
          ]))),
          const SizedBox(width: DSSpacing.s3),
          Expanded(child: DSSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Disabled', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text.primary)),
            const SizedBox(height: DSSpacing.s3),
            const DSSlider(label: 'Unavailable', value: 75),
          ]))),
        ]),
        const SizedBox(height: DSSpacing.s6),

        // Switches
        _SectionHeader(c: c, title: 'Switch', subtitle: 'Toggle controls for boolean settings.'),
        const SizedBox(height: DSSpacing.s3),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: DSSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Basic', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text.primary)),
            const SizedBox(height: DSSpacing.s3),
            DSSwitch(label: 'Email notifications', value: _switch1, onChanged: (v) => setState(() => _switch1 = v)),
            DSSwitch(label: 'Push notifications', value: _switch2, onChanged: (v) => setState(() => _switch2 = v)),
          ]))),
          const SizedBox(width: DSSpacing.s3),
          Expanded(child: DSSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Disabled', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text.primary)),
            const SizedBox(height: DSSpacing.s3),
            const DSSwitch(label: 'Disabled (On)', value: true, onChanged: null),
            const DSSwitch(label: 'Disabled (Off)', value: false, onChanged: null),
          ]))),
        ]),
        const SizedBox(height: DSSpacing.s8),

        // ── Info Chips ──────────────────────────────────────────
        _SectionHeader(c: c, title: 'Info Chip', subtitle: 'Read-only metadata chip — icon + label. Use highlight for primary metrics.'),
        const SizedBox(height: DSSpacing.s3),
        DSSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _RowLabel(c: c, label: 'DEFAULT'),
          const SizedBox(height: DSSpacing.s2),
          Wrap(spacing: DSSpacing.s2, runSpacing: DSSpacing.s2, children: const [
            DSInfoChip(icon: LucideIcons.users, label: '120 gæster'),
            DSInfoChip(icon: LucideIcons.clock, label: '19:00–02:00'),
            DSInfoChip(icon: LucideIcons.mapPin, label: 'København'),
            DSInfoChip(icon: LucideIcons.banknote, label: '8.000–12.000 kr.'),
          ]),
          const SizedBox(height: DSSpacing.s4),
          _RowLabel(c: c, label: 'HIGHLIGHT (primary metric)'),
          const SizedBox(height: DSSpacing.s2),
          Wrap(spacing: DSSpacing.s2, runSpacing: DSSpacing.s2, children: const [
            DSInfoChip(icon: LucideIcons.banknote, label: '4.500 kr.', highlight: true),
            DSInfoChip(icon: LucideIcons.users, label: '80 gæster'),
          ]),
          const SizedBox(height: DSSpacing.s4),
          _RowLabel(c: c, label: 'WITHOUT ICON'),
          const SizedBox(height: DSSpacing.s2),
          const Wrap(spacing: DSSpacing.s2, children: [
            DSInfoChip(label: 'Bryllup'),
            DSInfoChip(label: 'Firmafest'),
          ]),
        ])),
        const SizedBox(height: DSSpacing.s6),

        // ── Status Badges ───────────────────────────────────────
        _SectionHeader(c: c, title: 'Status Badge', subtitle: 'Colored pill with tinted bg — for offer/quote statuses.'),
        const SizedBox(height: DSSpacing.s3),
        DSSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _RowLabel(c: c, label: 'INLINE STATUSES'),
          const SizedBox(height: DSSpacing.s2),
          Wrap(spacing: DSSpacing.s2, runSpacing: DSSpacing.s2, children: [
            DSStatusBadge(label: 'Afventer', color: c.state.warning),
            DSStatusBadge(label: 'Vundet', color: c.state.success),
            DSStatusBadge(label: 'Tabt', color: c.text.muted),
            DSStatusBadge(label: 'Saxofonist søges', color: c.state.info),
            DSStatusBadge(label: 'Kan bydes igen', color: c.state.warning),
          ]),
          const SizedBox(height: DSSpacing.s4),
          _RowLabel(c: c, label: 'EXPAND (full-width banner)'),
          const SizedBox(height: DSSpacing.s2),
          DSStatusBadge(label: 'Aftale bekræftet', color: c.state.success, expand: true),
          const SizedBox(height: DSSpacing.s2),
          DSStatusBadge(label: 'Afventer kundens bekræftelse', color: c.state.warning, expand: true),
        ])),
        const SizedBox(height: DSSpacing.s6),

        // ── Tinted Chips (genre tags) ────────────────────────────
        _SectionHeader(c: c, title: 'Chip — tinted mode', subtitle: 'Read-only genre/taxonomy tags. DSChip(tinted: true).'),
        const SizedBox(height: DSSpacing.s3),
        DSSurface(child: Wrap(spacing: DSSpacing.s2, runSpacing: DSSpacing.s2, children: const [
          DSChip(label: 'House', tinted: true),
          DSChip(label: 'Pop', tinted: true),
          DSChip(label: 'R&B', tinted: true),
          DSChip(label: 'Jazz', tinted: true),
          DSChip(label: 'Latin', tinted: true),
          DSChip(label: 'Top 40', tinted: true),
        ])),
        const SizedBox(height: DSSpacing.s8),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CARDS & TOASTS PAGE
// ═══════════════════════════════════════════════════════════════

class _CardsToastsPage extends StatelessWidget {
  const _CardsToastsPage({required this.c});
  final DSColors c;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(DSSpacing.s4),
      children: [
        _PageHeader(c: c, title: 'Cards & Toasts', subtitle: 'Musician listing cards and notification toasts for user feedback.'),

        // Cards
        _SectionHeader(c: c, title: 'Cards', subtitle: 'Airbnb-style cards for showcasing musicians.'),
        const SizedBox(height: DSSpacing.s3),
        Text('Musician Listings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text.primary)),
        const SizedBox(height: DSSpacing.s3),

        SizedBox(
          height: 280,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _MusicianCard(c: c, emoji: '🎧', gradientStart: const Color(0xFF8B5CF6), gradientEnd: const Color(0xFFEC4899), name: 'DJ Alex Jensen', role: 'DJ', desc: 'Professional DJ with 10+ years experience in weddings and festivals.', price: '2,500 DKK / event', rating: 4.9, reviews: 127, badge: 'Verified', badgeColor: c.trust.verified, badgeBg: c.trust.verifiedSoft),
              const SizedBox(width: DSSpacing.s3),
              _MusicianCard(c: c, emoji: '🎷', gradientStart: const Color(0xFFF59E0B), gradientEnd: const Color(0xFFF97316), name: 'Sarah Andersen', role: 'Saxophonist', desc: 'Jazz and classical saxophonist for intimate events.', price: '1,800 DKK / event', rating: 5.0, reviews: 89, badge: 'Top Rated', badgeColor: c.state.warning, badgeBg: c.state.warning.withValues(alpha: 0.15)),
              const SizedBox(width: DSSpacing.s3),
              _MusicianCard(c: c, emoji: '🎻', gradientStart: const Color(0xFF3B82F6), gradientEnd: const Color(0xFF6366F1), name: 'Marcus Nielsen', role: 'Violinist', desc: 'Classical and contemporary violinist for weddings.', price: '2,000 DKK / event', rating: 4.8, reviews: 64, badge: 'New', badgeColor: c.state.info, badgeBg: c.state.info.withValues(alpha: 0.15)),
            ],
          ),
        ),
        const SizedBox(height: DSSpacing.s6),

        // Variations
        Text('Variations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text.primary)),
        const SizedBox(height: DSSpacing.s3),
        DSSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('The Jazz Quartet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.text.primary)),
          const SizedBox(height: 2),
          Text('Band', style: TextStyle(fontSize: 13, color: c.text.muted)),
          const SizedBox(height: DSSpacing.s2),
          Text('Four-piece jazz ensemble perfect for upscale events and corporate functions.', style: TextStyle(fontSize: 14, color: c.text.secondary)),
          const SizedBox(height: DSSpacing.s3),
          Row(children: [
            Icon(LucideIcons.star, size: 14, color: c.state.warning),
            const SizedBox(width: 3),
            Text('4.7', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text.primary)),
            Text(' (42)', style: TextStyle(fontSize: 13, color: c.text.muted)),
            const Spacer(),
            Text('5,000 DKK / event', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text.primary)),
          ]),
        ])),
        const SizedBox(height: DSSpacing.s6),

        // Toasts
        _SectionHeader(c: c, title: 'Toasts', subtitle: 'Notification toasts for user feedback.'),
        const SizedBox(height: DSSpacing.s3),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(children: [
            DSSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Success', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text.primary)),
              const SizedBox(height: DSSpacing.s3),
              DSButton(label: 'Show Toast', variant: DSButtonVariant.primary, onTap: () => DSToast.show(context, variant: DSToastVariant.success, title: 'Booking confirmed!', description: 'Your musician has been booked.')),
            ])),
            const SizedBox(height: DSSpacing.s3),
            DSSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Warning', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text.primary)),
              const SizedBox(height: DSSpacing.s3),
              DSButton(label: 'Show Toast', variant: DSButtonVariant.tertiary, onTap: () => DSToast.show(context, variant: DSToastVariant.warning, title: 'Limited availability', description: 'Only 2 dates left in December.')),
            ])),
          ])),
          const SizedBox(width: DSSpacing.s3),
          Expanded(child: Column(children: [
            DSSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text.primary)),
              const SizedBox(height: DSSpacing.s3),
              DSButton(label: 'Show Toast', variant: DSButtonVariant.secondary, onTap: () => DSToast.show(context, variant: DSToastVariant.info, title: 'New message received', description: 'DJ Alex Jensen sent you a message.')),
            ])),
            const SizedBox(height: DSSpacing.s3),
            DSSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Error', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text.primary)),
              const SizedBox(height: DSSpacing.s3),
              DSButton(label: 'Show Toast', variant: DSButtonVariant.ghost, onTap: () => DSToast.show(context, variant: DSToastVariant.error, title: 'Booking failed', description: 'Unable to process your request.')),
            ])),
          ])),
        ]),
        const SizedBox(height: DSSpacing.s8),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SHOWCASE-ONLY LAYOUT HELPERS (private, not reusable)
// ═══════════════════════════════════════════════════════════════

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.c, required this.title, required this.subtitle});
  final DSColors c;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DSSpacing.s4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: c.text.primary)),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(fontSize: 14, color: c.text.muted)),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.c, required this.title, required this.subtitle});
  final DSColors c;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c.text.primary)),
      const SizedBox(height: 2),
      Text(subtitle, style: TextStyle(fontSize: 14, color: c.text.secondary)),
    ]);
  }
}

class _RowLabel extends StatelessWidget {
  const _RowLabel({required this.c, required this.label});
  final DSColors c;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 1, color: c.text.muted));
  }
}

class _VariantLabels extends StatelessWidget {
  const _VariantLabels({required this.c, required this.labels});
  final DSColors c;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(children: labels.map((l) => Expanded(child: Text(l, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c.text.secondary)))).toList());
  }
}

// Musician Card (showcase-specific, complex layout)
class _MusicianCard extends StatelessWidget {
  const _MusicianCard({required this.c, required this.emoji, required this.gradientStart, required this.gradientEnd, required this.name, required this.role, required this.desc, required this.price, required this.rating, required this.reviews, required this.badge, required this.badgeColor, required this.badgeBg});
  final DSColors c;
  final String emoji;
  final Color gradientStart;
  final Color gradientEnd;
  final String name;
  final String role;
  final String desc;
  final String price;
  final double rating;
  final int reviews;
  final String badge;
  final Color badgeColor;
  final Color badgeBg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: c.bg.surface,
        borderRadius: BorderRadius.circular(DSRadius.lg),
        border: Border.all(color: c.border.subtle),
        boxShadow: DSShadow.sm,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          height: 120,
          decoration: BoxDecoration(gradient: LinearGradient(colors: [gradientStart, gradientEnd], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: Stack(children: [
            Center(child: Text(emoji, style: const TextStyle(fontSize: 48))),
            Positioned(top: 8, left: 8, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(DSRadius.pill)),
              child: Text(badge, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: badgeColor)),
            )),
            Positioned(top: 8, right: 8, child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
              child: const Icon(LucideIcons.heart, size: 16, color: Colors.black87),
            )),
          ]),
        ),
        Padding(padding: const EdgeInsets.all(DSSpacing.s3), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text.primary)),
          Text(role, style: TextStyle(fontSize: 12, color: c.text.muted)),
          const SizedBox(height: DSSpacing.s1),
          Text(desc, style: TextStyle(fontSize: 12, color: c.text.secondary), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: DSSpacing.s2),
          Row(children: [
            Icon(LucideIcons.star, size: 13, color: c.state.warning),
            const SizedBox(width: 2),
            Text('$rating', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.text.primary)),
            Text(' ($reviews)', style: TextStyle(fontSize: 12, color: c.text.muted)),
          ]),
          const SizedBox(height: 2),
          Text(price, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text.primary)),
        ])),
      ]),
    );
  }
}
