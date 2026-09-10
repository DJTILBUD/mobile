import 'package:dj_tilbud_app/features/profile/domain/entities/user_file.dart';

/// Canonical display order for a user's profile media.
///
/// Byte-for-byte mirror of web-app `src/helpers/sortUserFiles.ts` — change both together.
///
/// `sort_order` is nullable on purpose (migration 20260818000000): null means "never explicitly
/// ordered", so it must sort LAST and a freshly uploaded file appends to the end of the gallery
/// instead of jumping to the front. Ties (and the all-null legacy case) fall back to `id`, which
/// is the insert order every screen implicitly relied on before the column existed — so a gallery
/// nobody has reordered renders exactly as it did before.
int compareUserFiles(UserFile a, UserFile b) {
  final aOrder = a.sortOrder;
  final bOrder = b.sortOrder;

  if (aOrder != null && bOrder != null && aOrder != bOrder) {
    return aOrder - bOrder;
  }
  if (aOrder != null && bOrder == null) return -1;
  if (aOrder == null && bOrder != null) return 1;

  return a.id - b.id;
}

/// Returns a new list sorted by [compareUserFiles]. Never mutates the input.
List<UserFile> sortUserFiles(List<UserFile> files) {
  return List<UserFile>.of(files)..sort(compareUserFiles);
}
