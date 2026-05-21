import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/app.dart';
import 'package:dj_tilbud_app/core/config/role_cache.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/core/utils/event_type_labels.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/dj_job_filters.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/dj_profile.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/musician_profile.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/review.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/user_file.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';

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
const _musicianGenres = [
  'pop', 'house', 'disco', 'funk', 'jazz', 'hip hop', 'bossanova', 'latin', 'soul',
];
const _weekdayNames = ['Søn', 'Man', 'Tir', 'Ons', 'Tor', 'Fre', 'Lør'];

const _budgetMin = 0.0;
const _budgetMax = 50000.0;
const _budgetDivisions = 50;
const _guestsMin = 0.0;
const _guestsMax = 1000.0;
const _guestsDivisions = 50;

const _reviewEventTypes = [
  'bryllup', 'firmafest', 'fødselsdagsfest', 'fødselsdag',
  'julefrokost', 'privatfest', 'ungdomsfest', 'klub/bar',
  'lounge', 'konfirmation', 'studenterfest', 'sommerfest', 'andet',
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  DSColors get _c => DSTheme.of(context);

  int _step = 0;
  bool _completing = false;

  // Full DJ filter state — populated by _FiltersStep via onChanged callback
  DjJobFilters? _djFilters;

  bool get _isDj => RoleCache.role == MusicianRole.dj;
  int get _totalSteps => _isDj ? 4 : 3;

  bool _computeStepComplete({
    required DjProfile? dj,
    required MusicianProfile? musician,
    required List<UserFile>? files,
    required List<Review>? reviews,
  }) {
    switch (_step) {
      case 0:
        if (_isDj) {
          if (dj == null) return false;
          return dj.fullName.isNotEmpty &&
              dj.companyOrDjName.isNotEmpty &&
              dj.phone.isNotEmpty &&
              dj.aboutYou.isNotEmpty &&
              dj.regions.isNotEmpty &&
              dj.genres.isNotEmpty;
        } else {
          if (musician == null) return false;
          return musician.fullName.isNotEmpty &&
              musician.phone.isNotEmpty &&
              musician.instrument.isNotEmpty &&
              musician.regions.isNotEmpty;
        }
      case 1:
        final hasProfilePic = files?.any((f) => f.type == UserFileType.profile) ?? false;
        final hasCommonPic = files?.any((f) => f.type == UserFileType.common) ?? false;
        final hasVideo = files?.any((f) => f.type == UserFileType.commonVideo) ?? false;
        return hasProfilePic && hasCommonPic && hasVideo;
      case 2:
        return (reviews?.length ?? 0) >= 3;
      case 3:
        return true;
      default:
        return false;
    }
  }

  String? _computeStepHint({
    required bool stepComplete,
    required List<Review>? reviews,
    required List<UserFile>? files,
  }) {
    switch (_step) {
      case 0:
        return stepComplete ? null : 'Udfyld alle påkrævede profilfelter for at fortsætte';
      case 1:
        if (stepComplete) return null;
        final missing = <String>[];
        if (!(files?.any((f) => f.type == UserFileType.profile) ?? false)) missing.add('profilbillede');
        if (!(files?.any((f) => f.type == UserFileType.common) ?? false)) missing.add('billede');
        if (!(files?.any((f) => f.type == UserFileType.commonVideo) ?? false)) missing.add('video');
        return missing.isEmpty ? null : 'Mangler: ${missing.join(', ')}';
      case 2:
        if (stepComplete) return null;
        final count = reviews?.length ?? 0;
        final missing2 = 3 - count;
        return 'Tilføj mindst $missing2 anmeldelse${missing2 == 1 ? '' : 'r'} mere';
      default:
        return null;
    }
  }

  void _goBack() => setState(() => _step--);

  Future<void> _advance({required bool stepComplete}) async {
    if (!stepComplete || _completing) return;
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
      return;
    }
    await _finishOnboarding();
  }

  Future<void> _finishOnboarding() async {
    setState(() => _completing = true);
    try {
      final userId = supabase.auth.currentUser!.id;

      if (_isDj) {
        final filters = _djFilters ?? DjJobFilters(djId: userId);
        await ref.read(profileRepositoryProvider).saveDjJobFilters(filters);
        ref.invalidate(djJobFiltersProvider);
      }

      await ref.read(profileRepositoryProvider).setOnboardingCompleted(userId: userId, isDj: _isDj);
      markOnboardingComplete();
    } catch (e) {
      if (mounted) DSToast.show(context, variant: DSToastVariant.error, title: 'Fejl: $e');
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dj = _isDj ? ref.watch(djProfileProvider).valueOrNull : null;
    final musician = !_isDj ? ref.watch(musicianProfileProvider).valueOrNull : null;
    final files = ref.watch(userFilesProvider).valueOrNull;
    final reviews = (_isDj ? ref.watch(djReviewsProvider) : ref.watch(musicianReviewsProvider))
        .valueOrNull;

    final stepComplete = _computeStepComplete(
      dj: dj, musician: musician, files: files, reviews: reviews);
    final hint = _computeStepHint(stepComplete: stepComplete, reviews: reviews, files: files);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _c.bg.canvas,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              _buildStepIndicator(),
              Expanded(child: _buildStepContent()),
              _buildFooter(stepComplete: stepComplete, hint: hint),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final titles = _isDj
        ? ['Din profil', 'Billeder & video', 'Anmeldelser', 'Jobfiltre']
        : ['Din profil', 'Billeder & video', 'Anmeldelser'];
    final subtitles = _isDj
        ? [
            'Bekræft at dine profiloplysninger er udfyldt',
            'Upload mindst 1 profilbillede (video er valgfri)',
            'Tilføj mindst 3 anmeldelser fra kunder',
            'Tilpas hvilke jobs du vil se — eller behold standarderne',
          ]
        : [
            'Bekræft at dine profiloplysninger er udfyldt',
            'Upload mindst 1 profilbillede (video er valgfri)',
            'Tilføj mindst 3 anmeldelser fra kunder',
          ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(DSSpacing.s4, DSSpacing.s6, DSSpacing.s4, DSSpacing.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_step > 0) ...[
            GestureDetector(
              onTap: _goBack,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.chevronLeft, size: 20, color: _c.text.secondary),
                  Text('Tilbage', style: DSTextStyle.bodySm.copyWith(color: _c.text.secondary)),
                ],
              ),
            ),
            const SizedBox(height: DSSpacing.s3),
          ],
          Text(
            'Opsætning',
            style: DSTextStyle.headingLg.copyWith(fontWeight: FontWeight.w800, color: _c.text.primary),
          ),
          const SizedBox(height: DSSpacing.s1),
          Text(
            titles[_step],
            style: DSTextStyle.headingMd.copyWith(color: _c.brand.primary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: DSSpacing.s1),
          Text(
            subtitles[_step],
            style: DSTextStyle.bodyMd.copyWith(color: _c.text.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s4, vertical: DSSpacing.s3),
      child: Row(
        children: List.generate(_totalSteps, (i) {
          final done = i < _step;
          final active = i == _step;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < _totalSteps - 1 ? DSSpacing.s2 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: done || active ? _c.brand.primary : _c.border.subtle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    return switch (_step) {
      0 => _ProfileStep(isDj: _isDj),
      1 => const _PicturesStep(),
      2 => _ReviewsStep(isDj: _isDj),
      3 => _FiltersStep(
          onChanged: (filters) => setState(() => _djFilters = filters),
        ),
      _ => const SizedBox(),
    };
  }

  Widget _buildFooter({required bool stepComplete, required String? hint}) {
    final isLast = _step == _totalSteps - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(DSSpacing.s4, DSSpacing.s2, DSSpacing.s4, DSSpacing.s6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hint != null) ...[
            Text(
              hint,
              style: DSTextStyle.bodySm.copyWith(color: _c.text.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DSSpacing.s2),
          ],
          DSButton(
            label: isLast ? 'Fuldfør opsætning' : 'Fortsæt',
            size: DSButtonSize.lg,
            expand: true,
            isLoading: _completing,
            enabled: stepComplete && !_completing,
            onTap: () => _advance(stepComplete: stepComplete),
          ),
          const SizedBox(height: DSSpacing.s1),
          Text(
            'Trin ${_step + 1} af $_totalSteps',
            style: DSTextStyle.bodySm.copyWith(color: _c.text.muted),
          ),
        ],
      ),
    );
  }
}

// ── Step 1: Profile ───────────────────────────────────────────────────────────

class _ProfileStep extends ConsumerWidget {
  const _ProfileStep({required this.isDj});

  final bool isDj;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _c = DSTheme.of(context);
    final profileAsync = isDj ? ref.watch(djProfileProvider) : ref.watch(musicianProfileProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s4, vertical: DSSpacing.s6),
      child: profileAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: _c.brand.primary)),
        error: (e, _) => Text('Fejl: $e', style: DSTextStyle.bodyMd.copyWith(color: _c.state.danger)),
        data: (profile) {
          final rows = isDj
              ? _djRows(profile as DjProfile)
              : _musicianRows(profile as MusicianProfile);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DSSurface(
                child: Column(
                  children: rows
                      .map((r) => _ProfileFieldRow(label: r.$1, value: r.$2))
                      .toList(),
                ),
              ),
              const SizedBox(height: DSSpacing.s4),
              DSButton(
                label: 'Rediger profil',
                variant: DSButtonVariant.secondary,
                iconLeft: LucideIcons.pencil,
                size: DSButtonSize.md,
                expand: true,
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: _c.bg.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(DSRadius.lg))),
                  builder: (_) => _EditProfileSheet(isDj: isDj),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<(String, String)> _djRows(DjProfile dj) => [
        ('Navn', dj.fullName),
        ('DJ-navn / firma', dj.companyOrDjName),
        ('Telefon', dj.phone),
        ('Om dig', dj.aboutYou),
        ('Regioner', dj.regions.isEmpty ? '' : '${dj.regions.length} valgt'),
        ('Genrer', dj.genres.isEmpty ? '' : '${dj.genres.length} valgt'),
      ];

  List<(String, String)> _musicianRows(MusicianProfile m) => [
        ('Navn', m.fullName),
        ('Telefon', m.phone),
        ('Instrument', m.instrument),
        ('Timeløn', m.hourlyRate > 0 ? '${m.hourlyRate} kr/t' : ''),
        ('Regioner', m.regions.isEmpty ? '' : '${m.regions.length} valgt'),
      ];
}

class _ProfileFieldRow extends StatelessWidget {
  const _ProfileFieldRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final filled = value.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DSSpacing.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            filled ? LucideIcons.checkCircle : LucideIcons.alertCircle,
            size: 18,
            color: filled ? _c.state.success : _c.state.danger,
          ),
          const SizedBox(width: DSSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: DSTextStyle.labelSm.copyWith(color: _c.text.muted)),
                const SizedBox(height: 2),
                Text(
                  filled ? value : 'Mangler — rediger din profil',
                  style: DSTextStyle.bodyMd.copyWith(
                    color: filled ? _c.text.primary : _c.state.danger,
                    fontWeight: filled ? FontWeight.w400 : FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Edit profile sheet ────────────────────────────────────────────────────────

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.isDj});

  final bool isDj;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  DSColors get _c => DSTheme.of(context);
  final _formKey = GlobalKey<FormState>();

  final _fullNameCtrl = TextEditingController();
  final _djNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();
  final _hourlyRateCtrl = TextEditingController();

  List<String> _selectedRegions = [];
  List<String> _selectedGenres = [];
  String _musicianInstrument = '';

  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _djNameCtrl.dispose();
    _phoneCtrl.dispose();
    _aboutCtrl.dispose();
    _hourlyRateCtrl.dispose();
    super.dispose();
  }

  void _initDj(DjProfile p) {
    if (_initialized) return;
    _initialized = true;
    _fullNameCtrl.text = p.fullName;
    _djNameCtrl.text = p.companyOrDjName;
    _phoneCtrl.text = p.phone;
    _aboutCtrl.text = p.aboutYou;
    _selectedRegions = List.of(p.regions);
    _selectedGenres = List.of(p.genres);
  }

  void _initMusician(MusicianProfile p) {
    if (_initialized) return;
    _initialized = true;
    _fullNameCtrl.text = p.fullName;
    _phoneCtrl.text = p.phone;
    _hourlyRateCtrl.text = p.hourlyRate > 0 ? p.hourlyRate.toString() : '';
    _selectedRegions = List.of(p.regions);
    _selectedGenres = List.of(p.genres ?? []);
    _musicianInstrument = p.instrument;
  }

  int? get _regionLimit =>
      !widget.isDj && _musicianInstrument == 'saxophone' ? 2 : null;

  void _toggleRegion(String r) {
    if (widget.isDj) {
      setState(() => _selectedRegions = [r]);
      return;
    }
    final isSelected = _selectedRegions.contains(r);
    final limit = _regionLimit;
    if (!isSelected && limit != null && _selectedRegions.length >= limit) {
      DSToast.show(
        context,
        variant: DSToastVariant.warning,
        title: 'Du kan højst vælge $limit regioner',
      );
      return;
    }
    setState(() {
      isSelected ? _selectedRegions.remove(r) : _selectedRegions.add(r);
    });
  }

  void _toggleGenre(String g) {
    setState(() {
      _selectedGenres.contains(g)
          ? _selectedGenres.remove(g)
          : _selectedGenres.add(g);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      if (widget.isDj) {
        final cur = ref.read(djProfileProvider).value!;
        await repo.updateDjProfile(DjProfile(
          id: cur.id,
          fullName: _fullNameCtrl.text.trim(),
          companyOrDjName: _djNameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          aboutYou: _aboutCtrl.text.trim(),
          pricePerExtraHour: cur.pricePerExtraHour,
          regions: _selectedRegions,
          genres: _selectedGenres,
          canPlayWithSax: cur.canPlayWithSax,
          allowPublicDjProfile: cur.allowPublicDjProfile,
          soundcloudUrl: cur.soundcloudUrl,
          venuesAndEvents: cur.venuesAndEvents,
        ));
        ref.invalidate(djProfileProvider);
        await ref.read(djProfileProvider.future);
      } else {
        final cur = ref.read(musicianProfileProvider).value!;
        await repo.updateMusicianProfile(MusicianProfile(
          id: cur.id,
          fullName: _fullNameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          instrument: cur.instrument,
          hourlyRate: int.tryParse(_hourlyRateCtrl.text) ?? cur.hourlyRate,
          minimumBookingRate: cur.minimumBookingRate,
          regions: _selectedRegions,
          aboutText: cur.aboutText,
          experienceYears: cur.experienceYears,
          genres: _selectedGenres.isEmpty ? cur.genres : _selectedGenres,
          djSaxCollaboration: cur.djSaxCollaboration,
          venuesAndEvents: cur.venuesAndEvents,
        ));
        ref.invalidate(musicianProfileProvider);
        await ref.read(musicianProfileProvider.future);
      }
      if (mounted) {
        DSToast.show(context, variant: DSToastVariant.success, title: 'Profil gemt');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        final isSaxRegionLimit =
            msg.contains('musicians_saxophone_regions_max_two');
        DSToast.show(
          context,
          variant: DSToastVariant.error,
          title: isSaxRegionLimit
              ? 'Saxofonister kan kun vælge 2 regioner'
              : 'Kunne ikke gemme: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync =
        widget.isDj ? ref.watch(djProfileProvider) : ref.watch(musicianProfileProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: DSSpacing.s6,
        right: DSSpacing.s6,
        top: DSSpacing.s6,
        bottom: MediaQuery.of(context).viewInsets.bottom + DSSpacing.s6,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: profileAsync.when(
            loading: () => SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator(color: _c.brand.primary)),
            ),
            error: (e, _) =>
                Text('Fejl: $e', style: DSTextStyle.bodyMd.copyWith(color: _c.state.danger)),
            data: (profile) {
              if (widget.isDj) {
                _initDj(profile as DjProfile);
              } else {
                _initMusician(profile as MusicianProfile);
              }
              return _buildForm();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rediger profil',
          style: DSTextStyle.headingMd.copyWith(
              fontWeight: FontWeight.w700, color: _c.text.primary),
        ),
        const SizedBox(height: DSSpacing.s4),
        DSInput(
          controller: _fullNameCtrl,
          label: 'Fulde navn',
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Påkrævet' : null,
        ),
        if (widget.isDj) ...[
          const SizedBox(height: DSSpacing.s3),
          DSInput(
            controller: _djNameCtrl,
            label: 'DJ / firma navn',
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Påkrævet' : null,
          ),
        ],
        const SizedBox(height: DSSpacing.s3),
        DSInput(
          controller: _phoneCtrl,
          label: 'Telefon',
          keyboardType: TextInputType.phone,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Påkrævet' : null,
        ),
        if (widget.isDj) ...[
          const SizedBox(height: DSSpacing.s3),
          DSInput(
            controller: _aboutCtrl,
            label: 'Om dig (maks 600 tegn)',
            maxLines: 4,
            maxLength: 600,
            showCounter: true,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Påkrævet' : null,
          ),
        ],
        if (!widget.isDj) ...[
          const SizedBox(height: DSSpacing.s3),
          DSInput(
            controller: _hourlyRateCtrl,
            label: 'Timepris (DKK)',
            keyboardType: TextInputType.number,
          ),
        ],
        const SizedBox(height: DSSpacing.s4),
        Text(
          widget.isDj ? 'Region (vælg én)' : 'Regioner',
          style: DSTextStyle.labelLg.copyWith(color: _c.text.primary),
        ),
        if (_regionLimit != null) ...[
          const SizedBox(height: 2),
          Text(
            'Saxofonister kan vælge op til 2 regioner',
            style: DSTextStyle.bodySm.copyWith(color: _c.text.muted),
          ),
        ],
        const SizedBox(height: DSSpacing.s2),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allRegions
              .map((r) => _OnboardingFilterChip(
                    label: r,
                    active: _selectedRegions.contains(r),
                    onTap: () => _toggleRegion(r),
                  ))
              .toList(),
        ),
        const SizedBox(height: DSSpacing.s4),
        Text(
          'Genrer',
          style: DSTextStyle.labelLg.copyWith(color: _c.text.primary),
        ),
        const SizedBox(height: DSSpacing.s2),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (widget.isDj ? _djGenres : _musicianGenres)
              .map((g) => _OnboardingFilterChip(
                    label: g,
                    active: _selectedGenres.contains(g),
                    onTap: () => _toggleGenre(g),
                  ))
              .toList(),
        ),
        const SizedBox(height: DSSpacing.s6),
        DSButton(
          label: 'Gem',
          size: DSButtonSize.lg,
          expand: true,
          isLoading: _saving,
          onTap: _saving ? null : _save,
        ),
      ],
    );
  }
}

// ── Step 2: Pictures & video ──────────────────────────────────────────────────

class _PicturesStep extends ConsumerStatefulWidget {
  const _PicturesStep();

  @override
  ConsumerState<_PicturesStep> createState() => _PicturesStepState();
}

class _PicturesStepState extends ConsumerState<_PicturesStep> {
  DSColors get _c => DSTheme.of(context);

  bool _uploadingProfilePic = false;
  bool _uploadingCommonPic = false;
  bool _uploadingProfileVideo = false;
  bool _uploadingCommonVideo = false;
  int? _deletingId;

  String get _userId =>
      ref.read(djProfileProvider).value?.id ??
      ref.read(musicianProfileProvider).value?.id ??
      '';

  bool get _busy =>
      _uploadingProfilePic || _uploadingCommonPic ||
      _uploadingProfileVideo || _uploadingCommonVideo ||
      _deletingId != null;

  Future<void> _uploadImage(UserFileType type) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() {
      if (type == UserFileType.profile) _uploadingProfilePic = true;
      else _uploadingCommonPic = true;
    });
    try {
      await ref.read(profileRepositoryProvider).uploadFile(
            userId: _userId, filePath: picked.path, type: type);
      ref.invalidate(userFilesProvider);
      if (mounted) DSToast.show(context, variant: DSToastVariant.success, title: 'Billede uploadet');
    } catch (e) {
      if (mounted) DSToast.show(context, variant: DSToastVariant.error, title: 'Upload fejlede: $e');
    } finally {
      if (mounted) setState(() {
        if (type == UserFileType.profile) _uploadingProfilePic = false;
        else _uploadingCommonPic = false;
      });
    }
  }

  Future<void> _uploadVideo(UserFileType type) async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    setState(() {
      if (type == UserFileType.profileVideo) _uploadingProfileVideo = true;
      else _uploadingCommonVideo = true;
    });
    try {
      await ref.read(profileRepositoryProvider).uploadFile(
            userId: _userId, filePath: picked.path, type: type);
      ref.invalidate(userFilesProvider);
      if (mounted) DSToast.show(context, variant: DSToastVariant.success, title: 'Video uploadet');
    } catch (e) {
      if (mounted) DSToast.show(context, variant: DSToastVariant.error, title: 'Upload fejlede: $e');
    } finally {
      if (mounted) setState(() {
        if (type == UserFileType.profileVideo) _uploadingProfileVideo = false;
        else _uploadingCommonVideo = false;
      });
    }
  }

  Future<void> _delete(UserFile file) async {
    final isVideo = file.type == UserFileType.profileVideo || file.type == UserFileType.commonVideo;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isVideo ? 'Slet video?' : 'Slet billede?'),
        actions: [
          DSButton(label: 'Annuller', variant: DSButtonVariant.ghost, size: DSButtonSize.sm,
              onTap: () => Navigator.of(ctx).pop(false)),
          DSButton(label: 'Slet', variant: DSButtonVariant.tertiary, size: DSButtonSize.sm,
              onTap: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _deletingId = file.id);
    try {
      await ref.read(profileRepositoryProvider).deleteFile(file.id);
      ref.invalidate(userFilesProvider);
    } catch (e) {
      if (mounted) DSToast.show(context, variant: DSToastVariant.error, title: 'Fejl: $e');
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filesAsync = ref.watch(userFilesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s4, vertical: DSSpacing.s6),
      child: filesAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: _c.brand.primary)),
        error: (e, _) => Text('Fejl: $e', style: DSTextStyle.bodyMd.copyWith(color: _c.state.danger)),
        data: (files) {
          final profilePics = files.where((f) => f.type == UserFileType.profile).toList();
          final commonPics = files.where((f) => f.type == UserFileType.common).toList();
          final profileVideos = files.where((f) => f.type == UserFileType.profileVideo).toList();
          final commonVideos = files.where((f) => f.type == UserFileType.commonVideo).toList();
          final thumbnailMap = <int, String>{
            for (final f in files)
              if (f.type == UserFileType.thumbnail && f.thumbnailVideoId != null)
                f.thumbnailVideoId!: f.url,
          };

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profilbillede (required) ──
              _MediaSectionHeader(title: 'Profilbillede', required: true,
                  subtitle: 'Dit primære billede på platformen.'),
              const SizedBox(height: DSSpacing.s3),
              Wrap(
                spacing: DSSpacing.s3, runSpacing: DSSpacing.s3,
                children: [
                  ...profilePics.map((f) => _ImageTile(
                        file: f, isDeleting: _deletingId == f.id,
                        onDelete: _busy ? null : () => _delete(f))),
                  if (profilePics.isEmpty)
                    _UploadTile(
                        isLoading: _uploadingProfilePic,
                        onTap: _busy ? null : () => _uploadImage(UserFileType.profile)),
                ],
              ),

              const SizedBox(height: DSSpacing.s6),

              // ── Billeder (required, multiple) ──
              _MediaSectionHeader(title: 'Billeder', required: true,
                  subtitle: 'Mindst 1 billede af dig i aktion.'),
              const SizedBox(height: DSSpacing.s3),
              Wrap(
                spacing: DSSpacing.s3, runSpacing: DSSpacing.s3,
                children: [
                  ...commonPics.map((f) => _ImageTile(
                        file: f, isDeleting: _deletingId == f.id,
                        onDelete: _busy ? null : () => _delete(f))),
                  _UploadTile(
                      isLoading: _uploadingCommonPic,
                      onTap: _busy ? null : () => _uploadImage(UserFileType.common)),
                ],
              ),

              const SizedBox(height: DSSpacing.s6),

              // ── Video (required) ──
              _MediaSectionHeader(title: 'Video', required: true,
                  subtitle: 'Et klip af dig i aktion.'),
              const SizedBox(height: DSSpacing.s3),
              if (commonVideos.isNotEmpty)
                ...commonVideos.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: DSSpacing.s3),
                      child: _VideoTile(
                          file: f, label: 'Video uploadet',
                          thumbnailUrl: thumbnailMap[f.id],
                          isDeleting: _deletingId == f.id,
                          onDelete: _busy ? null : () => _delete(f))))
              else
                _VideoUploadTile(
                    isLoading: _uploadingCommonVideo,
                    onTap: _busy ? null : () => _uploadVideo(UserFileType.commonVideo)),

              const SizedBox(height: DSSpacing.s6),

              // ── Profiivideo (optional) ──
              _MediaSectionHeader(title: 'Profiivideo', required: false,
                  subtitle: 'Et kort klip til din offentlige profil.'),
              const SizedBox(height: DSSpacing.s3),
              if (profileVideos.isNotEmpty)
                ...profileVideos.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: DSSpacing.s3),
                      child: _VideoTile(
                          file: f, label: 'Profiivideo uploadet',
                          thumbnailUrl: thumbnailMap[f.id],
                          isDeleting: _deletingId == f.id,
                          onDelete: _busy ? null : () => _delete(f))))
              else
                _VideoUploadTile(
                    isLoading: _uploadingProfileVideo,
                    onTap: _busy ? null : () => _uploadVideo(UserFileType.profileVideo)),
            ],
          );
        },
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({required this.file, required this.isDeleting, required this.onDelete});

  final UserFile file;
  final bool isDeleting;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return Stack(
      children: [
        Container(
          width: 110, height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DSRadius.md),
            border: Border.all(color: _c.border.subtle),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.network(file.url, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(child: Icon(LucideIcons.imageOff, color: _c.border.subtle))),
        ),
        if (isDeleting)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DSRadius.md),
                color: _c.bg.canvas.withValues(alpha: 0.7),
              ),
              child: Center(child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _c.state.danger))),
            ),
          )
        else
          Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: _c.state.danger, shape: BoxShape.circle),
                child: Icon(LucideIcons.x, size: 14, color: _c.text.onDark),
              ),
            ),
          ),
      ],
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110, height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DSRadius.md),
          border: Border.all(color: _c.border.subtle),
          color: _c.bg.canvas,
        ),
        child: isLoading
            ? Center(child: SizedBox(width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: _c.brand.primary)))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.imagePlus, size: 32, color: _c.text.secondary),
                  const SizedBox(height: DSSpacing.s1),
                  Text('Tilføj billede',
                      style: DSTextStyle.bodySm.copyWith(fontSize: 11, color: _c.text.secondary)),
                ],
              ),
      ),
    );
  }
}

class _MediaSectionHeader extends StatelessWidget {
  const _MediaSectionHeader({
    required this.title,
    required this.required,
    this.subtitle,
  });

  final String title;
  final bool required;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title,
                style: DSTextStyle.headingSm
                    .copyWith(fontWeight: FontWeight.w700, color: _c.text.primary)),
            const SizedBox(width: DSSpacing.s2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: required
                    ? _c.state.danger.withValues(alpha: 0.1)
                    : _c.border.subtle,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                required ? 'Påkrævet' : 'Valgfri',
                style: DSTextStyle.labelSm.copyWith(
                    color: required ? _c.state.danger : _c.text.muted),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: DSTextStyle.bodySm.copyWith(color: _c.text.muted)),
        ],
      ],
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({
    required this.file,
    required this.label,
    required this.isDeleting,
    required this.onDelete,
    this.thumbnailUrl,
  });

  final UserFile file;
  final String label;
  final String? thumbnailUrl;
  final bool isDeleting;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: _c.border.subtle),
        color: _c.bg.surface,
      ),
      padding: const EdgeInsets.all(DSSpacing.s3),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DSRadius.sm),
            child: thumbnailUrl != null
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.network(thumbnailUrl!,
                          width: 64, height: 64, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _videoIcon(_c)),
                      Container(
                        width: 64, height: 64,
                        color: Colors.black.withValues(alpha: 0.25),
                      ),
                      Icon(LucideIcons.play, size: 20, color: Colors.white),
                    ],
                  )
                : _videoIcon(_c),
          ),
          const SizedBox(width: DSSpacing.s3),
          Expanded(
            child: Text(label,
                style: DSTextStyle.bodyMd.copyWith(color: _c.text.primary)),
          ),
          if (isDeleting)
            SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: _c.state.danger))
          else
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: _c.state.danger, shape: BoxShape.circle),
                child: Icon(LucideIcons.x, size: 14, color: _c.text.onDark),
              ),
            ),
        ],
      ),
    );
  }

  Widget _videoIcon(DSColors c) => Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          color: c.brand.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(DSRadius.sm),
        ),
        child: Icon(LucideIcons.video, size: 26, color: c.brand.primary),
      );
}

class _VideoUploadTile extends StatelessWidget {
  const _VideoUploadTile({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DSSpacing.s4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DSRadius.md),
          border: Border.all(color: _c.border.subtle),
          color: _c.bg.canvas,
        ),
        child: isLoading
            ? Center(child: SizedBox(width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: _c.brand.primary)))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.video, size: 22, color: _c.text.secondary),
                  const SizedBox(width: DSSpacing.s2),
                  Text('Upload profiivideo',
                      style: DSTextStyle.bodyMd.copyWith(color: _c.text.secondary)),
                ],
              ),
      ),
    );
  }
}

// ── Step 3: Reviews ───────────────────────────────────────────────────────────

class _ReviewsStep extends ConsumerWidget {
  const _ReviewsStep({required this.isDj});

  final bool isDj;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _c = DSTheme.of(context);
    final reviewsAsync = isDj ? ref.watch(djReviewsProvider) : ref.watch(musicianReviewsProvider);

    return reviewsAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: _c.brand.primary)),
      error: (e, _) => Center(child: Text('Fejl: $e')),
      data: (reviews) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (reviews.length < 3)
            Padding(
              padding: const EdgeInsets.fromLTRB(DSSpacing.s4, DSSpacing.s4, DSSpacing.s4, 0),
              child: Container(
                padding: const EdgeInsets.all(DSSpacing.s3),
                decoration: BoxDecoration(
                  color: _c.state.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DSRadius.md),
                ),
                child: Row(children: [
                  Icon(LucideIcons.info, size: 18, color: _c.state.warning),
                  const SizedBox(width: DSSpacing.s2),
                  Expanded(child: Text(
                    '${reviews.length}/3 anmeldelser tilføjet',
                    style: DSTextStyle.bodySm.copyWith(color: _c.text.primary),
                  )),
                ]),
              ),
            ),
          Expanded(
            child: reviews.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.star, size: 48, color: _c.border.subtle),
                        const SizedBox(height: DSSpacing.s3),
                        Text('Ingen anmeldelser endnu',
                            style: DSTextStyle.bodyMd.copyWith(color: _c.text.secondary)),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s4),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: DSSpacing.s4, bottom: DSSpacing.s2),
                      itemCount: reviews.length,
                      itemBuilder: (ctx, i) => Padding(
                        padding: const EdgeInsets.only(bottom: DSSpacing.s3),
                        child: DSSurface(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(reviews[i].customerName,
                                style: DSTextStyle.headingSm.copyWith(fontSize: 15, color: _c.text.primary)),
                            const SizedBox(height: DSSpacing.s1),
                            Text(
                              '${eventTypeLabel(reviews[i].eventType)} — ${reviews[i].eventDate}',
                              style: DSTextStyle.bodySm.copyWith(color: _c.text.muted),
                            ),
                            const SizedBox(height: DSSpacing.s2),
                            Text(reviews[i].review,
                                style: DSTextStyle.labelMd.copyWith(
                                    fontWeight: FontWeight.w400, color: _c.text.secondary)),
                          ]),
                        ),
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(DSSpacing.s4, DSSpacing.s2, DSSpacing.s4, DSSpacing.s2),
            child: DSButton(
              label: 'Tilføj anmeldelse',
              variant: DSButtonVariant.secondary,
              iconLeft: LucideIcons.plus,
              size: DSButtonSize.md,
              expand: true,
              onTap: () => _showAddReview(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddReview(BuildContext context, WidgetRef ref) {
    final _c = DSTheme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _c.bg.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(DSRadius.lg))),
      builder: (ctx) => _AddReviewSheet(
        onSave: (name, review, eventType, eventDate) async {
          final userId = isDj
              ? ref.read(djProfileProvider).value!.id
              : ref.read(musicianProfileProvider).value!.id;
          await ref.read(profileRepositoryProvider).createReview(
            userId: userId, isDj: isDj, customerName: name,
            rating: 5, review: review, eventType: eventType, eventDate: eventDate,
          );
          ref.invalidate(isDj ? djReviewsProvider : musicianReviewsProvider);
          if (ctx.mounted) Navigator.of(ctx).pop();
          if (context.mounted)
            DSToast.show(context, variant: DSToastVariant.success, title: 'Anmeldelse tilføjet');
        },
      ),
    );
  }
}

class _AddReviewSheet extends StatefulWidget {
  const _AddReviewSheet({required this.onSave});

  final Future<void> Function(String name, String review, String eventType, String eventDate) onSave;

  @override
  State<_AddReviewSheet> createState() => _AddReviewSheetState();
}

class _AddReviewSheetState extends State<_AddReviewSheet> {
  DSColors get _c => DSTheme.of(context);
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _reviewCtrl = TextEditingController();
  String _eventType = 'bryllup';
  DateTime _eventDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _reviewCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: DSSpacing.s6, right: DSSpacing.s6, top: DSSpacing.s6,
        bottom: MediaQuery.of(context).viewInsets.bottom + DSSpacing.s6,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ny anmeldelse',
                  style: DSTextStyle.headingMd.copyWith(
                      fontWeight: FontWeight.w700, color: _c.text.primary)),
              const SizedBox(height: DSSpacing.s4),
              DSInput(
                controller: _nameCtrl,
                label: 'Kundens fornavn',
                maxLength: 20,
                showCounter: true,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Påkrævet' : null,
              ),
              const SizedBox(height: DSSpacing.s3),
              DSDropdown<String>(
                label: 'Event type',
                value: _eventType,
                items: _reviewEventTypes
                    .map((t) => DSDropdownItem(value: t, label: eventTypeLabel(t)))
                    .toList(),
                onChanged: (v) => setState(() => _eventType = v!),
              ),
              const SizedBox(height: DSSpacing.s3),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _eventDate,
                    firstDate: DateTime(2015),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _eventDate = picked);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dato for arrangement',
                        style: DSTextStyle.bodyMd.copyWith(
                            color: _c.text.primary, fontWeight: FontWeight.w500)),
                    const SizedBox(height: DSSpacing.s1),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: DSSpacing.s4, vertical: DSSpacing.s3),
                      decoration: BoxDecoration(
                          color: _c.bg.inputBg,
                          borderRadius: BorderRadius.circular(DSRadius.sm)),
                      child: Row(children: [
                        Expanded(
                          child: Text(DateFormat('dd/MM/yyyy').format(_eventDate),
                              style: DSTextStyle.bodyMd.copyWith(color: _c.text.primary)),
                        ),
                        Icon(LucideIcons.calendar, size: 18, color: _c.text.secondary),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DSSpacing.s3),
              DSInput(
                controller: _reviewCtrl,
                label: 'Anmeldelse',
                maxLength: 750,
                showCounter: true,
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Påkrævet' : null,
              ),
              const SizedBox(height: DSSpacing.s4),
              DSButton(
                label: 'Tilføj',
                size: DSButtonSize.lg,
                expand: true,
                isLoading: _saving,
                onTap: _saving
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() => _saving = true);
                        try {
                          await widget.onSave(
                            _nameCtrl.text.trim(),
                            _reviewCtrl.text.trim(),
                            _eventType,
                            DateFormat('yyyy-MM-dd').format(_eventDate),
                          );
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step 4: DJ Filters (full) ─────────────────────────────────────────────────

class _FiltersStep extends ConsumerStatefulWidget {
  const _FiltersStep({required this.onChanged});

  final void Function(DjJobFilters) onChanged;

  @override
  ConsumerState<_FiltersStep> createState() => _FiltersStepState();
}

class _FiltersStepState extends ConsumerState<_FiltersStep> {
  DSColors get _c => DSTheme.of(context);

  DjJobFilters? _filters;
  bool _initialized = false;

  void _initFrom(DjJobFilters? saved) {
    final userId = supabase.auth.currentUser!.id;
    _filters = saved ?? DjJobFilters(djId: userId);
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onChanged(_filters!);
    });
  }

  void _update(DjJobFilters updated) {
    setState(() => _filters = updated);
    widget.onChanged(updated);
  }

  // ── Event types ──

  void _toggleEventType(String type) {
    final current = List<String>.from(_filters!.excludedEventTypes);
    current.contains(type) ? current.remove(type) : current.add(type);
    _update(_filters!.copyWith(excludedEventTypes: current));
  }

  void _selectAllEventTypes() => _update(_filters!.copyWith(excludedEventTypes: []));
  void _deselectAllEventTypes() =>
      _update(_filters!.copyWith(excludedEventTypes: List.from(_allEventTypes)));

  // ── Regions ──

  void _toggleRegion(String region) {
    final current = List<String>.from(_filters!.excludedRegions);
    current.contains(region) ? current.remove(region) : current.add(region);
    _update(_filters!.copyWith(excludedRegions: current));
  }

  void _selectAllRegions() => _update(_filters!.copyWith(excludedRegions: []));
  void _deselectAllRegions() =>
      _update(_filters!.copyWith(excludedRegions: List.from(_allRegions)));

  // ── Genres ──

  void _toggleGenre(String genre) {
    final current = List<String>.from(_filters!.excludedGenres);
    current.contains(genre) ? current.remove(genre) : current.add(genre);
    _update(_filters!.copyWith(excludedGenres: current));
  }

  void _selectAllGenres() => _update(_filters!.copyWith(excludedGenres: []));
  void _deselectAllGenres() =>
      _update(_filters!.copyWith(excludedGenres: List.from(_djGenres)));

  // ── Weekdays ──

  void _toggleWeekday(int day) {
    final current = _filters!.allowedWeekdays == null
        ? List<int>.generate(7, (i) => i)
        : List<int>.from(_filters!.allowedWeekdays!);
    current.contains(day) ? current.remove(day) : current.add(day);
    _update(_filters!.copyWith(
      allowedWeekdays: current.length == 7 ? () => null : () => current,
    ));
  }

  void _applyWeekendPreset() =>
      _update(_filters!.copyWith(allowedWeekdays: () => [5, 6, 0]));

  // ── Budget ──

  RangeValues get _budgetRange => RangeValues(
        (_filters!.minBudget ?? _budgetMin).toDouble().clamp(_budgetMin, _budgetMax),
        (_filters!.maxBudget ?? _budgetMax).toDouble().clamp(_budgetMin, _budgetMax),
      );

  void _onBudgetChanged(RangeValues v) {
    final lo = v.start.round();
    final hi = v.end.round();
    _update(_filters!.copyWith(
      minBudget: () => lo == _budgetMin.toInt() ? null : lo,
      maxBudget: () => hi == _budgetMax.toInt() ? null : hi,
    ));
  }

  // ── Guests ──

  RangeValues get _guestsRange => RangeValues(
        (_filters!.minGuests ?? _guestsMin).toDouble().clamp(_guestsMin, _guestsMax),
        (_filters!.maxGuests ?? _guestsMax).toDouble().clamp(_guestsMin, _guestsMax),
      );

  void _onGuestsChanged(RangeValues v) {
    final lo = v.start.round();
    final hi = v.end.round();
    _update(_filters!.copyWith(
      minGuests: () => lo == _guestsMin.toInt() ? null : lo,
      maxGuests: () => hi == _guestsMax.toInt() ? null : hi,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final filtersAsync = ref.watch(djJobFiltersProvider);
    return filtersAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: _c.brand.primary)),
      error: (e, _) => Center(
          child: Text('Fejl: $e', style: DSTextStyle.bodyMd.copyWith(color: _c.state.danger))),
      data: (saved) {
        if (!_initialized) _initFrom(saved);
        return _buildForm();
      },
    );
  }

  Widget _buildForm() {
    final f = _filters!;
    final effectiveWeekdays = f.allowedWeekdays ?? List<int>.generate(7, (i) => i);

    return ListView(
      padding: const EdgeInsets.fromLTRB(DSSpacing.s4, DSSpacing.s4, DSSpacing.s4, DSSpacing.s2),
      children: [
        // ── Event types ──
        _FilterSectionHeader(
          title: 'Arrangementtyper',
          subtitle: 'Skjul jobs du ikke ønsker at se',
          onSelectAll: _selectAllEventTypes,
          onDeselectAll: _deselectAllEventTypes,
        ),
        const SizedBox(height: DSSpacing.s2),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _allEventTypes.map((type) => _OnboardingFilterChip(
                label: eventTypeLabel(type),
                active: !f.excludedEventTypes.contains(type),
                onTap: () => _toggleEventType(type),
              )).toList(),
        ),
        const SizedBox(height: DSSpacing.s6),

        // ── Regions ──
        _FilterSectionHeader(
          title: 'Regioner',
          subtitle: 'Skjul jobs fra bestemte regioner',
          onSelectAll: _selectAllRegions,
          onDeselectAll: _deselectAllRegions,
        ),
        const SizedBox(height: DSSpacing.s2),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _allRegions.map((r) => _OnboardingFilterChip(
                label: r,
                active: !f.excludedRegions.contains(r),
                onTap: () => _toggleRegion(r),
              )).toList(),
        ),
        const SizedBox(height: DSSpacing.s6),

        // ── Genres ──
        _FilterSectionHeader(
          title: 'Genres',
          subtitle: 'Skjul jobs hvor alle genres er ekskluderede',
          onSelectAll: _selectAllGenres,
          onDeselectAll: _deselectAllGenres,
        ),
        const SizedBox(height: DSSpacing.s2),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _djGenres.map((g) => _OnboardingFilterChip(
                label: g,
                active: !f.excludedGenres.contains(g),
                onTap: () => _toggleGenre(g),
              )).toList(),
        ),
        const SizedBox(height: DSSpacing.s6),

        // ── Weekdays ──
        Row(
          children: [
            Expanded(
              child: _FilterSectionLabel(
                  title: 'Ugedage', subtitle: 'Vis kun jobs på valgte dage'),
            ),
            GestureDetector(
              onTap: _applyWeekendPreset,
              child: Text('Weekend-preset',
                  style: DSTextStyle.labelSm.copyWith(
                      fontWeight: FontWeight.w600, color: _c.brand.primaryActive)),
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
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? _c.brand.primary : _c.bg.inputBg,
                  border: active ? null : Border.all(color: _c.border.subtle),
                ),
                child: Center(
                  child: Text(
                    _weekdayNames[jsDay],
                    style: DSTextStyle.bodySm.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: active ? _c.brand.onPrimary : _c.text.secondary),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: DSSpacing.s6),

        // ── Budget ──
        _FilterSectionLabel(title: 'Budget (kr.)', subtitle: 'Skjul jobs udenfor dette interval'),
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

        // ── Guests ──
        _FilterSectionLabel(
            title: 'Antal gæster', subtitle: 'Skjul jobs udenfor dette interval'),
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

// ── Filter step helpers ───────────────────────────────────────────────────────

class _FilterSectionLabel extends StatelessWidget {
  const _FilterSectionLabel({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: DSTextStyle.headingSm
                .copyWith(fontSize: 15, fontWeight: FontWeight.w700, color: _c.text.primary)),
        if (subtitle != null)
          Text(subtitle!, style: DSTextStyle.bodySm.copyWith(color: _c.text.muted)),
      ],
    );
  }
}

class _FilterSectionHeader extends StatelessWidget {
  const _FilterSectionHeader({
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
        Expanded(child: _FilterSectionLabel(title: title, subtitle: subtitle)),
        GestureDetector(
          onTap: onSelectAll,
          child: Text('Vælg alle',
              style: DSTextStyle.labelSm
                  .copyWith(fontWeight: FontWeight.w600, color: _c.brand.primaryActive)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('·', style: DSTextStyle.bodySm.copyWith(color: _c.text.muted)),
        ),
        GestureDetector(
          onTap: onDeselectAll,
          child: Text('Fravælg alle',
              style: DSTextStyle.labelSm.copyWith(
                  fontWeight: FontWeight.w600, color: _c.text.muted)),
        ),
      ],
    );
  }
}

class _OnboardingFilterChip extends StatelessWidget {
  const _OnboardingFilterChip(
      {required this.label, required this.active, required this.onTap});
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
        child: Text(label,
            style: DSTextStyle.labelMd.copyWith(
                color: active ? _c.brand.onPrimary : _c.text.secondary)),
      ),
    );
  }
}
