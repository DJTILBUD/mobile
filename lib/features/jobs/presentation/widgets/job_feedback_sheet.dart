import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/jobs/domain/job_feedback.dart';
import 'package:dj_tilbud_app/features/jobs/domain/repositories/jobs_repository.dart';

/// Shows "Hvorfor bød du ikke?" and, if the DJ answers, sends it.
///
/// One tap on a chip answers and closes; "Andet" reveals an optional note and a send button.
/// "Spring over", swipe down and tapping outside all skip, and a skip sends NOTHING (plan 2.1:
/// skipping is never stored against the DJ). The thank-you toast shows at once; the POST runs
/// after, and a failure is only logged: the question is optional, so it must never become an error
/// dialog. Eligibility (`can_ask`) is the caller's job and comes from the server.
Future<void> showJobFeedbackSheet(
  BuildContext context, {
  required JobsRepository repository,
  required int jobId,
  List<String> reasons = jobFeedbackReasons,
}) async {
  final answer = await showModalBottomSheet<JobFeedbackAnswer>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => JobFeedbackSheet(reasons: reasons),
  );
  if (answer == null) return;

  if (context.mounted) {
    DSToast.show(
      context,
      variant: DSToastVariant.success,
      title: 'Tak, det hjælper os',
    );
  }
  try {
    await repository.submitJobFeedback(jobId, answer);
  } catch (e) {
    debugPrint('job feedback: submit failed for job $jobId: $e');
  }
}

/// The sheet body. Pops with a [JobFeedbackAnswer], or with null on "Spring over".
// @uxid lib/features/jobs/presentation/widgets/job_feedback_sheet.dart::JobFeedbackSheet
class JobFeedbackSheet extends StatefulWidget {
  const JobFeedbackSheet({super.key, this.reasons = jobFeedbackReasons});

  final List<String> reasons;

  @override
  State<JobFeedbackSheet> createState() => _JobFeedbackSheetState();
}

class _JobFeedbackSheetState extends State<JobFeedbackSheet> {
  final _noteController = TextEditingController();
  bool _otherOpen = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _onChip(String reason) {
    if (reason == jobFeedbackOtherReason) {
      setState(() => _otherOpen = true);
      return;
    }
    Navigator.of(context).pop(JobFeedbackAnswer(reasons: [reason]));
  }

  void _sendOther() {
    Navigator.of(context).pop(
      JobFeedbackAnswer(
        reasons: const [jobFeedbackOtherReason],
        note: _noteController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    // A modal sheet is not resized by the keyboard, so it lifts itself (keyboard rule 2).
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Container(
        decoration: BoxDecoration(
          color: c.bg.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DSRadius.lg),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          DSSpacing.s4,
          DSSpacing.s3,
          DSSpacing.s4,
          DSSpacing.s4,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.border.subtle,
                    borderRadius: BorderRadius.circular(DSRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: DSSpacing.s4),
              Text(
                'Hjælp os med at sende dig de rigtige jobs',
                style: DSTextStyle.headingSm.copyWith(color: c.text.primary),
              ),
              const SizedBox(height: DSSpacing.s1),
              Text(
                'Hvorfor bød du ikke på dette job?',
                style: DSTextStyle.bodyMd.copyWith(color: c.text.secondary),
              ),
              const SizedBox(height: DSSpacing.s4),
              Wrap(
                spacing: DSSpacing.s2,
                runSpacing: DSSpacing.s2,
                children: [
                  for (final reason in widget.reasons)
                    DSChip(
                      label: reason,
                      selected: reason == jobFeedbackOtherReason && _otherOpen,
                      onTap: () => _onChip(reason),
                    ),
                ],
              ),
              if (_otherOpen) ...[
                const SizedBox(height: DSSpacing.s3),
                DSInput(
                  key: const ValueKey('job-feedback-note'),
                  hint: 'Fortæl os gerne mere (valgfrit)',
                  controller: _noteController,
                  maxLength: jobFeedbackNoteMaxLength,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(jobFeedbackNoteMaxLength),
                  ],
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendOther(),
                ),
                const SizedBox(height: DSSpacing.s3),
                DSButton(label: 'Send', expand: true, onTap: _sendOther),
              ],
              const SizedBox(height: DSSpacing.s2),
              Center(
                child: DSButton(
                  label: 'Spring over',
                  variant: DSButtonVariant.ghost,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
