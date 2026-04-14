import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _c = lightColors;

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _controller = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim().isEmpty) return;
    // Mirrors the web app — feedback submission is acknowledged client-side.
    // A real backend endpoint can be wired up here when ready.
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _c.bg.canvas,
      appBar: AppBar(
        title: const Text('Feedback'),
        backgroundColor: _c.bg.surface,
        surfaceTintColor: _c.bg.surface,
      ),
      body: _submitted ? _buildThanks() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.all(DSSpacing.s4),
      children: [
        Text(
          'Hjælp os med at blive bedre',
          style: DSTextStyle.headingLg.copyWith(fontWeight: FontWeight.w700, color: _c.text.primary),
        ),
        const SizedBox(height: DSSpacing.s2),
        Text(
          'Vi forsøger hele tiden at gøre oplevelsen bedre for dig. Hvis du har feedback, '
          'må du meget gerne skrive det herunder.',
          style: DSTextStyle.bodyMd.copyWith(color: _c.text.secondary, height: 1.5),
        ),
        const SizedBox(height: DSSpacing.s6),
        Container(
          padding: const EdgeInsets.all(DSSpacing.s4),
          decoration: BoxDecoration(
            color: _c.bg.surface,
            borderRadius: BorderRadius.circular(DSRadius.md),
            border: Border.all(color: _c.border.subtle),
            boxShadow: DSShadow.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DSInput(
                label: 'Besked til DJTILBUD',
                controller: _controller,
                hint: 'Skriv din feedback her...',
                minLines: 6,
                maxLines: 12,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: DSSpacing.s4),
              DSButton(
                label: 'Send feedback',
                variant: DSButtonVariant.primary,
                expand: true,
                onTap: _controller.text.trim().isEmpty ? null : _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThanks() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DSSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _c.brand.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.check, size: 36, color: _c.brand.onPrimary),
            ),
            const SizedBox(height: DSSpacing.s4),
            Text(
              'Tak for din feedback!',
              style: DSTextStyle.headingLg.copyWith(fontWeight: FontWeight.w700, color: _c.text.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DSSpacing.s2),
            Text(
              'Tusind tak fordi du tog dig tid til at give os feedback. '
              'Vi læser det hele og bruger det til at gøre platformen bedre.',
              style: DSTextStyle.bodyMd.copyWith(color: _c.text.secondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DSSpacing.s6),
            DSButton(
              label: 'Luk',
              variant: DSButtonVariant.secondary,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
