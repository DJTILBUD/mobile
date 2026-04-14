import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/router/app_routes.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/dj_profile.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/musician_profile.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

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

const _instruments = [
  ('saxophone', 'Saxofon'),
  ('violin', 'Violin'),
  ('cello', 'Cello'),
  ('band', 'Band'),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  static const _c = lightColors;

  MusicianRole? _selectedRole;
  bool _showForm = false;
  bool _saving = false;
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();

  // Shared
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();
  List<String> _selectedRegions = [];
  List<String> _selectedGenres = [];

  // DJ-only
  final _djNameCtrl = TextEditingController();
  final _priceExtraHourCtrl = TextEditingController();

  // Musician-only
  String? _instrument;
  final _hourlyRateCtrl = TextEditingController();
  final _minBookingCtrl = TextEditingController();

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _aboutCtrl.dispose();
    _djNameCtrl.dispose();
    _priceExtraHourCtrl.dispose();
    _hourlyRateCtrl.dispose();
    _minBookingCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRegions.isEmpty) {
      setState(() => _errorMessage = 'Vælg mindst én region');
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final user = supabase.auth.currentUser!;
      final repo = ref.read(profileRepositoryProvider);

      if (_selectedRole == MusicianRole.dj) {
        await repo.createDjProfile(DjProfile(
          id: user.id,
          fullName: _fullNameCtrl.text.trim(),
          companyOrDjName: _djNameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          aboutYou: _aboutCtrl.text.trim(),
          pricePerExtraHour: int.tryParse(_priceExtraHourCtrl.text) ?? 0,
          regions: _selectedRegions,
          genres: _selectedGenres,
          canPlayWithSax: false,
          allowPublicDjProfile: true,
        ));
        if (mounted) context.goNamed(AppRoutes.djHome);
      } else {
        await repo.createMusicianProfile(
          profile: MusicianProfile(
            id: user.id,
            fullName: _fullNameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            instrument: _instrument!,
            hourlyRate: int.tryParse(_hourlyRateCtrl.text) ?? 0,
            minimumBookingRate: int.tryParse(_minBookingCtrl.text) ?? 0,
            regions: _selectedRegions,
            genres: _selectedGenres.isEmpty ? null : _selectedGenres,
          ),
          email: user.email ?? '',
        );
        if (mounted) context.goNamed(AppRoutes.instrumentalistHome);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Kunne ikke oprette profil. Prøv igen.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _handleSignOut() async {
    await supabase.auth.signOut();
    if (mounted) context.goNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _c.bg.canvas,
      appBar: AppBar(
        backgroundColor: _c.bg.surface,
        surfaceTintColor: _c.bg.surface,
        leading: _showForm
            ? DSIconButton(
                icon: LucideIcons.arrowLeft,
                variant: DSIconButtonVariant.ghost,
                onTap: () => setState(() {
                  _showForm = false;
                  _errorMessage = null;
                }),
              )
            : null,
        title: Text(
          _showForm ? 'Opsæt din profil' : 'Velkommen',
          style: DSTextStyle.headingSm.copyWith(color: _c.text.primary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: DSSpacing.s2),
            child: DSButton(label: 'Log ud', variant: DSButtonVariant.ghost, size: DSButtonSize.sm, onTap: _handleSignOut),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: DSMotion.normal,
        child: _showForm ? _buildForm() : _buildRoleSelection(),
      ),
    );
  }

  // ── Role selection ──────────────────────────────────────────────────────────

  Widget _buildRoleSelection() {
    return SafeArea(
      key: const ValueKey('role-selection'),
      child: Padding(
        padding: const EdgeInsets.all(DSSpacing.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Image.asset('assets/images/primary-logo.png', width: 80, height: 80),
            ),
            const SizedBox(height: DSSpacing.s4),
            Text(
              'Hvem er du?',
              style: DSTextStyle.displayMd.copyWith(
                fontWeight: FontWeight.w700,
                color: _c.text.primary,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DSSpacing.s2),
            Text(
              'Vælg den rolle der passer til dig for at komme i gang.',
              style: DSTextStyle.labelMd.copyWith(fontSize: 15, color: _c.text.secondary, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DSSpacing.s8),
            _RoleCard(
              icon: LucideIcons.headphones,
              title: 'DJ',
              subtitle: 'Jeg spiller musik til events som DJ',
              selected: _selectedRole == MusicianRole.dj,
              onTap: () => setState(() => _selectedRole = MusicianRole.dj),
            ),
            const SizedBox(height: DSSpacing.s4),
            _RoleCard(
              icon: LucideIcons.mic,
              title: 'Musiker / Instrumentalist',
              subtitle: 'Jeg spiller et instrument (saxofon, violin...)',
              selected: _selectedRole == MusicianRole.instrumentalist,
              onTap: () => setState(() => _selectedRole = MusicianRole.instrumentalist),
            ),
            const Spacer(),
            DSButton(
              label: 'Fortsæt',
              variant: DSButtonVariant.primary,
              expand: true,
              size: DSButtonSize.lg,
              onTap: _selectedRole == null
                  ? null
                  : () => setState(() => _showForm = true),
            ),
          ],
        ),
      ),
    );
  }

  // ── Profile form ────────────────────────────────────────────────────────────

  Widget _buildForm() {
    final isDj = _selectedRole == MusicianRole.dj;

    return Form(
      key: _formKey,
      child: ListView(
        key: const ValueKey('profile-form'),
        padding: const EdgeInsets.all(DSSpacing.s6),
        children: [
          Text(
            isDj ? 'Din DJ-profil' : 'Din musikerprofil',
            style: DSTextStyle.headingLg.copyWith(
              fontWeight: FontWeight.w700,
              color: _c.text.primary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: DSSpacing.s2),
          Text(
            'Udfyld de grundlæggende oplysninger. Du kan altid redigere dem senere.',
            style: DSTextStyle.bodyMd.copyWith(color: _c.text.secondary, height: 1.4),
          ),
          const SizedBox(height: DSSpacing.s6),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(DSSpacing.s3),
              decoration: BoxDecoration(
                color: _c.state.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DSRadius.sm),
                border: Border.all(color: _c.state.danger),
              ),
              child: Text(
                _errorMessage!,
                style: DSTextStyle.bodyMd.copyWith(color: _c.state.danger),
              ),
            ),
            const SizedBox(height: DSSpacing.s4),
          ],

          _buildField('Fulde navn', _fullNameCtrl, required: true),
          if (isDj) ...[
            const SizedBox(height: DSSpacing.s4),
            _buildField('DJ / firma navn', _djNameCtrl, required: true),
          ],
          const SizedBox(height: DSSpacing.s4),
          _buildField('Telefon', _phoneCtrl,
              required: true, keyboard: TextInputType.phone),
          const SizedBox(height: DSSpacing.s4),
          _buildField('Om dig', _aboutCtrl,
              required: true, maxLines: 4, maxLength: isDj ? 600 : null),

          if (isDj) ...[
            const SizedBox(height: DSSpacing.s4),
            _buildField('Pris pr. ekstra time (kr.)', _priceExtraHourCtrl,
                required: true, keyboard: TextInputType.number),
          ],

          if (!isDj) ...[
            const SizedBox(height: DSSpacing.s4),
            DSDropdown<String>(
              label: 'Instrument',
              value: _instrument,
              items: _instruments
                  .map((i) => DSDropdownItem(value: i.$1, label: i.$2))
                  .toList(),
              onChanged: (v) => setState(() => _instrument = v),
            ),
            const SizedBox(height: DSSpacing.s4),
            _buildField('Timepris (kr.)', _hourlyRateCtrl,
                required: true, keyboard: TextInputType.number),
            const SizedBox(height: DSSpacing.s4),
            _buildField('Minimum booking pris (kr.)', _minBookingCtrl,
                required: true, keyboard: TextInputType.number),
          ],

          const SizedBox(height: DSSpacing.s6),
          _buildChipSection(
            isDj ? 'Region *' : 'Regioner *',
            _allRegions,
            _selectedRegions,
            required: true,
            singleSelect: isDj,
          ),

          const SizedBox(height: DSSpacing.s6),
          _buildChipSection(
            'Genrer',
            isDj ? _djGenres : _musicianGenres,
            _selectedGenres,
          ),

          const SizedBox(height: DSSpacing.s8),
          DSButton(
            label: 'Opret profil',
            variant: DSButtonVariant.primary,
            size: DSButtonSize.lg,
            expand: true,
            isLoading: _saving,
            onTap: _saving ? null : _handleSave,
          ),
          if (!isDj) ...[
            const SizedBox(height: DSSpacing.s3),
            Text(
              'Dit instrument kan ikke ændres efter oprettelse. Kontakt support hvis du har valgt forkert.',
              style: DSTextStyle.bodySm.copyWith(color: _c.text.muted, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: DSSpacing.s8),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboard,
  }) {
    return DSInput(
      label: label,
      controller: ctrl,
      maxLines: maxLines,
      maxLength: maxLength,
      showCounter: maxLength != null,
      keyboardType: keyboard,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Påkrævet' : null
          : null,
    );
  }

  Widget _buildChipSection(
    String title,
    List<String> options,
    List<String> selected, {
    bool required = false,
    bool singleSelect = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: DSTextStyle.labelLg.copyWith(
            fontWeight: FontWeight.w600,
            color: required && selected.isEmpty ? _c.state.danger : _c.text.primary,
          ),
        ),
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
                _errorMessage = null;
              }),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Role card widget ──────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DSMotion.fast,
        padding: const EdgeInsets.all(DSSpacing.s4),
        decoration: BoxDecoration(
          color: selected
              ? _c.brand.primary.withValues(alpha: 0.12)
              : _c.bg.surface,
          borderRadius: BorderRadius.circular(DSRadius.lg),
          border: Border.all(
            color: selected ? _c.brand.primaryActive : _c.border.subtle,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? [] : DSShadow.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected
                    ? _c.brand.primary
                    : _c.bg.inputBg,
                borderRadius: BorderRadius.circular(DSRadius.md),
              ),
              child: Icon(
                icon,
                size: 24,
                color: selected ? _c.brand.onPrimary : _c.text.secondary,
              ),
            ),
            const SizedBox(width: DSSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DSTextStyle.headingSm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _c.text.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: DSTextStyle.labelMd.copyWith(color: _c.text.secondary, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DSSpacing.s2),
            Icon(
              selected ? LucideIcons.circleDot : LucideIcons.circle,
              color: selected ? _c.brand.primaryActive : _c.border.subtle,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
