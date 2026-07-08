import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/utils/unsaved_changes_dialog.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/musician_job_filters.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';

const _allRegions = [
  'Hovedstaden',
  'Bornholm',
  'Fyn',
  'Nordjylland',
  'Nordsjælland',
  'Østjylland',
  'Sønderjylland',
  'Sydsjælland',
  'Vestjylland',
  'Vestsjælland',
];

// Sax type ('lounge' | 'party') — the Jobs/ExtJobs.sax_type field. Value → Danish label.
const _allSaxTypes = ['lounge', 'party'];
const _saxTypeLabels = {'lounge': 'Lounge', 'party': 'Party'};

class MusicianJobFiltersScreen extends ConsumerStatefulWidget {
  const MusicianJobFiltersScreen({super.key, required this.musicianId});

  final String musicianId;

  @override
  ConsumerState<MusicianJobFiltersScreen> createState() =>
      _MusicianJobFiltersScreenState();
}

class _MusicianJobFiltersScreenState
    extends ConsumerState<MusicianJobFiltersScreen> {
  MusicianJobFilters? _filters;
  bool _initialized = false;
  MusicianJobFilters? _initialFilters;

  void _initFrom(MusicianJobFilters? saved) {
    _filters = saved ?? MusicianJobFilters(musicianId: widget.musicianId);
    _initialFilters = _filters;
    _initialized = true;
  }

  bool get _isDirty => _initialized && _filters != _initialFilters;

  Future<void> _onPopInvoked(bool didPop, _) async {
    if (didPop) return;
    final confirmed = await showUnsavedChangesDialog(context);
    if (confirmed == true && mounted) Navigator.of(context).pop();
  }

  // ── Sax types ──

  void _toggleSaxType(String type) {
    final current = List<String>.from(_filters!.excludedSaxTypes);
    current.contains(type) ? current.remove(type) : current.add(type);
    setState(() => _filters = _filters!.copyWith(excludedSaxTypes: current));
  }

  void _selectAllSaxTypes() {
    setState(() => _filters = _filters!.copyWith(excludedSaxTypes: []));
  }

  void _deselectAllSaxTypes() {
    setState(
      () =>
          _filters = _filters!.copyWith(
            excludedSaxTypes: List.from(_allSaxTypes),
          ),
    );
  }

  // ── Regions ──

  void _toggleRegion(String region) {
    final current = List<String>.from(_filters!.excludedRegions);
    current.contains(region) ? current.remove(region) : current.add(region);
    setState(() => _filters = _filters!.copyWith(excludedRegions: current));
  }

  void _selectAllRegions() {
    setState(() => _filters = _filters!.copyWith(excludedRegions: []));
  }

  void _deselectAllRegions() {
    setState(
      () =>
          _filters = _filters!.copyWith(
            excludedRegions: List.from(_allRegions),
          ),
    );
  }

  // ── Save / reset ──

  Future<void> _save() async {
    final success = await ref
        .read(saveMusicianJobFiltersProvider.notifier)
        .save(_filters!);
    if (!mounted) return;
    if (success) {
      DSToast.show(
        context,
        variant: DSToastVariant.success,
        title: 'Filtre gemt',
      );
      Navigator.of(context).pop();
    } else {
      DSToast.show(
        context,
        variant: DSToastVariant.error,
        title: 'Noget gik galt. Prøv igen.',
      );
    }
  }

  void _reset() => setState(
    () => _filters = MusicianJobFilters(musicianId: widget.musicianId),
  );

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final filtersAsync = ref.watch(musicianJobFiltersProvider);
    final isSaving = ref.watch(saveMusicianJobFiltersProvider) is AsyncLoading;

    return filtersAsync.when(
      loading:
          () => _buildScaffold(
            child: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (e, _) => _buildScaffold(
            child: Center(
              child: Text(
                'Fejl: $e',
                style: DSTextStyle.bodyMd.copyWith(color: _c.state.danger),
              ),
            ),
          ),
      data: (saved) {
        if (!_initialized) _initFrom(saved);
        return _buildScaffold(isSaving: isSaving, child: _buildForm());
      },
    );
  }

  Widget _buildScaffold({Widget? child, bool isSaving = false}) {
    final _c = DSTheme.of(context);
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        backgroundColor: _c.bg.canvas,
        appBar: AppBar(
          title: const Text('Job-filtre'),
          backgroundColor: _c.bg.surface,
          surfaceTintColor: _c.bg.surface,
          actions: [
            if (_filters != null)
              Padding(
                padding: const EdgeInsets.only(right: DSSpacing.s2),
                child: DSButton(
                  label: 'Nulstil',
                  variant: DSButtonVariant.ghost,
                  size: DSButtonSize.sm,
                  onTap: _reset,
                ),
              ),
          ],
        ),
        body: child,
        bottomNavigationBar:
            _filters == null
                ? null
                : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(DSSpacing.s4),
                    child: DSButton(
                      label: 'Gem filtre',
                      variant: DSButtonVariant.primary,
                      expand: true,
                      isLoading: isSaving,
                      onTap: isSaving ? null : _save,
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildForm() {
    final f = _filters!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DSSpacing.s4,
        DSSpacing.s4,
        DSSpacing.s4,
        DSSpacing.s8,
      ),
      children: [
        // ── Regions ──
        _ChipSectionHeader(
          title: 'Regioner',
          subtitle: 'Skjul jobs fra bestemte regioner',
          onSelectAll: _selectAllRegions,
          onDeselectAll: _deselectAllRegions,
        ),
        const SizedBox(height: DSSpacing.s2),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _allRegions.map((r) {
                return _FilterChip(
                  label: r,
                  active: !f.excludedRegions.contains(r),
                  onTap: () => _toggleRegion(r),
                );
              }).toList(),
        ),
        const SizedBox(height: DSSpacing.s6),

        // ── Sax type ──
        _ChipSectionHeader(
          title: 'Type',
          subtitle: 'Vælg om du vil se lounge- og/eller party-jobs',
          onSelectAll: _selectAllSaxTypes,
          onDeselectAll: _deselectAllSaxTypes,
        ),
        const SizedBox(height: DSSpacing.s2),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _allSaxTypes.map((t) {
                return _FilterChip(
                  label: _saxTypeLabels[t] ?? t,
                  active: !f.excludedSaxTypes.contains(t),
                  onTap: () => _toggleSaxType(t),
                );
              }).toList(),
        ),
      ],
    );
  }
}

// ── Section headers ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: DSTextStyle.headingSm.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _c.text.primary,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: DSTextStyle.bodySm.copyWith(color: _c.text.muted),
          ),
      ],
    );
  }
}

class _ChipSectionHeader extends StatelessWidget {
  const _ChipSectionHeader({
    required this.title,
    this.subtitle,
    required this.onSelectAll,
    required this.onDeselectAll,
  });
  final String title;
  final String? subtitle;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _SectionHeader(title, subtitle: subtitle)),
        GestureDetector(
          onTap: onSelectAll,
          child: Text(
            'Vælg alle',
            style: DSTextStyle.labelSm.copyWith(
              fontWeight: FontWeight.w600,
              color: _c.brand.primaryActive,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '·',
            style: DSTextStyle.bodySm.copyWith(color: _c.text.muted),
          ),
        ),
        GestureDetector(
          onTap: onDeselectAll,
          child: Text(
            'Fravælg alle',
            style: DSTextStyle.labelSm.copyWith(
              fontWeight: FontWeight.w600,
              color: _c.text.muted,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? _c.brand.primary : _c.bg.inputBg,
          borderRadius: BorderRadius.circular(DSRadius.pill),
          border: active ? null : Border.all(color: _c.border.subtle),
        ),
        child: Text(
          label,
          style: DSTextStyle.labelMd.copyWith(
            color: active ? _c.brand.onPrimary : _c.text.secondary,
          ),
        ),
      ),
    );
  }
}
