import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/utils/event_type_labels.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/review.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _c = lightColors;

const _eventTypes = [
  'bryllup', 'firmafest', 'fødselsdagsfest', 'fødselsdag',
  'julefrokost', 'privatfest', 'ungdomsfest', 'klub/bar',
  'lounge', 'konfirmation', 'studenterfest', 'sommerfest', 'andet',
];

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key, required this.role});

  final MusicianRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDj = role == MusicianRole.dj;
    final reviewsAsync = isDj ? ref.watch(djReviewsProvider) : ref.watch(musicianReviewsProvider);

    return Scaffold(
      backgroundColor: _c.bg.canvas,
      appBar: AppBar(
        title: Text('Anmeldelser', style: DSTextStyle.headingSm.copyWith(color: _c.text.primary)),
        backgroundColor: _c.bg.surface,
        surfaceTintColor: _c.bg.surface,
      ),
      floatingActionButton: DSIconButton(
        icon: LucideIcons.plus,
        variant: DSIconButtonVariant.primary,
        size: DSButtonSize.lg,
        onTap: () => _showUpsertDialog(context, ref, isDj: isDj),
      ),
      body: reviewsAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: _c.brand.primary)),
        error: (e, _) => Center(child: Text('Fejl: $e')),
        data: (reviews) {
          if (reviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.star, size: 48, color: _c.border.subtle),
                  const SizedBox(height: DSSpacing.s3),
                  Text('Ingen anmeldelser endnu', style: DSTextStyle.bodyMd.copyWith(color: _c.text.secondary)),
                  const SizedBox(height: DSSpacing.s1),
                  Text('Tryk + for at tilføje en', style: DSTextStyle.labelMd.copyWith(color: _c.text.muted)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(DSSpacing.s4),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return _ReviewCard(
                review: review,
                onEdit: () => _showUpsertDialog(context, ref, isDj: isDj, existing: review),
                onDelete: () => _confirmDelete(context, ref, isDj: isDj, review: review),
              );
            },
          );
        },
      ),
    );
  }

  void _showUpsertDialog(BuildContext context, WidgetRef ref, {required bool isDj, Review? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _c.bg.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(DSRadius.lg))),
      builder: (ctx) => _ReviewForm(
        existing: existing,
        onSave: (name, review, eventType, eventDate) async {
          try {
            final repo = ref.read(profileRepositoryProvider);
            if (existing != null) {
              await repo.updateReview(
                reviewId: existing.id,
                customerName: name,
                rating: 3,
                review: review,
                eventType: eventType,
                eventDate: eventDate,
              );
            } else {
              await repo.createReview(
                userId: isDj ? ref.read(djProfileProvider).value!.id : ref.read(musicianProfileProvider).value!.id,
                isDj: isDj,
                customerName: name,
                rating: 3,
                review: review,
                eventType: eventType,
                eventDate: eventDate,
              );
            }
            ref.invalidate(isDj ? djReviewsProvider : musicianReviewsProvider);
            if (ctx.mounted) Navigator.of(ctx).pop();
            if (context.mounted) {
              DSToast.show(context, variant: DSToastVariant.success, title: existing != null ? 'Anmeldelse opdateret' : 'Anmeldelse tilføjet');
            }
          } catch (e) {
            if (context.mounted) {
              DSToast.show(context, variant: DSToastVariant.error, title: 'Fejl: $e');
            }
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, {required bool isDj, required Review review}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Slet anmeldelse?'),
        content: Text('Anmeldelse fra ${review.customerName} vil blive slettet.'),
        actions: [
          DSButton(label: 'Annuller', variant: DSButtonVariant.ghost, size: DSButtonSize.sm, onTap: () => Navigator.of(ctx).pop()),
          DSButton(
            label: 'Slet',
            variant: DSButtonVariant.tertiary,
            size: DSButtonSize.sm,
            onTap: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(profileRepositoryProvider).deleteReview(review.id);
                ref.invalidate(isDj ? djReviewsProvider : musicianReviewsProvider);
                if (context.mounted) DSToast.show(context, variant: DSToastVariant.success, title: 'Anmeldelse slettet');
              } catch (e) {
                if (context.mounted) DSToast.show(context, variant: DSToastVariant.error, title: 'Fejl: $e');
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, required this.onEdit, required this.onDelete});

  final Review review;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DSSpacing.s3),
      child: DSSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.customerName,
                  style: DSTextStyle.headingSm.copyWith(fontSize: 15, color: _c.text.primary),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Rediger')),
                  PopupMenuItem(value: 'delete', child: Text('Slet', style: DSTextStyle.bodyMd.copyWith(color: _c.state.danger))),
                ],
                icon: Icon(LucideIcons.moreVertical, size: 20, color: _c.text.secondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.s1),
          Text(
            '${eventTypeLabel(review.eventType)} — ${review.eventDate}',
            style: DSTextStyle.bodySm.copyWith(color: _c.text.muted),
          ),
          const SizedBox(height: DSSpacing.s2),
          Text(
            review.review,
            style: DSTextStyle.labelMd.copyWith(fontWeight: FontWeight.w400, color: _c.text.secondary),
          ),
        ],
      ),
      ),
    );
  }
}

class _ReviewForm extends StatefulWidget {
  const _ReviewForm({this.existing, required this.onSave});

  final Review? existing;
  final Future<void> Function(String name, String review, String eventType, String eventDate) onSave;

  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _reviewCtrl;
  late String _eventType;
  late DateTime _eventDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.customerName ?? '');
    _reviewCtrl = TextEditingController(text: widget.existing?.review ?? '');
    _eventType = widget.existing?.eventType ?? 'bryllup';
    _eventDate = widget.existing != null
        ? (DateTime.tryParse(widget.existing!.eventDate) ?? DateTime.now())
        : DateTime.now();
  }

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
              Text(
                widget.existing != null ? 'Rediger anmeldelse' : 'Ny anmeldelse',
                style: DSTextStyle.headingMd.copyWith(fontWeight: FontWeight.w700, color: _c.text.primary),
              ),
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
                items: _eventTypes
                    .map((t) => DSDropdownItem(value: t, label: eventTypeLabel(t)))
                    .toList(),
                onChanged: (v) => setState(() => _eventType = v!),
              ),
              const SizedBox(height: DSSpacing.s3),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Dato: ${DateFormat('dd/MM/yyyy').format(_eventDate)}',
                  style: DSTextStyle.bodyMd.copyWith(color: _c.text.primary),
                ),
                trailing: Icon(LucideIcons.calendar, size: 20, color: _c.text.secondary),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _eventDate,
                    firstDate: DateTime(2015),
                    lastDate: DateTime.now(),
                    builder: (context, child) => Theme(
                      data: ThemeData.light().copyWith(
                        colorScheme: ColorScheme.light(
                          primary: _c.brand.primary,
                          onPrimary: _c.brand.onPrimary,
                          surface: Colors.white,
                          onSurface: _c.text.primary,
                        ),
                        datePickerTheme: DatePickerThemeData(
                          backgroundColor: Colors.white,
                          headerBackgroundColor: _c.brand.primary,
                          headerForegroundColor: _c.brand.onPrimary,
                          dayOverlayColor: WidgetStatePropertyAll(
                            _c.brand.primary.withValues(alpha: 0.12),
                          ),
                          todayBorder: BorderSide(color: _c.brand.primary),
                        ),
                        dialogTheme: const DialogThemeData(
                          backgroundColor: Colors.white,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setState(() => _eventDate = picked);
                },
              ),
              const SizedBox(height: DSSpacing.s3),
              DSInput(
                controller: _reviewCtrl,
                label: 'Anmeldelse',
                maxLength: 750,
                showCounter: true,
                maxLines: 5,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Påkrævet' : null,
              ),
              const SizedBox(height: DSSpacing.s4),
              DSButton(
                label: widget.existing != null ? 'Opdater' : 'Tilføj',
                size: DSButtonSize.lg,
                expand: true,
                isLoading: _saving,
                onTap: _saving ? null : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _saving = true);
                  await widget.onSave(
                    _nameCtrl.text.trim(),
                    _reviewCtrl.text.trim(),
                    _eventType,
                    DateFormat('yyyy-MM-dd').format(_eventDate),
                  );
                  if (mounted) setState(() => _saving = false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
