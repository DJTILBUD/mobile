/// "Hvorfor bød du ikke?" one-tap feedback (plan
/// `web-app/documentation/supply-matching-revival-plan.md`, section 2.1).
///
/// MIRRORS web-app `src/helpers/jobFeedback.ts` (reason list, cooldown, note cap). Both files
/// must change together. The RULE (who may be asked, when) is server-side only:
/// `GET /api/dj/jobs/{id}/feedback` answers `can_ask`, and the POST re-checks it (409
/// `not_allowed`). Mobile never decides eligibility itself; these constants are only a fallback
/// chip list for when the server does not send `reasons`, plus the client-side note cap.
library;

/// Chip labels, exactly and in this order. Sent back verbatim: the route refuses unknown strings.
const List<String> jobFeedbackReasons = [
  'For lavt budget',
  'For langt væk',
  'Optaget den dag',
  'Ikke min type event',
  'Jobbet var fyldt op',
  'Andet',
];

/// The chip that reveals the optional free-text field instead of sending at once.
const String jobFeedbackOtherReason = 'Andet';

/// A DJ is asked at most once per this many days, across all jobs (enforced server-side).
const int jobFeedbackCooldownDays = 7;

/// Max length of the optional note after "Andet" (the route returns 400 above this).
const int jobFeedbackNoteMaxLength = 300;

/// Answer of `GET /api/dj/jobs/{id}/feedback`.
///
/// Fails CLOSED like the route: anything malformed means "do not ask". Asking twice is worse than
/// not asking once.
class JobFeedbackPrompt {
  const JobFeedbackPrompt({required this.canAsk, required this.reasons});

  const JobFeedbackPrompt.closed()
    : canAsk = false,
      reasons = jobFeedbackReasons;

  final bool canAsk;

  /// The server's chip list when present, else [jobFeedbackReasons].
  final List<String> reasons;

  factory JobFeedbackPrompt.fromJson(Map<String, dynamic> json) {
    final canAsk = json['can_ask'] == true;
    final raw = json['reasons'];
    final reasons =
        raw is List && raw.isNotEmpty && raw.every((r) => r is String)
            ? List<String>.unmodifiable(raw.cast<String>())
            : jobFeedbackReasons;
    return JobFeedbackPrompt(canAsk: canAsk, reasons: reasons);
  }
}

/// A DJ's answer from the sheet. Null from the sheet means "skipped" and nothing is sent.
class JobFeedbackAnswer {
  const JobFeedbackAnswer({required this.reasons, this.note});

  final List<String> reasons;
  final String? note;

  /// POST body. The note is trimmed and dropped when empty, like the route does.
  Map<String, dynamic> toJson() {
    final trimmed = note?.trim() ?? '';
    return {'reasons': reasons, if (trimmed.isNotEmpty) 'note': trimmed};
  }
}
