import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_provider.dart';
import 'package:dj_tilbud_app/features/chat/data/datasources/job_link_remote_datasource.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/job_link.dart';

final jobLinkDatasourceProvider = Provider<JobLinkRemoteDatasource>(
  (ref) => JobLinkRemoteDatasource(ref.watch(supabaseClientProvider)),
);

/// Resolves the job-ref tokens in a conversation for the current viewer.
/// Keyed by a sorted, comma-joined ref list (families need a value-equal key).
final jobLinkResolutionsProvider = FutureProvider.autoDispose
    .family<Map<String, JobLinkResolution>, String>((ref, refsCsv) async {
      if (refsCsv.isEmpty) return const {};
      final refs = refsCsv.split(',');
      return ref.watch(jobLinkDatasourceProvider).resolveJobLinks(refs);
    });

/// Search results for the composer "@" picker, keyed by the typed query.
final linkableJobsProvider = FutureProvider.autoDispose
    .family<List<LinkableJob>, String>((ref, query) async {
      return ref.watch(jobLinkDatasourceProvider).searchLinkableJobs(query);
    });
