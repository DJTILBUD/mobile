import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/agent/presentation/providers/agent_provider.dart';
import 'package:dj_tilbud_app/features/agent/presentation/widgets/profile_bio_bottom_sheet.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/dj_profile.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/musician_profile.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _c = lightColors;

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

const _djSaxOptions = [
  ('played_a_lot', 'Har spillet meget med DJ'),
  ('tried_some_times', 'Har prøvet et par gange'),
  ('never_done_before', 'Har aldrig prøvet'),
];

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, required this.role});

  final MusicianRole role;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // DJ fields
  final _fullNameCtrl = TextEditingController();
  final _djNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();
  final _priceExtraHourCtrl = TextEditingController();
  final _soundcloudCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  List<String> _selectedRegions = [];
  List<String> _selectedGenres = [];
  bool _canPlayWithSax = false;
  bool _allowPublicProfile = true;
  List<String> _venues = [];

  // Musician-specific
  final _hourlyRateCtrl = TextEditingController();
  final _minBookingCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  String? _djSaxCollaboration;
  String _instrument = '';

  bool _initialized = false;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _djNameCtrl.dispose();
    _phoneCtrl.dispose();
    _aboutCtrl.dispose();
    _priceExtraHourCtrl.dispose();
    _soundcloudCtrl.dispose();
    _venueCtrl.dispose();
    _hourlyRateCtrl.dispose();
    _minBookingCtrl.dispose();
    _experienceCtrl.dispose();
    super.dispose();
  }

  void _initDj(DjProfile p) {
    if (_initialized) return;
    _initialized = true;
    _fullNameCtrl.text = p.fullName;
    _djNameCtrl.text = p.companyOrDjName;
    _phoneCtrl.text = p.phone;
    _aboutCtrl.text = p.aboutYou;
    _priceExtraHourCtrl.text = p.pricePerExtraHour > 0 ? p.pricePerExtraHour.toString() : '';
    _soundcloudCtrl.text = p.soundcloudUrl ?? '';
    _selectedRegions = List.of(p.regions);
    _selectedGenres = List.of(p.genres);
    _canPlayWithSax = p.canPlayWithSax;
    _allowPublicProfile = p.allowPublicDjProfile;
    _venues = List.of(p.venuesAndEvents ?? []);
  }

  void _initMusician(MusicianProfile p) {
    if (_initialized) return;
    _initialized = true;
    _fullNameCtrl.text = p.fullName;
    _phoneCtrl.text = p.phone;
    _aboutCtrl.text = p.aboutText ?? '';
    _instrument = p.instrument;
    _hourlyRateCtrl.text = p.hourlyRate > 0 ? p.hourlyRate.toString() : '';
    _minBookingCtrl.text = p.minimumBookingRate > 0 ? p.minimumBookingRate.toString() : '';
    _experienceCtrl.text = p.experienceYears?.toString() ?? '';
    _selectedRegions = List.of(p.regions);
    _selectedGenres = List.of(p.genres ?? []);
    _djSaxCollaboration = p.djSaxCollaboration;
    _venues = List.of(p.venuesAndEvents ?? []);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final repo = ref.read(profileRepositoryProvider);
      if (widget.role == MusicianRole.dj) {
        await repo.updateDjProfile(DjProfile(
          id: ref.read(djProfileProvider).value!.id,
          fullName: _fullNameCtrl.text.trim(),
          companyOrDjName: _djNameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          aboutYou: _aboutCtrl.text.trim(),
          pricePerExtraHour: int.tryParse(_priceExtraHourCtrl.text) ?? 0,
          regions: _selectedRegions,
          genres: _selectedGenres,
          canPlayWithSax: _canPlayWithSax,
          allowPublicDjProfile: _allowPublicProfile,
          soundcloudUrl: _soundcloudCtrl.text.trim().isEmpty ? null : _soundcloudCtrl.text.trim(),
          venuesAndEvents: _venues.isEmpty ? null : _venues,
        ));
        ref.invalidate(djProfileProvider);
      } else {
        await repo.updateMusicianProfile(MusicianProfile(
          id: ref.read(musicianProfileProvider).value!.id,
          fullName: _fullNameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          instrument: _instrument,
          hourlyRate: int.tryParse(_hourlyRateCtrl.text) ?? 0,
          minimumBookingRate: int.tryParse(_minBookingCtrl.text) ?? 0,
          regions: _selectedRegions,
          aboutText: _aboutCtrl.text.trim().isEmpty ? null : _aboutCtrl.text.trim(),
          experienceYears: int.tryParse(_experienceCtrl.text),
          genres: _selectedGenres.isEmpty ? null : _selectedGenres,
          djSaxCollaboration: _djSaxCollaboration,
          venuesAndEvents: _venues.isEmpty ? null : _venues,
        ));
        ref.invalidate(musicianProfileProvider);
      }

      if (mounted) {
        DSToast.show(context, variant: DSToastVariant.success, title: 'Profil gemt');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        DSToast.show(context, variant: DSToastVariant.error, title: 'Kunne ikke gemme');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDj = widget.role == MusicianRole.dj;
    final profileAsync = isDj ? ref.watch(djProfileProvider) : ref.watch(musicianProfileProvider);

    return Scaffold(
      backgroundColor: _c.bg.canvas,
      appBar: AppBar(
        title: Text('Profil oplysninger', style: DSTextStyle.headingSm.copyWith(color: _c.text.primary)),
        backgroundColor: _c.bg.surface,
        surfaceTintColor: _c.bg.surface,
      ),
      body: profileAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: _c.brand.primary)),
        error: (e, _) => Center(child: Text('Fejl: $e')),
        data: (profile) {
          if (isDj) {
            _initDj(profile as DjProfile);
          } else {
            _initMusician(profile as MusicianProfile);
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(DSSpacing.s6),
              children: [
                _buildTextField('Fulde navn', _fullNameCtrl, required: true),
                if (isDj) ...[
                  const SizedBox(height: DSSpacing.s4),
                  _buildTextField('DJ / firma navn', _djNameCtrl, required: true),
                ],
                const SizedBox(height: DSSpacing.s4),
                _buildTextField('Telefon', _phoneCtrl, required: true, keyboardType: TextInputType.phone),
                const SizedBox(height: DSSpacing.s4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isDj ? 'Om dig (maks 600 tegn)' : 'Om dig',
                      style: DSTextStyle.labelLg.copyWith(color: _c.text.primary),
                    ),
                    GestureDetector(
                      onTap: () {
                        final userContext = isDj
                            ? djToUserContext(profile as DjProfile)
                            : musicianToUserContext(profile as MusicianProfile);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => ProviderScope(
                            overrides: [
                              agentSessionProvider.overrideWith(
                                (ref) => AgentSessionNotifier(
                                  ref.watch(agentRepositoryProvider),
                                ),
                              ),
                            ],
                            child: ProfileBioBottomSheet(
                              userContext: userContext,
                              userRole: isDj ? 'dj' : 'musician',
                              isDj: isDj,
                              onDraftAccepted: (draft) =>
                                  setState(() => _aboutCtrl.text = draft),
                            ),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.sparkle,
                              size: 13, color: _c.brand.primaryActive),
                          const SizedBox(width: DSSpacing.s1),
                          Text(
                            'AI',
                            style: DSTextStyle.labelSm.copyWith(fontWeight: FontWeight.w600, color: _c.brand.primaryActive),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DSSpacing.s2),
                DSInput(
                  controller: _aboutCtrl,
                  maxLines: 4,
                  maxLength: isDj ? 600 : null,
                  showCounter: isDj,
                  hint: 'Fortæl om dig selv som ${isDj ? 'DJ' : 'musiker'}...',
                ),
                if (isDj) ...[
                  const SizedBox(height: DSSpacing.s4),
                  _buildTextField('Pris pr. ekstra time (inkl. moms)', _priceExtraHourCtrl,
                      required: true, keyboardType: TextInputType.number),
                ],
                if (!isDj) ...[
                  const SizedBox(height: DSSpacing.s4),
                  _buildReadOnlyField('Instrument', _instrument),
                  const SizedBox(height: DSSpacing.s4),
                  _buildTextField('Timepris (DKK)', _hourlyRateCtrl,
                      required: true, keyboardType: TextInputType.number),
                  const SizedBox(height: DSSpacing.s4),
                  _buildTextField('Minimum booking pris (DKK)', _minBookingCtrl,
                      required: true, keyboardType: TextInputType.number),
                  const SizedBox(height: DSSpacing.s4),
                  _buildTextField('Års erfaring', _experienceCtrl,
                      keyboardType: TextInputType.number),
                ],

                const SizedBox(height: DSSpacing.s6),
                _buildChipSection(
                  isDj ? 'Region' : 'Regioner',
                  _allRegions,
                  _selectedRegions,
                  singleSelect: isDj,
                  subtitle: isDj ? 'Vælg én region — din hjemby/base' : null,
                ),

                const SizedBox(height: DSSpacing.s6),
                _buildChipSection('Genrer', isDj ? _djGenres : _musicianGenres, _selectedGenres),

                if (isDj) ...[
                  const SizedBox(height: DSSpacing.s4),
                  _buildTextField('SoundCloud URL', _soundcloudCtrl),
                ],

                const SizedBox(height: DSSpacing.s6),
                _buildVenuesSection(),

                if (isDj) ...[
                  const SizedBox(height: DSSpacing.s4),
                  DSSwitch(
                    label: 'Kan spille med saxofonist',
                    value: _canPlayWithSax,
                    onChanged: (v) => setState(() => _canPlayWithSax = v),
                  ),
                  const SizedBox(height: DSSpacing.s2),
                  DSSwitch(
                    label: 'Offentlig DJ profil',
                    value: _allowPublicProfile,
                    onChanged: (v) => setState(() => _allowPublicProfile = v),
                  ),
                ],

                if (!isDj) ...[
                  const SizedBox(height: DSSpacing.s4),
                  _buildDjSaxDropdown(),
                ],

                const SizedBox(height: DSSpacing.s8),
                DSButton(
                  label: 'Gem',
                  size: DSButtonSize.lg,
                  expand: true,
                  isLoading: _saving,
                  onTap: _saving ? null : _save,
                ),
                const SizedBox(height: DSSpacing.s8),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool required = false,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
  }) {
    return DSInput(
      label: label,
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      showCounter: maxLength != null,
      keyboardType: keyboardType,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Påkrævet' : null
          : null,
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return DSInput(
      label: label,
      initialValue: value,
      readOnly: true,
      enabled: false,
    );
  }

  Widget _buildChipSection(
    String title,
    List<String> options,
    List<String> selected, {
    bool singleSelect = false,
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: DSTextStyle.labelLg.copyWith(fontWeight: FontWeight.w600, color: _c.text.primary)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle, style: DSTextStyle.bodySm.copyWith(color: _c.text.muted)),
        ],
        const SizedBox(height: DSSpacing.s2),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: options.map((opt) {
            final isSelected = selected.contains(opt);
            return DSChip(
              label: opt,
              selected: isSelected,
              onTap: () => setState(() {
                if (singleSelect) {
                  selected.clear();
                  if (!isSelected) selected.add(opt);
                } else {
                  if (isSelected) {
                    selected.remove(opt);
                  } else {
                    selected.add(opt);
                  }
                }
              }),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVenuesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Spillesteder & events', style: DSTextStyle.labelLg.copyWith(fontWeight: FontWeight.w600, color: _c.text.primary)),
        const SizedBox(height: DSSpacing.s2),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _venues
              .map((v) => DSChip(
                    label: v,
                    onDelete: () => setState(() => _venues.remove(v)),
                  ))
              .toList(),
        ),
        const SizedBox(height: DSSpacing.s2),
        Row(
          children: [
            Expanded(
              child: DSInput(
                hint: 'Tilføj spillested...',
                controller: _venueCtrl,
                onSubmitted: (_) => _addVenue(_venueCtrl.text),
              ),
            ),
            const SizedBox(width: DSSpacing.s2),
            DSIconButton(
              icon: LucideIcons.plusCircle,
              variant: DSIconButtonVariant.secondary,
              onTap: () => _addVenue(_venueCtrl.text),
            ),
          ],
        ),
      ],
    );
  }

  void _addVenue(String value) {
    final v = value.trim();
    if (v.isNotEmpty && !_venues.contains(v)) {
      setState(() {
        _venues.add(v);
        _venueCtrl.clear();
      });
    }
  }

  Widget _buildDjSaxDropdown() {
    return DSDropdown<String>(
      label: 'Erfaring med DJ-samarbejde',
      value: _djSaxCollaboration,
      items: _djSaxOptions
          .map((o) => DSDropdownItem(value: o.$1, label: o.$2))
          .toList(),
      onChanged: (v) => setState(() => _djSaxCollaboration = v),
    );
  }
}
