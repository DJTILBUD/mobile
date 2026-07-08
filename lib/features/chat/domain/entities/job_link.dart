/// A message can reference a job inline as a plain-text token `@job:<id>`
/// (internal Jobs) or `@extjob:<id>` (ExtJobs). The token is resolved per-viewer
/// via the web API into access + a navigation target + a label.

class JobLinkTarget {
  const JobLinkTarget({required this.kind, required this.id});

  /// One of: dj_quote, dj_open_job, dj_ext_job, musician_offer,
  /// musician_ext_job, musician_open_job.
  final String kind;
  final int id;

  factory JobLinkTarget.fromJson(Map<String, dynamic> json) =>
      JobLinkTarget(kind: json['kind'] as String, id: json['id'] as int);
}

class JobLinkResolution {
  const JobLinkResolution({
    required this.ref,
    required this.accessible,
    this.eventType,
    this.date,
    this.target,
  });

  final String ref; // "job:123" | "extjob:456"
  final bool accessible;
  final String? eventType;
  final String? date;
  final JobLinkTarget? target;

  factory JobLinkResolution.fromJson(Map<String, dynamic> json) =>
      JobLinkResolution(
        ref: json['ref'] as String,
        accessible: json['accessible'] as bool? ?? false,
        eventType: json['eventType'] as String?,
        date: json['date'] as String?,
        target:
            json['target'] != null
                ? JobLinkTarget.fromJson(
                  Map<String, dynamic>.from(json['target'] as Map),
                )
                : null,
      );
}

/// A job the current user may link, returned by the composer "@" picker.
class LinkableJob {
  const LinkableJob({
    required this.ref,
    required this.kind,
    required this.id,
    this.eventType,
    this.date,
    this.visibleToRecipient,
  });

  final String ref;
  final String kind; // job | extjob
  final int id;
  final String? eventType;
  final String? date;

  /// Admin support picker only: whether the DJ/musician in the thread can see
  /// this job. null = not computed (the musician-facing picker never sets it).
  final bool? visibleToRecipient;

  factory LinkableJob.fromJson(Map<String, dynamic> json) => LinkableJob(
    ref: json['ref'] as String,
    kind: json['kind'] as String,
    id: json['id'] as int,
    eventType: json['eventType'] as String?,
    date: json['date'] as String?,
    visibleToRecipient: json['visibleToRecipient'] as bool?,
  );
}

/// Extracts the deduped `job:id` / `extjob:id` refs from a message body.
final RegExp jobRefRegExp = RegExp(r'@(job|extjob):(\d+)');

List<String> extractJobRefs(String text) {
  final refs = <String>{};
  for (final m in jobRefRegExp.allMatches(text)) {
    refs.add('${m.group(1)}:${m.group(2)}');
  }
  return refs.toList();
}
