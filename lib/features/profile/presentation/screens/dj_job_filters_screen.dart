import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/utils/event_type_labels.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/dj_job_filters.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';

const _c = lightColors;

const _allEventTypes = [
  'bryllup', 'firmafest', 'fødselsdagsfest', 'julefrokost',
  'privatfest', 'ungdomsfest', 'klub/bar', 'lounge', 'andet',
];
const _allRegions = [
  'Hovedstaden', 'Bornholm', 'Fyn', 'Nordjylland', 'Nordsjælland',
  'Østjylland', 'Sønderjylland', 'Sydsjælland', 'Vestjylland', 'Vestsjælland',
];
const _djGenres = [
  'EDM', 'Disco', 'Dansk top', 'Hip hop', 'House', 'Lounge', 'Pop',
  'R&B', 'Reggae', 'Remixes', 'Rock', 'Techno', 'Top 50 (DK)',
  'Top 50 (global)', "70'er/80'er/90'er",
];
// Weekday names in Danish — index 0 = Sunday (matching JS/DB convention)
const _weekdayNames = ['Søn', 'Man', 'Tir', 'Ons', 'Tor', 'Fre', 'Lør'];

// Slider bounds
const _budgetMin = 0.0;
const _budgetMax = 50000.0;
const _budgetDivisions = 50; // step = 1000 DKK

const _guestsMin = 0.0;
const _guestsMax = 1000.0;
const _guestsDivisions = 50; // step = 20 guests

class DjJobFiltersScreen extends ConsumerStatefulWidget {
  const DjJobFiltersScreen({super.key, required this.djId});

  final String djId;

  @override
  ConsumerState<DjJobFiltersScreen> createState() => _DjJobFiltersScreenState();
}

class _DjJobFiltersScreenState extends ConsumerState<DjJobFiltersScreen> {
  DjJobFilters? _filters;
  bool _initialized = false;

  void _initFrom(DjJobFilters? saved) {
    _filters = saved ?? DjJobFilters(djId: widget.djId, allowedWeekdays: null);
    _initialized = true;
  }

  // ── Event types ──

  void _toggleEventType(String type) {
    final current = List<String>.from(_filters!.excludedEventTypes);
    current.contains(type) ? current.remove(type) : current.add(type);
    setState(() => _filters = _filters!.copyWith(excludedEventTypes: current));
  }

  void _selectAllEventTypes() =>
      setState(() => _filters = _filters!.copyWith(excludedEventTypes: []));

  void _deselectAllEventTypes() =>
      setState(() => _filters = _filters!.copyWith(excludedEventTypes: List.from(_allEventTypes)));

  // ── Regions ──

  void _toggleRegion(String region) {
    final current = List<String>.from(_filters!.excludedRegions);
    current.contains(region) ? current.remove(region) : current.add(region);
    setState(() => _filters = _filters!.copyWith(excludedRegions: current));
  }

  void _selectAllRegions() =>
      setState(() => _filters = _filters!.copyWith(excludedRegions: []));

  void _deselectAllRegions() =>
      setState(() => _filters = _filters!.copyWith(excludedRegions: List.from(_allRegions)));

  // ── Genres ──

  void _toggleGenre(String genre) {
    final current = List<String>.from(_filters!.excludedGenres);
    current.contains(genre) ? current.remove(genre) : current.add(genre);
    setState(() => _filters = _filters!.copyWith(excludedGenres: current));
  }

  void _selectAllGenres() =>
      setState(() => _filters = _filters!.copyWith(excludedGenres: []));

  void _deselectAllGenres() =>
      setState(() => _filters = _filters!.copyWith(excludedGenres: List.from(_djGenres)));

  // ── Weekdays ──

  void _toggleWeekday(int day) {
    final current = _filters!.allowedWeekdays == null
        ? List<int>.generate(7, (i) => i)
        : List<int>.from(_filters!.allowedWeekdays!);
    current.contains(day) ? current.remove(day) : current.add(day);
    setState(() => _filters = _filters!.copyWith(
          allowedWeekdays: current.length == 7 ? () => null : () => current,
        ));
  }

  void _applyWeekendPreset() => setState(() => _filters = _filters!.copyWith(
        allowedWeekdays: () => [5, 6, 0], // Fri, Sat, Sun
      ));

  // ── Budget slider ──

  RangeValues get _budgetRange => RangeValues(
        (_filters!.minBudget ?? _budgetMin).toDouble().clamp(_budgetMin, _budgetMax),
        (_filters!.maxBudget ?? _budgetMax).toDouble().clamp(_budgetMin, _budgetMax),
      );

  void _onBudgetChanged(RangeValues v) {
    final lo = v.start.round();
    final hi = v.end.round();
    setState(() => _filters = _filters!.copyWith(
          minBudget: () => lo == _budgetMin.toInt() ? null : lo,
          maxBudget: () => hi == _budgetMax.toInt() ? null : hi,
        ));
  }

  // ── Guests slider ──

  RangeValues get _guestsRange => RangeValues(
        (_filters!.minGuests ?? _guestsMin).toDouble().clamp(_guestsMin, _guestsMax),
        (_filters!.maxGuests ?? _guestsMax).toDouble().clamp(_guestsMin, _guestsMax),
      );

  void _onGuestsChanged(RangeValues v) {
    final lo = v.start.round();
    final hi = v.end.round();
    setState(() => _filters = _filters!.copyWith(
          minGuests: () => lo == _guestsMin.toInt() ? null : lo,
          maxGuests: () => hi == _guestsMax.toInt() ? null : hi,
        ));
  }

  // ── Save / reset ──

  Future<void> _save() async {
    final success = await ref.read(saveDjJobFiltersProvider.notifier).save(_filters!);
    if (!mounted) return;
    if (success) {
      DSToast.show(context, variant: DSToastVariant.success, title: 'Filtre gemt');
      Navigator.of(context).pop();
    } else {
      DSToast.show(context, variant: DSToastVariant.error, title: 'Noget gik galt. Prøv igen.');
    }
  }

  void _reset() => setState(() => _filters = DjJobFilters(djId: widget.djId));

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final filtersAsync = ref.watch(djJobFiltersProvider);
    final isSaving = ref.watch(saveDjJobFiltersProvider) is AsyncLoading;

    return filtersAsync.when(
      loading: () => _buildScaffold(child: const Center(child: CircularProgressIndicator())),
      error: (e, _) => _buildScaffold(
        child: Center(child: Text('Fejl: $e', style: DSTextStyle.bodyMd.copyWith(color: _c.state.danger))),
      ),
      data: (saved) {
        if (!_initialized) _initFrom(saved);
        return _buildScaffold(isSaving: isSaving, child: _buildForm());
      },
    );
  }

  Widget _buildScaffold({Widget? child, bool isSaving = false}) {
    return Scaffold(
      backgroundColor: _c.bg.canvas,
      appBar: AppBar(
        title: const Text('Job-filtre'),
        backgroundColor: _c.bg.surface,
        surfaceTintColor: _c.bg.surface,
        actions: [
          if (_filters != null)
            Padding(
              padding: const EdgeInsets.only(right: DSSpacing.s2),
              child: DSButton(label: 'Nulstil', variant: DSButtonVariant.ghost, size: DSButtonSize.sm, onTap: _reset),
            ),
        ],
      ),
      body: child,
      bottomNavigationBar: _filters == null
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
    );
  }

  Widget _buildForm() {
    final f = _filters!;
    final effectiveWeekdays = f.allowedWeekdays ?? List<int>.generate(7, (i) => i);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          DSSpacing.s4, DSSpacing.s4, DSSpacing.s4, DSSpacing.s8),
      children: [
        // ── Event types ──
        _ChipSectionHeader(
          title: 'Arrangementtyper',
          subtitle: 'Skjul jobs du ikke ønsker at se',
          onSelectAll: _selectAllEventTypes,
          onDeselectAll: _deselectAllEventTypes,
        ),
        const SizedBox(height: DSSpacing.s2),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allEventTypes.map((type) {
            return _FilterChip(
              label: eventTypeLabel(type),
              active: !f.excludedEventTypes.contains(type),
              onTap: () => _toggleEventType(type),
            );
          }).toList(),
        ),
        const SizedBox(height: DSSpacing.s6),

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
          children: _allRegions.map((r) {
            return _FilterChip(
              label: r,
              active: !f.excludedRegions.contains(r),
              onTap: () => _toggleRegion(r),
            );
          }).toList(),
        ),
        const SizedBox(height: DSSpacing.s6),

        // ── Genres ──
        _ChipSectionHeader(
          title: 'Genres',
          subtitle: 'Skjul jobs hvor alle genres er ekskluderede',
          onSelectAll: _selectAllGenres,
          onDeselectAll: _deselectAllGenres,
        ),
        const SizedBox(height: DSSpacing.s2),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _djGenres.map((g) {
            return _FilterChip(
              label: g,
              active: !f.excludedGenres.contains(g),
              onTap: () => _toggleGenre(g),
            );
          }).toList(),
        ),
        const SizedBox(height: DSSpacing.s6),

        // ── Weekdays ──
        Row(
          children: [
            Expanded(child: _SectionHeader('Ugedage', subtitle: 'Vis kun jobs på valgte dage')),
            GestureDetector(
              onTap: _applyWeekendPreset,
              child: Text(
                'Weekend-preset',
                style: DSTextStyle.labelSm.copyWith(fontWeight: FontWeight.w600, color: _c.brand.primaryActive),
              ),
            ),
          ],
        ),
        const SizedBox(height: DSSpacing.s2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (jsDay) {
            final active = effectiveWeekdays.contains(jsDay);
            return GestureDetector(
              onTap: () => _toggleWeekday(jsDay),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? _c.brand.primary : _c.bg.inputBg,
                  border: active ? null : Border.all(color: _c.border.subtle),
                ),
                child: Center(
                  child: Text(
                    _weekdayNames[jsDay],
                    style: DSTextStyle.bodySm.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: active ? _c.brand.onPrimary : _c.text.secondary),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: DSSpacing.s6),

        // ── Budget slider ──
        _SectionHeader('Budget (kr.)', subtitle: 'Skjul jobs udenfor dette interval'),
        DSRangeSlider(
          values: _budgetRange,
          min: _budgetMin,
          max: _budgetMax,
          divisions: _budgetDivisions,
          labelBuilder: (v) => '${v.toInt()} kr.',
          noFilterLabel: 'Alle budgetter',
          onChanged: _onBudgetChanged,
        ),
        const SizedBox(height: DSSpacing.s4),

        // ── Guests slider ──
        _SectionHeader('Antal gæster', subtitle: 'Skjul jobs udenfor dette interval'),
        DSRangeSlider(
          values: _guestsRange,
          min: _guestsMin,
          max: _guestsMax,
          divisions: _guestsDivisions,
          labelBuilder: (v) => '${v.toInt()}',
          noFilterLabel: 'Alle størrelser',
          onChanged: _onGuestsChanged,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: DSTextStyle.headingSm.copyWith(fontSize: 15, fontWeight: FontWeight.w700, color: _c.text.primary)),
        if (subtitle != null)
          Text(subtitle!, style: DSTextStyle.bodySm.copyWith(color: _c.text.muted)),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _SectionHeader(title, subtitle: subtitle)),
        GestureDetector(
          onTap: onSelectAll,
          child: Text(
            'Vælg alle',
            style: DSTextStyle.labelSm.copyWith(fontWeight: FontWeight.w600, color: _c.brand.primaryActive),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('·', style: DSTextStyle.bodySm.copyWith(color: _c.text.muted)),
        ),
        GestureDetector(
          onTap: onDeselectAll,
          child: Text(
            'Fravælg alle',
            style: DSTextStyle.labelSm.copyWith(fontWeight: FontWeight.w600, color: _c.text.muted),
          ),
        ),
      ],
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
          style: DSTextStyle.labelMd.copyWith(color: active ? _c.brand.onPrimary : _c.text.secondary),
        ),
      ),
    );
  }
}

